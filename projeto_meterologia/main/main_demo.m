%% main_demo.m — Full pipeline: load → bloom → train → minhash → ensemble predict → evaluate
%
% Expected project structure:
%   weather_project/
%   ├── data/weather_data.csv
%   ├── naive_bayes/      nb_train.m  nb_predict.m
%   ├── bloom_filter/     bloom_init.m  bloom_insert.m  bloom_check.m
%   │                     bloom_hash.m  bloom_fp_rate.m
%   ├── minhash/          minhash_signature.m  minhash_neighbours.m
%   │                     minhash_similarity.m  discretizar_dia.m
%   ├── main_demo.m
%   └── evaluate.m
%
% Each module contributes to the final prediction:
%   Bloom Filter  → flags unseen patterns (gates the pipeline)
%   MinHash       → finds the k most similar historical days
%   Naive Bayes   → computes class probabilities from learned distributions
%   Ensemble      → final class = α·P_NB + (1-α)·WeightedMinHashVote

clear; clc; close all;

%% -------------------------------------------------------
%  0. PATHS
% -------------------------------------------------------
baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'naive_bayes'));
addpath(fullfile(baseDir, 'bloom_filter'));
addpath(fullfile(baseDir, 'minhash'));

%% -------------------------------------------------------
%  1. LOAD DATA
% -------------------------------------------------------
fprintf('=== Loading data ===\n');
data = readtable(fullfile(baseDir, 'data', 'los_angeles.csv'));

featureNames = {'precipitation','temp_max','temp_min','wind', ...
                'snow_depth','temp_range','month_sin','month_cos','tsun','wsf2'};

X = table2array(data(:, featureNames));
Y = categorical(data.weather);
classes   = categories(Y);
nFeatures = numel(featureNames);
N         = size(X, 1);

fprintf('Dataset: %d samples | %d features | %d classes\n', N, nFeatures, numel(classes));
fprintf('Classes: %s\n\n', strjoin(classes', ', '));

%% -------------------------------------------------------
%  2. TRAIN / TEST SPLIT  (80 / 20)
% -------------------------------------------------------
rng(42);
idx    = randperm(N);
nTrain = round(0.8 * N);

idxTrain = idx(1:nTrain);
idxTest  = idx(nTrain+1:end);

XTrain = X(idxTrain, :);  YTrain = Y(idxTrain);
XTest  = X(idxTest,  :);  YTest  = Y(idxTest);

fprintf('Train: %d samples | Test: %d samples\n\n', nTrain, numel(idxTest));

%% -------------------------------------------------------
%  3. BLOOM FILTER — built on training data
%     Role: before predicting, flag whether a test day's
%     pattern was ever seen during training.
%     Unseen patterns → prediction should be treated with
%     lower confidence.
% -------------------------------------------------------
fprintf('=== Building Bloom Filter ===\n');

fpr_target = 0.01;
m_bf = ceil(-(nTrain * log(fpr_target)) / (log(2)^2));
k_bf = max(1, round((m_bf / nTrain) * log(2)));

bf = bloom_init(m_bf, k_bf);
for i = 1:nTrain
    bf = bloom_insert(bf, mat2str(XTrain(i,:), 4));
end

fprintf('  m = %d bits | k = %d hashes | theoretical FPR = %.4f%%\n\n', ...
    m_bf, k_bf, bloom_fp_rate(bf) * 100);

%% -------------------------------------------------------
%  4. NAIVE BAYES — train on XTrain
% -------------------------------------------------------
fprintf('=== Training Gaussian Naive Bayes ===\n');
[mu, sigma, logPrior, classes] = nb_train(XTrain, YTrain);

fprintf('\n%-12s  %8s\n', 'Class', 'Prior');
fprintf('%s\n', repmat('-', 1, 22));
for c = 1:numel(classes)
    fprintf('  %-12s  %.4f\n', classes{c}, exp(logPrior(c)));
end
fprintf('\n');

%% -------------------------------------------------------
%  5. MINHASH — build signatures on training sets
%     Role: given a test day, find the k most similar
%     training days and use their labels as weighted votes.
% -------------------------------------------------------
fprintf('=== Building MinHash signatures ===\n');

nHash = 100;   % signature length — higher = more accurate Jaccard estimate

% Discretise every training day into a set of tokens
trainSets = cell(nTrain, 1);
for i = 1:nTrain
    trainSets{i} = discretizar_dia(XTrain(i,:));
end

% Compute (nHash x nTrain) signature matrix
sigTrain = minhash_signature(trainSets, nHash);

fprintf('  nHash = %d | Training signature matrix: %dx%d\n\n', ...
    nHash, size(sigTrain,1), size(sigTrain,2));

%% -------------------------------------------------------
%  6. ENSEMBLE PREDICTION ON TEST SET
%     For each test day:
%       a) Bloom Filter  → seen / unseen flag
%       b) Naive Bayes   → class probabilities  (probNB)
%       c) MinHash       → k nearest neighbours → weighted vote (votesMH)
%       d) Ensemble      → score = α·probNB + (1-α)·votesMH
% -------------------------------------------------------
fprintf('=== Ensemble prediction on test set ===\n');

alpha   = 0.7;   % NB weight;  MinHash weight = 1-alpha
kNN     = 5;     % number of MinHash neighbours
nTest   = size(XTest, 1);
nClasses = numel(classes);

predictions  = categorical(repmat("", nTest, 1));
ensembleProb = zeros(nTest, nClasses);
nbProb       = zeros(nTest, nClasses);
bloomFlags   = false(nTest, 1);   % true = pattern seen in training

for i = 1:nTest

    % ---- a) Bloom Filter check ----
    key = mat2str(XTest(i,:), 4);
    bloomFlags(i) = bloom_check(bf, key);

    % ---- b) Naive Bayes probabilities ----
    [~, probNB] = nb_predict(XTest(i,:), mu, sigma, logPrior, classes);
    probNB = probNB(:);
    nbProb(i,:) = probNB';

    % ---- c) MinHash: k nearest neighbours ----
    querySet = discretizar_dia(XTest(i,:));
    sigQuery = minhash_signature([querySet], nHash);   %#ok<NBRAK>

    [neighboursIdx, neighboursSim] = minhash_neighbours(sigTrain, sigQuery, kNN);

    % Weighted vote: each neighbour votes for its class, weighted by similarity
    votesMH   = zeros(nClasses, 1);
    totalSim  = sum(neighboursSim);

    if totalSim > 0
        for v = 1:numel(neighboursIdx)
            neighbourClass = char(YTrain(neighboursIdx(v)));
            cIdx = find(strcmp(classes, neighbourClass));
            if ~isempty(cIdx)
                votesMH(cIdx) = votesMH(cIdx) + neighboursSim(v);
            end
        end
        votesMH = votesMH / totalSim;   % normalise to [0,1]
    else
        % No useful similarity → fall back entirely to Naive Bayes
        votesMH = probNB;
    end

    % ---- d) Ensemble score ----
    % If Bloom Filter says "unseen", reduce NB confidence slightly
    effectiveAlpha = alpha;
    if ~bloomFlags(i)
        effectiveAlpha = min(alpha + 0.1, 1.0);   % trust NB more for novel patterns
    end

    score = effectiveAlpha * probNB + (1 - effectiveAlpha) * votesMH;
    score = score / sum(score);   % normalise

    ensembleProb(i,:) = score';
    [~, best] = max(score);
    predictions(i) = classes{best};
end

nSeen   = sum(bloomFlags);
nUnseen = nTest - nSeen;
fprintf('  Bloom Filter: %d seen | %d unseen (novel patterns)\n', nSeen, nUnseen);
fprintf('  Ensemble alpha = %.2f (NB) + %.2f (MinHash)\n\n', alpha, 1-alpha);

%% -------------------------------------------------------
%  7. EVALUATE
% -------------------------------------------------------
fprintf('=== Evaluation ===\n');
evaluate(YTest, predictions, classes, XTest, bf);

%% -------------------------------------------------------
%  8. MANUAL PREDICTION EXAMPLE
%     Shows all three components contributing visibly.
% -------------------------------------------------------
fprintf('\n=== Manual prediction example ===\n');

% [precipitation, temp_max, temp_min, wind, snow_depth,
%  temp_range, month_sin, month_cos, tsun, wsf2]
newDay = [5.0, 12.0, 6.0, 4.5, 0.0, 6.0, 0.5, 0.866, 0.0, 9.0];

fprintf('Input: ');
for j = 1:nFeatures
    fprintf('%s=%.1f  ', featureNames{j}, newDay(j));
end
fprintf('\n\n');

% Bloom Filter
key = mat2str(newDay, 4);
if bloom_check(bf, key)
    fprintf('[Bloom Filter]  Pattern probably seen in training.\n');
else
    fprintf('[Bloom Filter]  NOVEL pattern — not in training history.\n');
end

% Naive Bayes
[~, probNB] = nb_predict(newDay, mu, sigma, logPrior, classes);
probNB = probNB(:);
fprintf('\n[Naive Bayes] Class probabilities:\n');
for c = 1:numel(classes)
    fprintf('  %-12s  %.4f\n', classes{c}, probNB(c));
end

% MinHash neighbours
querySet = discretizar_dia(newDay);
sigQuery = minhash_signature({querySet}, nHash);
[neighboursIdx, neighboursSim] = minhash_neighbours(sigTrain, sigQuery, kNN);

fprintf('\n[MinHash] %d nearest neighbours:\n', kNN);
for v = 1:numel(neighboursIdx)
    fprintf('  Neighbour %d — similarity=%.4f — class=%s\n', ...
        v, neighboursSim(v), char(YTrain(neighboursIdx(v))));
end

% MinHash weighted vote
votesMH  = zeros(nClasses, 1);
totalSim = sum(neighboursSim);
if totalSim > 0
    for v = 1:numel(neighboursIdx)
        cIdx = find(strcmp(classes, char(YTrain(neighboursIdx(v)))));
        if ~isempty(cIdx)
            votesMH(cIdx) = votesMH(cIdx) + neighboursSim(v);
        end
    end
    votesMH = votesMH / totalSim;
else
    votesMH = probNB;
end

fprintf('\n[MinHash] Weighted votes:\n');
for c = 1:numel(classes)
    fprintf('  %-12s  %.4f\n', classes{c}, votesMH(c));
end

% Ensemble
score = alpha * probNB + (1-alpha) * votesMH;
score = score / sum(score);
[~, best] = max(score);

fprintf('\n[Ensemble]  alpha=%.2f·NB + %.2f·MinHash\n', alpha, 1-alpha);
for c = 1:numel(classes)
    marker = '';
    if c == best, marker = '  ← prediction'; end
    fprintf('  %-12s  %.4f%s\n', classes{c}, score(c), marker);
end
fprintf('\nFinal prediction: %s\n', classes{best});