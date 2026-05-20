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

% remover data (não usamos)
data.date = [];
data.tsun  = [];   % 100% zeros — remove completamente, só adiciona ruído

% Features compostas ANTES de normalizar
data.temp_mean   = (data.temp_max + data.temp_min) / 2;
data.season_temp = data.temp_mean .* data.month_cos;
data.cos_x_tmax  = data.month_cos .* data.temp_max;

% label
Y = categorical(data.weather);

% features numéricas (tudo menos weather)
X = table2array(removevars(data, 'weather'));

fprintf('Precipitation nonzero: %d/%d (%.1f%%)\n', ...
    sum(X(:,1)>0), size(X,1), 100*mean(X(:,1)>0));
%% =========================
% 2. SPLIT TREINO / TESTE
%% =========================
rng(42);

idx = randperm(size(X,1));

trainRatio = 0.8;
nTrain = round(trainRatio * length(idx));

trainIdx = idx(1:nTrain);
testIdx  = idx(nTrain+1:end);

XTrain = X(trainIdx,:);
YTrain = Y(trainIdx);

XTest  = X(testIdx,:);
YTest  = Y(testIdx);

raw = readtable(fullfile(baseDir, 'data', 'seattle.csv'));
raw.date = [];

fprintf('CSV raw nonzero precip: %d\n', sum(raw.precipitation > 0));
fprintf('data após features compostas nonzero: %d\n', sum(data.precipitation > 0));
fprintf('X completo nonzero col1: %d\n', sum(X(:,1) > 0));
fprintf('XTrain nonzero col1: %d\n', sum(XTrain(:,1) > 0));
fprintf('XTrain drizzle nonzero col1: %d/%d\n', ...
    sum(XTrain(YTrain=='drizzle', 1) > 0), sum(YTrain=='drizzle'));

disp(removevars(data,'weather').Properties.VariableNames)


%% =========================
% 3. BLOOM FILTER (TREINO)
%% =========================
%% =========================
% 3. BLOOM FILTER (TREINO)
%% =========================
bf = bloom_init(50000, 7);
for i = 1:size(XTrain,1)
    % 1. Extrair os tokens discretizados (essencial!)
    tokens = extract_features(XTrain(i,:));
    
    % 2. Criar a chave exatamente igual ao formato do teste
    key = lower(strjoin(sort(string(tokens)), '|'));
    
    bf = bloom_insert(bf, key);
end

%% =========================
% 4. MINHASH (TREINO)
%% =========================

trainTokens = cell(size(XTrain,1),1);
for i = 1:size(XTrain,1)
    % Guardar os novos tokens textuais em vez dos dados brutos
    trainTokens{i} = extract_features(XTrain(i,:));
end
% Gerar as assinaturas com base nos novos tokens
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
% Naive Bayes só
[~, p_nb_all] = nb_predict(XTest, mu, sigma, logPrior, classes);
[~, idx_nb] = max(p_nb_all, [], 2);
pred_nb = classes(idx_nb);

acc_nb = mean(pred_nb == YTest);
previsoes = ensemble_predict(XTest, YTrain, sigTrain, bf, ...
                             mu, sigma, logPrior, classes, hashData, ...
                             w_nb, w_mh, w_bf);

% placeholder simples (ou versão tua melhorada)
pred_mh = previsoes; % se ainda não separaste, ignora ou melhora depois

%% =========================
% 8. EVALUAÇÃO
%% =========================
evaluate(YTest, previsoes, classes, XTest, bf);


fprintf('\n=== RESULTADOS DO ENSEMBLE ===\n');
acc = mean(previsoes == YTest);
fprintf('Accuracy Ensemble: %.4f (%.2f%%)\n', acc, acc*100);

% Desenhar Gráficos com as previsões já prontas
figure;
cm = confusionchart(YTest, previsoes);
cm.Title = 'Ensemble - Matriz de Confusão';
cm.RowSummary = 'row-normalized';
cm.ColumnSummary = 'column-normalized';

% --- TESTE VISUAL DE AMOSTRAS ---
fprintf('\n=== TESTE MINHASH (Exemplos) ===\n');
for i = 1:5
    tokens = extract_features(XTest(i,:));
    sigQuery = minhash_single(tokens, hashData);
    scores = minhash_score(sigTrain, YTrain, sigQuery, classes, 5);
    fprintf('\nAmostra %d (Real: %s | Previsto: %s)\n', i, string(YTest(i)), string(previsoes(i)));
    for c = 1:numel(classes)
        fprintf('  %s -> %.4f\n', classes{c}, scores(c));
    end
end
