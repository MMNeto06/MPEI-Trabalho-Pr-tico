%% Classificador Naive Bayes Gaussiano - Seattle Weather
% Previsão da categoria de tempo (weather) com base em:
%   precipitation, temp_max, temp_min, wind
%
% Como as features são contínuas, usamos Gaussian Naive Bayes:
%   P(xi | classe) ~ N(média, desvio padrão) por feature e por classe.
% A previsão é feita com log-probabilidades para evitar underflow numérico.

%% 1) Carregar e preparar os dados
dados = readtable('seattle-weather.csv');

X = table2array(dados(:, {'precipitation', 'temp_max', 'temp_min', 'wind'}));
nomeFeatures = {'precipitation', 'temp_max', 'temp_min', 'wind'};

Y = categorical(dados.weather);
classes = categories(Y);   % {'drizzle','fog','rain','snow','sun'}
nClasses = numel(classes);
nFeatures = size(X, 2);
N = size(X, 1);

fprintf('Dataset: %d amostras, %d features, %d classes\n', N, nFeatures, nClasses);
fprintf('Classes: ');
disp(classes')

%% 2) Divisão treino / teste
%rng(42); -> definição de seed, comentado neste momento. se quisermos reproduzir sempre os mesmos dados descomentar
idx = randperm(N);
percentagemTreino = 0.8;
nTreino = round(percentagemTreino * N);

idxTreino = idx(1:nTreino);
idxTeste = idx(nTreino+1:end);

XTreino = X(idxTreino, :);
YTreino = Y(idxTreino);
XTeste = X(idxTeste,  :);
YTeste = Y(idxTeste);

fprintf('\nTreino: %d amostras | Teste: %d amostras\n', nTreino, numel(idxTeste));

%% 3) Treino: estimar priors e parâmetros Gaussianos por classe
% Para cada classe c e feature j, guardamos:
%   mu(c,j)    = média de X(:,j) nos exemplos de classe c
%   sigma(c,j) = desvio padrão de X(:,j) nos exemplos de classe c
%   logPrior(c) = log( P(classe c) )

mu = zeros(nClasses, nFeatures);
sigma = zeros(nClasses, nFeatures);
logPrior = zeros(nClasses, 1);

for c = 1:nClasses
    mask = (YTreino == classes{c});
    XClasse = XTreino(mask, :);
    
    mu(c, :) = mean(XClasse, 1);
    sigma(c, :) = std(XClasse, 1) + 1e-9;   % epsilon para evitar divisão por zero
    logPrior(c) = log(sum(mask) / nTreino);
end

fprintf('\n--- Parâmetros aprendidos por classe ---\n');
for c = 1:nClasses
    fprintf('\nClasse: %s  (prior=%.3f)\n', classes{c}, exp(logPrior(c)));
    for j = 1:nFeatures
        fprintf('  %-15s  mu=%.3f  sigma=%.3f\n', nomeFeatures{j}, mu(c,j), sigma(c,j));
    end
end

%% 4) Função auxiliar: log da densidade Gaussiana
% logN(x, mu, sigma) = -log(sigma) - 0.5*log(2*pi) - 0.5*((x-mu)/sigma)^2
logGauss = @(x, m, s) -log(s) - 0.5*log(2*pi) - 0.5*((x - m)./s).^2;

%% 5) Previsão no conjunto de teste
nTeste = numel(YTeste);
previsoes = categorical(repmat("", nTeste, 1));

for i = 1:nTeste
    x = XTeste(i, :);
    logPost = zeros(nClasses, 1);
    
    for c = 1:nClasses
        % log P(c | x) ∝ log P(c) + sum_j log P(x_j | c)
        logPost(c) = logPrior(c);
        for j = 1:nFeatures
            logPost(c) = logPost(c) + logGauss(x(j), mu(c,j), sigma(c,j));
        end
    end
    
    [~, idxMax] = max(logPost);
    previsoes(i) = classes{idxMax};
end

%% 6) Métricas de avaliação global
acuracia = mean(previsoes == YTeste);
fprintf('\n=== Métricas Globais ===\n');
fprintf('Acurácia: %.4f (%.2f%%)\n', acuracia, acuracia*100);

%% 7) Métricas por classe (precision, recall, F1)
fprintf('\n%-12s  %9s  %9s  %9s  %6s\n', 'Classe', 'Precision', 'Recall', 'F1-Score', 'Suporte');
fprintf('%s\n', repmat('-', 1, 55));

precisoes = zeros(nClasses, 1);
recalls = zeros(nClasses, 1);
f1scores = zeros(nClasses, 1);
suportes = zeros(nClasses, 1);

for c = 1:nClasses
    tp = sum(previsoes == classes{c} & YTeste == classes{c});
    fp = sum(previsoes == classes{c} & YTeste ~= classes{c});
    fn = sum(previsoes ~= classes{c} & YTeste == classes{c});
    suporte = sum(YTeste == classes{c});
    
    p = tp / max(tp + fp, 1);
    r = tp / max(tp + fn, 1);
    f1 = 2 * p * r / max(p + r, 1e-9);
    
    precisoes(c) = p;
    recalls(c) = r;
    f1scores(c) = f1;
    suportes(c) = suporte;
    
    fprintf('%-12s  %9.4f  %9.4f  %9.4f  %6d\n', classes{c}, p, r, f1, suporte);
end

fprintf('%s\n', repmat('-', 1, 55));
% Macro-average (média não ponderada entre classes)
fprintf('%-12s  %9.4f  %9.4f  %9.4f  %6d\n', 'Macro avg', mean(precisoes), mean(recalls), mean(f1scores), nTeste);
% Weighted average (ponderada pelo suporte de cada classe)
fprintf('%-12s  %9.4f  %9.4f  %9.4f  %6d\n', 'Weighted avg', sum(precisoes .* suportes) / nTeste, ...
    sum(recalls .* suportes) / nTeste, sum(f1scores .* suportes) / nTeste, nTeste);

%% 8) Matriz de confusão
fprintf('\n--- Matriz de Confusão ---\n');
confMatrix = confusionmat(YTeste, previsoes, 'Order', classes);

% Cabeçalho
fprintf('%12s', '');
for c = 1:nClasses
    fprintf('%10s', classes{c});
end
fprintf('  <- Previsto\n');
fprintf('%s\n', repmat('-', 1, 12 + nClasses*10 + 12));

for c = 1:nClasses
    fprintf('%-12s', classes{c});
    for k = 1:nClasses
        fprintf('%10d', confMatrix(c, k));
    end
    fprintf('\n');
end
fprintf('^ Real\n');

%% 9) Exemplo de previsão manual para um novo ponto
fprintf('\n--- Exemplo de previsão para novo ponto ---\n');
novoPonto = [5.0, 8.0, 3.0, 4.5];  % [precipitation, temp_max, temp_min, wind]
fprintf('Entrada: precipitation=%.1f, temp_max=%.1f, temp_min=%.1f, wind=%.1f\n', novoPonto);

logPostNovo = zeros(nClasses, 1);
for c = 1:nClasses
    logPostNovo(c) = logPrior(c);
    for j = 1:nFeatures
        logPostNovo(c) = logPostNovo(c) + logGauss(novoPonto(j), mu(c,j), sigma(c,j));
    end
end

% Converter log-posteriors em probabilidades (softmax numérico estável)
logPostNovo = logPostNovo - max(logPostNovo);
probNovo = exp(logPostNovo) / sum(exp(logPostNovo));

fprintf('\nProbabilidades por classe:\n');
for c = 1:nClasses
    fprintf('  %-12s  %.4f\n', classes{c}, probNovo(c));
end
[~, idxPrev] = max(probNovo);
fprintf('\nPrevisão: %s\n', classes{idxPrev});
