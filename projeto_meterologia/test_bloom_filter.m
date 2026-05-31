% test_bloom_filter.m
% Testes do módulo Bloom Filter
% MPEI 2025-2026

clc; clear; close all;

baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'bloom_filter'));

fprintf('============================================================\n');
fprintf('            TESTES DO MÓDULO BLOOM FILTER                  \n');
fprintf('============================================================\n\n');

%% --- Preparação dos Dados ---
data = readtable(fullfile(baseDir, 'data', 'beijing.csv'));
data.date           = [];
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

bf_cols   = [1, 17, 14, 12, 2, 7];
bf_breaks = [2,  4, 10; ...
             3,  6, 12; ...
             35, 60, 80; ...
             55, 70, 82; ...
             10, 18, 25; ...
             25, 40, 55];

fprintf('Treino: %d amostras | Teste: %d amostras\n\n', size(XTrain,1), size(XTest,1));

%% ----------------------------------------------------------------
%  Teste 1: Inicialização do Filtro
%% ----------------------------------------------------------------
fprintf('--- Teste 1: Inicialização do Bloom Filter ---\n');
m   = 50000;
k   = round((m / size(XTrain,1)) * log(2));
bf  = bloom_init(m, k);

fprintf('Número de bits  (m)      : %d\n', m);
fprintf('Número de hashes (k)     : %d\n', k);
fprintf('FPR teórica (filtro vazio): %.6f%%\n', bloom_fp_rate(bf) * 100);

% Verificar que o filtro foi criado vazio (FPR deve ser 0 ou valor base)
fpr_init = bloom_fp_rate(bf);
if fpr_init == 0 || fpr_init < 1e-10
    fprintf('PASSOU: Filtro inicializado vazio (FPR=%.2e)\n\n', fpr_init);
else
    fprintf('INFO: FPR inicial = %.6f (depende da implementação)\n\n', fpr_init);
end

%% ----------------------------------------------------------------
%  Teste 2: Inserção — sem Falsos Negativos
%  (propriedade fundamental do Bloom Filter)
%% ----------------------------------------------------------------
fprintf('--- Teste 2: Inserção — Garantia de Sem Falsos Negativos ---\n');
keysTrain = build_bf_key(XTrain, bf_cols, bf_breaks);
for i = 1:length(keysTrain)
    bf = bloom_insert(bf, keysTrain(i));
end
fprintf('Elementos inseridos: %d\n', length(keysTrain));
fprintf('FPR estimada após inserção: %.4f%%\n', bloom_fp_rate(bf) * 100);

% Todos os elementos inseridos DEVEM ser encontrados
nEncontrados = 0;
for i = 1:length(keysTrain)
    if bloom_check(bf, keysTrain(i))
        nEncontrados = nEncontrados + 1;
    end
end
tpr = nEncontrados / length(keysTrain);
fprintf('Elementos de treino encontrados: %d / %d  (TPR=%.4f)\n', ...
    nEncontrados, length(keysTrain), tpr);
if tpr == 1.0
    fprintf('PASSOU: Nenhum falso negativo — todos os elementos inseridos são encontrados\n\n');
else
    fprintf('FALHOU: Existem falsos negativos (%.2f%% não encontrados)\n\n', (1-tpr)*100);
end

%% ----------------------------------------------------------------
%  Teste 3: Dias de Teste Vistos vs Novos
%  (extraído de evaluate.m — Secção 1: Bloom Filter)
%% ----------------------------------------------------------------
fprintf('--- Teste 3: Dias de Teste — Vistos vs Definitivamente Novos ---\n');
fprintf('(Equivalente ao bloco "Bloom Filter: Dias de Teste vs Histórico" em evaluate.m)\n');
nTeste   = size(XTest, 1);
nVisto   = 0;
nNaoVisto = 0;
for i = 1:nTeste
    key = build_bf_key(XTest(i,:), bf_cols, bf_breaks);
    if bloom_check(bf, key)
        nVisto   = nVisto + 1;
    else
        nNaoVisto = nNaoVisto + 1;
    end
end
fprintf('  Dias provavelmente vistos no treino : %d / %d\n', nVisto,    nTeste);
fprintf('  Dias definitivamente novos          : %d / %d\n', nNaoVisto, nTeste);
fprintf('  FPR estimada do filtro              : %.4f%%\n\n', bloom_fp_rate(bf) * 100);

%% ----------------------------------------------------------------
%  Teste 4: Taxa de Falsos Positivos Empírica vs Teórica
%% ----------------------------------------------------------------
fprintf('--- Teste 4: FPR Empírica vs Teórica ---\n');
keysTest    = build_bf_key(XTest, bf_cols, bf_breaks);
keysTrain_set = unique(keysTrain);   % conjunto único de chaves de treino

nFP         = 0;
nActualNew  = 0;
for i = 1:length(keysTest)
    found = bloom_check(bf, keysTest(i));
    isNew = ~any(strcmp(keysTest(i), keysTrain_set));
    if isNew
        nActualNew = nActualNew + 1;
        if found
            nFP = nFP + 1;
        end
    end
end

fpr_teorica  = bloom_fp_rate(bf) * 100;
if nActualNew > 0
    fpr_empirica = (nFP / nActualNew) * 100;
    fprintf('  Elementos de teste realmente novos: %d / %d\n', nActualNew, length(keysTest));
    fprintf('  Falsos positivos observados       : %d\n',       nFP);
    fprintf('  FPR empírica                      : %.4f%%\n',   fpr_empirica);
    fprintf('  FPR teórica (bloom_fp_rate)        : %.4f%%\n\n', fpr_teorica);
else
    fprintf('  Todos os elementos de teste têm chave já presente no treino.\n');
    fprintf('  FPR teórica: %.4f%%\n\n', fpr_teorica);
end

%% ----------------------------------------------------------------
%  Teste 5: Efeito dos Parâmetros m e k na FPR
%% ----------------------------------------------------------------
fprintf('--- Teste 5: Efeito dos Parâmetros m e k na FPR ---\n');
fprintf('  %-10s  %-5s  %-20s  %-10s\n', 'm (bits)', 'k', 'FPR teórica (%)', 'k ótimo');
fprintf('  %s\n', repmat('-', 1, 55));

m_vals = [10000, 25000, 50000, 100000, 200000];
k_vals = [2, 3, 5, 7, 10];
n_elem = size(XTrain, 1);

for m_test = m_vals
    k_opt_test = max(1, round((m_test / n_elem) * log(2)));
    for k_test = k_vals
        bf_test = bloom_init(m_test, k_test);
        for i = 1:length(keysTrain)
            bf_test = bloom_insert(bf_test, keysTrain(i));
        end
        fpr_test = bloom_fp_rate(bf_test) * 100;
        marker = '';
        if k_test == k_opt_test, marker = '<-- k ótimo'; end
        fprintf('  %-10d  %-5d  %-20.6f  %s\n', m_test, k_test, fpr_test, marker);
    end
    fprintf('\n');
end

%% ----------------------------------------------------------------
%  Teste 6: Verificação por Classe — Distribuição de Elementos Vistos
%% ----------------------------------------------------------------
fprintf('--- Teste 6: Distribuição de Dias Vistos por Classe de Tempo ---\n');
classes = unique(YTest);
fprintf('  %-12s  %-12s  %-12s  %-10s\n', 'Classe', 'Total Teste', 'Vistos', '% Vistos');
fprintf('  %s\n', repmat('-', 1, 50));
for c = 1:numel(classes)
    cls      = classes(c);
    idx_cls  = find(YTest == cls);
    nCls     = numel(idx_cls);
    nVis_cls = 0;
    for i = 1:nCls
        key = build_bf_key(XTest(idx_cls(i),:), bf_cols, bf_breaks);
        if bloom_check(bf, key)
            nVis_cls = nVis_cls + 1;
        end
    end
    fprintf('  %-12s  %-12d  %-12d  %.1f%%\n', char(cls), nCls, nVis_cls, 100*nVis_cls/max(nCls,1));
end
fprintf('\n');

fprintf('============================================================\n');
fprintf('         TESTES DO BLOOM FILTER CONCLUÍDOS                 \n');
fprintf('============================================================\n');