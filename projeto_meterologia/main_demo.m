clc;
clear;
close all;

baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'naive_bayes'));
addpath(fullfile(baseDir, 'bloom_filter'));
addpath(fullfile(baseDir, 'minhash'));
tic; 

% 1. LER DADOS 
data = readtable(fullfile(baseDir, 'data', 'brasilia.csv'));

% Remover colunas que não são features/obsoleto
data.date = [];  
% data.dew_point_mean e data.temp_max mantidos!

data.temp_mean = (data.temp_max + data.temp_min) / 2;
data.season_temp = data.temp_mean .* data.month_cos;
data.cos_x_tmax = data.month_cos .* data.temp_max;

% NOVA FEATURE: Dew Point Depression (Diferença entre Temp Média e Ponto de Orvalho)
data.dew_depression = data.temp_mean - data.dew_point_mean;

Y = categorical(data.weather);
X = table2array(removevars(data, 'weather'));

% TRANSFORMAÇÃO LOGARÍTMICA: Torna as variáveis de precipitação (1 e 19)
% mais próximas de uma Gaussiana para o Naive Bayes.
X(:,1) = log1p(X(:,1)); 
X(:,19) = log1p(X(:,19));

% 2. SPLIT TREINO / TESTE
rng(42);
idx = randperm(size(X,1));
trainRatio = 0.8;
nTrain = round(trainRatio * length(idx));

trainIdx = idx(1:nTrain);
testIdx = idx(nTrain+1:end);

XTrain = X(trainIdx, :);
YTrain = Y(trainIdx);
XTest = X(testIdx, :);
YTest = Y(testIdx);

fprintf('\nTreino: %d amostras | Teste: %d amostras\n', size(XTrain,1), size(XTest,1));

% 3. BLOOM FILTER 
bf = bloom_init(50000, 7);

% Atualizar os índices
bf_cols = [1, 19, 16, 12, 2, 7, 14];
% Breaks ajustados com log1p para bater certo com a transformação da matriz X
bf_breaks = [log1p(2), log1p(4), log1p(10); ... % precip (log)
             log1p(3), log1p(6), log1p(12); ... % precip_hours (log)
             35, 60, 80; ...                    % cloud
             55, 70, 82; ...                    % humidity
             10, 18, 25; ...                    % temp_max
             25, 40, 55; ...                    % wind_gusts
              2,  8, 14];                       % dew_mean

for i = 1:size(XTrain,1)
    key = build_bf_key(XTrain(i,:), bf_cols, bf_breaks);
    bf = bloom_insert(bf, key);
end

% 4. MINHASH 
thresholds = compute_thresholds(XTrain, YTrain);
trainTokens = cell(size(XTrain,1), 1);
for i = 1:size(XTrain,1)
    trainTokens{i} = extract_features(XTrain(i,:), thresholds);
end
[sigTrain, hashData] = minhash_signature(trainTokens, 200);

% 5. NAIVE BAYES (TREINO)
[mu, sigma, logPrior, classes] = nb_train(XTrain, YTrain);

% 6. PESOS DO ENSEMBLE
w_nb = 0.55;
w_mh = 0.40;
w_bf = 0.05;

% 7. ENSEMBLE PREDICTION
% Naive Bayes isolado (para comparação)
[~, p_nb_all] = nb_predict(XTest, mu, sigma, logPrior, classes);
[~, idx_nb] = max(p_nb_all, [], 2);
pred_nb = classes(idx_nb);
acc_nb = mean(categorical(pred_nb) == YTest);
fprintf('\nAccuracy Naive Bayes (só): %.4f (%.2f%%)\n', acc_nb, acc_nb*100);

previsoes = ensemble_predict(XTest, YTrain, sigTrain, bf, ...
                             mu, sigma, logPrior, classes, hashData, ...
                             w_nb, w_mh, w_bf, bf_cols, bf_breaks, thresholds);

% 8. AVALIAÇÃO
evaluate(YTest, previsoes, classes, XTest, bf, bf_cols, bf_breaks);

fprintf('\n=== RESULTADOS DO ENSEMBLE ===\n');
acc = mean(previsoes == YTest);
fprintf('Accuracy Ensemble: %.4f (%.2f%%)\n', acc, acc*100);

figure;
cm = confusionchart(YTest, previsoes);
cm.Title = 'Ensemble — Matriz de Confusão';
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

toc