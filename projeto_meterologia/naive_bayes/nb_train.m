function [mu, sigma, logPrior, classes] = nb_train(XTreino, YTreino)
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
        sigma(c, :) = std(XClasse, 1) + 1e-9;  
        logPrior(c) = log(sum(mask) / nTreino);
    end
end