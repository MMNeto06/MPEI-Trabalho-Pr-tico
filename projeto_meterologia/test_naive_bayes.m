% test_naive_bayes.m
% Testes do módulo Naive Bayes
% MPEI 2025-2026

clc; clear; close all;

baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'naive_bayes'));
addpath(fullfile(baseDir, 'data'));

fprintf('============================================================\n');
fprintf('            TESTES DO MÓDULO NAIVE BAYES                   \n');
fprintf('============================================================\n\n');

%% --- Preparação dos Dados ---
data = readtable(fullfile(baseDir, 'data', 'beijing.csv'));
data.date          = [];
data.dew_point_mean = [];
data.dew_point_max  = [];
data.temp_mean      = (data.temp_max + data.temp_min) / 2;
data.season_temp    = data.temp_mean .* data.month_cos;
data.cos_x_tmax     = data.month_cos .* data.temp_max;

Y = categorical(data.weather);
X = table2array(removevars(data, 'weather'));

rng(42);
idx    = randperm(size(X, 1));
nTrain = round(0.8 * length(idx));
XTrain = X(idx(1:nTrain),     :);
YTrain = Y(idx(1:nTrain));
XTest  = X(idx(nTrain+1:end), :);
YTest  = Y(idx(nTrain+1:end));
nTeste = numel(YTest);

fprintf('Treino: %d amostras | Teste: %d amostras\n\n', size(XTrain,1), nTeste);

%% ----------------------------------------------------------------
%  Teste 1: Treino — verificar estrutura do modelo
%% ----------------------------------------------------------------
fprintf('--- Teste 1: Treino do Modelo ---\n');
[mu, sigma, logPrior, classes] = nb_train(XTrain, YTrain);
nClasses = numel(classes);

fprintf('Classes identificadas (%d): %s\n', nClasses, strjoin(classes, ', '));
fprintf('Dimensões de mu    (nClasses x nFeatures): %d x %d\n', size(mu,1),    size(mu,2));
fprintf('Dimensões de sigma (nClasses x nFeatures): %d x %d\n', size(sigma,1), size(sigma,2));
fprintf('Log-priors: ');
fprintf('%.4f ', logPrior);
fprintf('\n');

% Verificar que os priors somam aproximadamente 1 em escala de probabilidade
priorSum = sum(exp(logPrior));
if abs(priorSum - 1) < 1e-6
    fprintf('PASSOU: log-priors correspondem a probabilidades que somam 1 (soma=%.6f)\n\n', priorSum);
else
    fprintf('FALHOU: soma dos priors = %.6f (esperado ~1)\n\n', priorSum);
end

%% ----------------------------------------------------------------
%  Teste 2: Previsão e Exatidão Global
%  (equivalente ao bloco de comparação no main_demo.m)
%% ----------------------------------------------------------------
fprintf('--- Teste 2: Previsão e Exatidão Global ---\n');
[pred_raw, p_all] = nb_predict(XTest, mu, sigma, logPrior, classes);
pred_cat = categorical(pred_raw);

acc = mean(pred_cat == YTest);
fprintf('Exatidão no conjunto de teste : %.4f  (%.2f%%)\n', acc, acc * 100);

% Exatidão no treino — para detetar sub-ajuste grosseiro
[pred_train_raw, ~] = nb_predict(XTrain, mu, sigma, logPrior, classes);
acc_train = mean(categorical(pred_train_raw) == YTrain);
fprintf('Exatidão no conjunto de treino: %.4f  (%.2f%%)\n\n', acc_train, acc_train * 100);

%% ----------------------------------------------------------------
%  Teste 3: Probabilidades Posteriores — integridade
%% ----------------------------------------------------------------
fprintf('--- Teste 3: Integridade das Probabilidades Posteriores ---\n');

% 3a) Cada linha deve somar 1
prob_sums = sum(p_all, 2);
max_err   = max(abs(prob_sums - 1));
if max_err < 1e-6
    fprintf('PASSOU (3a): Posteriors somam 1 para todas as amostras (erro máx=%.2e)\n', max_err);
else
    fprintf('FALHOU (3a): Posteriors não somam 1 (erro máx=%.2e)\n', max_err);
end

% 3b) Todos os valores entre 0 e 1
if all(p_all(:) >= 0) && all(p_all(:) <= 1)
    fprintf('PASSOU (3b): Todos os valores estão em [0, 1]\n');
else
    fprintf('FALHOU (3b): Existem valores fora de [0, 1]\n');
end

% 3c) A classe com maior posterior coincide com a previsão
[~, best_col] = max(p_all, [], 2);
pred_from_prob = categorical(classes(best_col));
agreement = mean(pred_from_prob == pred_cat);
if agreement == 1
    fprintf('PASSOU (3c): Previsão concorda sempre com o argmax dos posteriors\n\n');
else
    fprintf('FALHOU (3c): Previsão discorda do argmax em %.2f%% dos casos\n\n', (1-agreement)*100);
end

%% ----------------------------------------------------------------
%  Teste 4: Métricas por Classe — Precision, Recall, F1, FPR, FNR
%  (extraído e adaptado de evaluate.m, secções 2 e 3)
%% ----------------------------------------------------------------
fprintf('--- Teste 4: Métricas por Classe (Precision / Recall / F1 / FPR / FNR) ---\n');
fprintf('%-12s  %9s  %10s  %9s  %9s  %9s  %6s\n', ...
    'Classe', 'Precision', 'Recall/TPR', 'F1-Score', 'FPR', 'FNR', 'Sup.');
fprintf('%s\n', repmat('-', 1, 78));

precisoes = zeros(nClasses,1);
recalls   = zeros(nClasses,1);
f1scores  = zeros(nClasses,1);
fprs      = zeros(nClasses,1);
fnrs      = zeros(nClasses,1);
suportes  = zeros(nClasses,1);

for c = 1:nClasses
    tp = sum(pred_cat == classes{c} & YTest == classes{c});
    fp = sum(pred_cat == classes{c} & YTest ~= classes{c});
    fn = sum(pred_cat ~= classes{c} & YTest == classes{c});
    tn = nTeste - tp - fp - fn;

    p   = tp / max(tp + fp, 1);
    r   = tp / max(tp + fn, 1);
    f1  = 2 * p * r / max(p + r, 1e-9);
    fpr = fp / max(fp + tn, 1);
    fnr = fn / max(fn + tp, 1);

    precisoes(c) = p;  recalls(c)   = r;
    f1scores(c)  = f1; fprs(c)      = fpr;
    fnrs(c)      = fnr;
    suportes(c)  = sum(YTest == classes{c});

    fprintf('%-12s  %9.4f  %10.4f  %9.4f  %9.4f  %9.4f  %6d\n', ...
        classes{c}, p, r, f1, fpr, fnr, suportes(c));
end

fprintf('%s\n', repmat('-', 1, 78));
fprintf('%-12s  %9.4f  %10.4f  %9.4f  %9.4f  %9.4f  %6d\n', ...
    'Macro avg', mean(precisoes), mean(recalls), mean(f1scores), ...
    mean(fprs), mean(fnrs), nTeste);
fprintf('%-12s  %9.4f  %10.4f  %9.4f  %9.4f  %9.4f  %6d\n', ...
    'Weighted avg', ...
    sum(precisoes .* suportes)/nTeste, sum(recalls   .* suportes)/nTeste, ...
    sum(f1scores  .* suportes)/nTeste, sum(fprs      .* suportes)/nTeste, ...
    sum(fnrs      .* suportes)/nTeste, nTeste);
fprintf('\n  TPR = TP / (TP + FN)  |  FPR = FP / (FP + TN)  |  FNR = FN / (FN + TP)\n\n');

%% ----------------------------------------------------------------
%  Teste 5: Matriz de Confusão
%  (extraído de evaluate.m, secções 4 e 5)
%% ----------------------------------------------------------------
fprintf('--- Teste 5: Matriz de Confusão ---\n');
confMatrix = confusionmat(YTest, pred_cat, 'Order', classes);

fprintf('%12s', '');
for c = 1:nClasses, fprintf('%10s', classes{c}); end
fprintf('  <- Previsto\n');
fprintf('%s\n', repmat('-', 1, 12 + nClasses * 10 + 12));
for c = 1:nClasses
    fprintf('%-12s', classes{c});
    for k = 1:nClasses, fprintf('%10d', confMatrix(c, k)); end
    fprintf('\n');
end
fprintf('^ Real\n\n');

try
    figure('Name', 'NB — Matriz de Confusão');
    confusionchart(YTest, pred_cat, ...
        'Title',         'Naive Bayes — Matriz de Confusão', ...
        'RowSummary',    'row-normalized', ...
        'ColumnSummary', 'column-normalized');
catch
end

%% ----------------------------------------------------------------
%  Teste 6: Validação Cruzada 5-Fold
%% ----------------------------------------------------------------
fprintf('--- Teste 6: Validação Cruzada (5-Fold) ---\n');
k_fold    = 5;
N_all     = size(X, 1);
fold_size = floor(N_all / k_fold);
cv_accs   = zeros(k_fold, 1);

for fold = 1:k_fold
    test_i  = (fold-1)*fold_size + 1 : fold*fold_size;
    train_i = setdiff(1:N_all, test_i);
    [mu_cv, sig_cv, lp_cv, cls_cv] = nb_train(X(train_i,:), Y(train_i));
    [pred_cv, ~] = nb_predict(X(test_i,:), mu_cv, sig_cv, lp_cv, cls_cv);
    cv_accs(fold) = mean(categorical(pred_cv) == Y(test_i));
    fprintf('  Fold %d: %.4f (%.2f%%)\n', fold, cv_accs(fold), cv_accs(fold)*100);
end
fprintf('  Média: %.4f ± %.4f\n\n', mean(cv_accs), std(cv_accs));

fprintf('============================================================\n');
fprintf('         TESTES DO NAIVE BAYES CONCLUÍDOS                  \n');
fprintf('============================================================\n');