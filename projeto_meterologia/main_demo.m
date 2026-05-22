clc;
clear;
close all;

baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'naive_bayes'));
addpath(fullfile(baseDir, 'bloom_filter'));
addpath(fullfile(baseDir, 'minhash'));

%% =========================
% 1. LER DADOS CSV
%% =========================
data = readtable(fullfile(baseDir, 'data', 'seattle.csv'));

% Remover colunas que não são features
data.date         = [];   % identificador temporal — não usar
data.dew_point_mean = []; % 100% zeros no dataset — não acrescenta informação
data.dew_point_max  = []; % idem

% ---- Features compostas ANTES de normalizar ----
data.temp_mean   = (data.temp_max + data.temp_min) / 2;
data.season_temp = data.temp_mean .* data.month_cos;
data.cos_x_tmax  = data.month_cos .* data.temp_max;

% Label
Y = categorical(data.weather);

X = table2array(removevars(data, 'weather'));

%% =========================
% 2. SPLIT TREINO / TESTE
%% =========================
rng();
idx = randperm(size(X,1));
trainRatio = 0.8;
nTrain     = round(trainRatio * length(idx));

trainIdx = idx(1:nTrain);
testIdx  = idx(nTrain+1:end);

XTrain = X(trainIdx, :);
YTrain = Y(trainIdx);
XTest  = X(testIdx, :);
YTest  = Y(testIdx);

fprintf('\nTreino: %d amostras | Teste: %d amostras\n', size(XTrain,1), size(XTest,1));
fprintf('XTrain — precipitação não-zero : %d/%d\n', ...
    sum(XTrain(:,1)>0), size(XTrain,1));

%% =========================
% 3. BLOOM FILTER (TREINO)
%% =========================
%% BLOOM FILTER — chave quantizada (substituir o bloco actual)
bf = bloom_init(500000, 7);

% Features a usar na chave: precip, precip_hours, cloud, humidity, temp_max, wind_gusts
bf_cols = [1, 19, 14, 12, 2, 7];
bf_breaks = [2, 4, 10; ...   % precip:      0|<2|<4|<10|>=10
             3, 6, 12; ...   % precip_hours: 0|<3|<6|<12|>=12
             35,60, 80; ...  % cloud:       <35|<60|<80|>=80
             55,70, 82; ...  % humidity:    <55|<70|<82|>=82
             10,18, 25; ...  % temp_max:    <10|<18|<25|>=25
             25,40, 55];     % wind_gusts:  <25|<40|<55|>=55

for i = 1:size(XTrain,1)
    key = build_bf_key(XTrain(i,:), bf_cols, bf_breaks);
    bf  = bloom_insert(bf, key);
end

%% =========================
% 4. MINHASH (TREINO)
%% =========================
%% LIMIARES DINÂMICOS (calculados do treino)
thresholds = compute_thresholds(XTrain, YTrain);
trainTokens = cell(size(XTrain,1), 1);
for i = 1:size(XTrain,1)
    trainTokens{i} = extract_features(XTrain(i,:), thresholds);
end
[sigTrain, hashData] = minhash_signature(trainTokens, 200);

%% =========================
% 5. NAIVE BAYES (TREINO)
%% =========================
[mu, sigma, logPrior, classes] = nb_train(XTrain, YTrain);

%% =========================
% 6. PESOS DO ENSEMBLE
%% =========================
w_nb = 0.55;
w_mh = 0.40;
w_bf = 0.05;

%% =========================
% 7. ENSEMBLE PREDICTION
%% =========================
% Naive Bayes isolado (para comparação)
[~, p_nb_all] = nb_predict(XTest, mu, sigma, logPrior, classes);
[~, idx_nb]   = max(p_nb_all, [], 2);
pred_nb       = classes(idx_nb);
acc_nb        = mean(categorical(pred_nb) == YTest);
fprintf('\nAccuracy Naive Bayes (só): %.4f (%.2f%%)\n', acc_nb, acc_nb*100);

% Ensemble completo
previsoes = ensemble_predict(XTest, YTrain, sigTrain, bf, ...
                             mu, sigma, logPrior, classes, hashData, ...
                             w_nb, w_mh, w_bf, bf_cols, bf_breaks, thresholds);

%% =========================
% 8. AVALIAÇÃO
%% =========================
evaluate(YTest, previsoes, classes, XTest, bf, thresholds);

fprintf('\n=== RESULTADOS DO ENSEMBLE ===\n');
acc = mean(previsoes == YTest);
fprintf('Accuracy Ensemble: %.4f (%.2f%%)\n', acc, acc*100);

% Matriz de confusão visual
figure;
cm = confusionchart(YTest, previsoes);
cm.Title          = 'Ensemble — Matriz de Confusão (Seattle Weather)';
cm.RowSummary     = 'row-normalized';
cm.ColumnSummary  = 'column-normalized';