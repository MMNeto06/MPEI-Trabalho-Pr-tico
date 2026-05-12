function [mu, sigma, logPrior, classes] = nb_train(XTreino, YTreino)
%NB_TRAIN  Treina um classificador Naive Bayes Gaussiano.
%
%   [mu, sigma, logPrior, classes] = nb_train(XTreino, YTreino)
%
%   Entradas:
%     XTreino   — matriz (nTreino x nFeatures) de features contínuas
%     YTreino   — vetor categorical (nTreino x 1) com os rótulos de classe
%
%   Saídas:
%     mu        — matriz (nClasses x nFeatures) das médias por classe/feature
%     sigma     — matriz (nClasses x nFeatures) dos desvios-padrão por classe/feature
%     logPrior  — vetor  (nClasses x 1) com log( P(classe c) )
%     classes   — cell array com os nomes das classes (mesma ordem das linhas de mu/sigma)

    classes   = categories(YTreino);
    nClasses  = numel(classes);
    nFeatures = size(XTreino, 2);
    nTreino   = size(XTreino, 1);

    mu       = zeros(nClasses, nFeatures);
    sigma    = zeros(nClasses, nFeatures);
    logPrior = zeros(nClasses, 1);

    for c = 1:nClasses
        mask    = (YTreino == classes{c});
        XClasse = XTreino(mask, :);

        mu(c, :)    = mean(XClasse, 1);
        sigma(c, :) = std(XClasse, 1) + 1e-9;   % epsilon evita divisão por zero
        logPrior(c) = log(sum(mask) / nTreino);
    end
end