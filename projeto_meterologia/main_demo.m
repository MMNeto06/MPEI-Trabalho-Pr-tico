%% main_demo.m  —  Pipeline completo: carregamento → treino → previsão → avaliação
%
% Features base (sempre presentes no CSV):
%   precipitation  — precipitação (mm)
%   temp_max       — temperatura máxima (°C)
%   temp_min       — temperatura mínima (°C)
%   wind           — velocidade média do vento (m/s)
%   snow_depth     — profundidade de neve acumulada (mm)
%   temp_range     — amplitude térmica (TMAX − TMIN)
%   month_sin      — componente seno do mês (codificação cíclica)
%   month_cos      — componente coseno do mês (codificação cíclica)
%
% Features opcionais (presentes apenas em estações NOAA que as reportam):
%   tsun           — total de horas de sol do dia (minutos)
%   wsf2           — velocidade máxima de rajada em 2 minutos (m/s)

%% 0) Definir pasta base e adicionar pastas ao path do MATLAB
baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'naive_bayes'));
addpath(fullfile(baseDir, 'bloom_filter'));
addpath(fullfile(baseDir, 'minhash'));

%% 1) Carregar e preparar os dados
fprintf('=== A carregar dados ===\n');
dados = readtable(fullfile(baseDir, 'data', 'seattle.csv'));

variaveis = dados.Properties.VariableNames;

colunasBase = {'precipitation', 'temp_max', 'temp_min', 'wind', ...
               'snow_depth', 'temp_range', 'month_sin', 'month_cos'};
if ~all(ismember(colunasBase, variaveis))
    error('CSV sem colunas base. Regenera com o weather.py actualizado.');
end

nomeFeatures = colunasBase;
if ismember('tsun', variaveis)
    nomeFeatures{end+1} = 'tsun';
    fprintf('  Coluna TSUN detectada — incluída nas features.\n');
end
if ismember('wsf2', variaveis)
    nomeFeatures{end+1} = 'wsf2';
    fprintf('  Coluna WSF2 detectada — incluída nas features.\n');
end

fprintf('  A usar %d features: %s\n\n', numel(nomeFeatures), strjoin(nomeFeatures, ', '));

X = table2array(dados(:, nomeFeatures));
Y = categorical(dados.weather);

classes   = categories(Y);
nFeatures = size(X, 2);
N         = size(X, 1);

fprintf('Dataset: %d amostras | %d features | %d classes\n', N, nFeatures, numel(classes));
fprintf('Classes: %s\n\n', strjoin(classes', ', '));

%% 2) Divisão treino / teste  (80 / 20)
rng(42);
idx               = randperm(N);
percentagemTreino = 0.8;
nTreino           = round(percentagemTreino * N);

idxTreino = idx(1:nTreino);
idxTeste  = idx(nTreino+1:end);

XTreino = X(idxTreino, :);
YTreino = Y(idxTreino);
XTeste  = X(idxTeste,  :);
YTeste  = Y(idxTeste);

fprintf('Treino: %d amostras | Teste: %d amostras\n\n', nTreino, numel(idxTeste));

%% 3) Bloom Filter
fprintf('=== A construir Bloom Filter ===\n');

fpr_alvo = 0.01;
m_bf     = ceil(-(nTreino * log(fpr_alvo)) / (log(2)^2));
k_bf     = max(1, round((m_bf / nTreino) * log(2)));

bf = bloom_init(m_bf, k_bf);
for i = 1:nTreino
    bf = bloom_insert(bf, mat2str(XTreino(i,:), 4));
end

fprintf('  m = %d bits | k = %d hashes | FPR teórica = %.4f%%\n\n', ...
    m_bf, k_bf, bloom_fp_rate(bf) * 100);

%% 4) Treino Naive-Bayes
fprintf('=== A treinar Naive Bayes Gaussiano ===\n');
[mu, sigma, logPrior, classes] = nb_train(XTreino, YTreino);

fprintf('\n%-12s  %8s\n', 'Classe', 'Prior');
fprintf('%s\n', repmat('-', 1, 22));
for c = 1:numel(classes)
    fprintf('%-12s  %8.3f\n', classes{c}, exp(logPrior(c)));
end
fprintf('\n');

%% 5) Previsão
fprintf('=== A classificar conjunto de teste ===\n');
[previsoes, probas] = nb_predict(XTeste, mu, sigma, logPrior, classes);

%% 6) Avaliação
fprintf('\n=== Avaliação ===\n');
evaluate(YTeste, previsoes, classes, XTeste, bf);

%% 7) Exemplo de previsão para um novo ponto
fprintf('\n=== Exemplo de previsão manual ===\n');

mes       = 1;
novoPonto = [5.0, 14.0, 8.0, 3.5, 0.0, 6.0, sin(2*pi*mes/12), cos(2*pi*mes/12)];
if ismember('tsun', nomeFeatures), novoPonto(end+1) = 0.0; end
if ismember('wsf2', nomeFeatures), novoPonto(end+1) = 5.0; end

fprintf('Entrada (mês = Janeiro):\n');
for j = 1:nFeatures
    fprintf('  %-14s = %.4f\n', nomeFeatures{j}, novoPonto(j));
end
fprintf('\n');

chaveNovo = mat2str(novoPonto, 4);
if bloom_check(bf, chaveNovo)
    fprintf('Bloom Filter: padrão provavelmente visto no treino.\n');
else
    fprintf('Bloom Filter: padrão NOVO — não está no histórico de treino.\n');
end

[prevNovo, probNovo] = nb_predict(novoPonto, mu, sigma, logPrior, classes);
fprintf('\nProbabilidades por classe:\n');
for c = 1:numel(classes)
    fprintf('  %-12s  %.4f\n', classes{c}, probNovo(c));
end
fprintf('\nPrevisão final: %s\n', char(prevNovo));

%% 8) Efeito do mês na previsão (mesmo perfil físico)
fprintf('\n=== Efeito do mês na previsão (mesmo perfil físico) ===\n');
fprintf('Perfil base: prcp=2.0 tmax=18.0 tmin=10.0 wind=2.5 snow=0 trange=8.0\n\n');
fprintf('%-6s  %-12s  %s\n', 'Mês', 'Previsão', 'Probabilidades');
fprintf('%s\n', repmat('-', 1, 70));

mesesNomes = {'Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'};
for mes = 1:12
    ponto = [2.0, 18.0, 10.0, 2.5, 0.0, 8.0, sin(2*pi*mes/12), cos(2*pi*mes/12)];
    if ismember('tsun', nomeFeatures), ponto(end+1) = 200.0; end 
    if ismember('wsf2', nomeFeatures), ponto(end+1) = 4.0;   end

    [prev, prob] = nb_predict(ponto, mu, sigma, logPrior, classes);
    probStr = '';
    for c = 1:numel(classes)
        probStr = [probStr sprintf('%s=%.2f  ', classes{c}, prob(c))];
    end
    fprintf('%-6s  %-12s  %s\n', mesesNomes{mes}, char(prev), probStr);
end