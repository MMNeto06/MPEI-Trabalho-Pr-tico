%% main_demo.m  —  Pipeline completo: carregamento → treino → previsão → avaliação
%
% Estrutura do projeto esperada:
%   projeto_meteorologia/
%   ├── data/weather_data.csv
%   ├── naive_bayes/nb_train.m  nb_predict.m
%   ├── bloom_filter/bloom_init.m  bloom_insert.m  bloom_check.m  bloom_hash.m  bloom_fp_rate.m
%   ├── main_demo.m
%   └── evaluate.m

%% 0) Definir pasta base e adicionar pastas ao path do MATLAB
% Garante que os caminhos funcionam independentemente do working directory
baseDir = fileparts(mfilename('fullpath'));
addpath(fullfile(baseDir, 'naive_bayes'));
addpath(fullfile(baseDir, 'bloom_filter'));
addpath(fullfile(baseDir, 'minhash'));

%% 1) Carregar e preparar os dados
fprintf('=== A carregar dados ===\n');
dados = readtable(fullfile(baseDir, 'data', 'seattle-weather.csv'));

nomeFeatures = {'precipitation', 'temp_max', 'temp_min', 'wind'};
X = table2array(dados(:, nomeFeatures));
Y = categorical(dados.weather);

classes   = categories(Y);
nFeatures = size(X, 2);
N         = size(X, 1);

fprintf('Dataset: %d amostras | %d features | %d classes\n', N, nFeatures, numel(classes));
fprintf('Classes: %s\n\n', strjoin(classes', ', '));

%% 2) Divisão treino / teste  (80 / 20)
% Descomenta rng(42) para resultados reprodutíveis
% rng(42);
idx              = randperm(N);
percentagemTreino = 0.8;
nTreino          = round(percentagemTreino * N);

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
m_bf = ceil(-(nTreino * log(fpr_alvo)) / (log(2)^2));
k_bf = max(1, round((m_bf / nTreino) * log(2)));

bf = bloom_init(m_bf, k_bf);
for i = 1:nTreino
    bf = bloom_insert(bf, mat2str(XTreino(i,:), 4));
end

fprintf('  m = %d bits | k = %d hashes | FPR teórica = %.4f%%\n\n', ...
    m_bf, k_bf, bloom_fp_rate(bf) * 100);

%% 4) Treino Naive-Bayes
fprintf('=== A treinar Naive Bayes Gaussiano ===\n');
[mu, sigma, logPrior, classes] = nb_train(XTreino, YTreino);

% Mostrar parâmetros aprendidos
fprintf('\n%-12s  %8s  ', 'Classe', 'Prior');
fprintf('%-15s  ', nomeFeatures{:});
fprintf('\n%s\n', repmat('-', 1, 12 + 10 + nFeatures*20));

for c = 1:numel(classes)
    fprintf('%-12s  %8.3f  ', classes{c}, exp(logPrior(c)));
    for j = 1:nFeatures
        fprintf('mu=%.2f s=%.2f     ', mu(c,j), sigma(c,j));
    end
    fprintf('\n');
end
fprintf('\n');

%% 5) Previsão
fprintf('=== A classificar conjunto de teste ===\n');
[previsoes, probas] = nb_predict(XTeste, mu, sigma, logPrior, classes);

%% 6) Avaliação  (delega em evaluate.m)
fprintf('\n=== Avaliação ===\n');
evaluate(YTeste, previsoes, classes, XTeste, bf);

%% 7) Exemplo de previsão para um novo ponto
fprintf('\n=== Exemplo de previsão manual ===\n');
novoPonto   = [5.0, 8.0, 3.0, 4.5];   % [precipitation, temp_max, temp_min, wind]
nomesCampos = {'precipitation', 'temp_max', 'temp_min', 'wind'};

fprintf('Entrada: ');
for j = 1:nFeatures
    fprintf('%s=%.1f  ', nomesCampos{j}, novoPonto(j));
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