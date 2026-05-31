function [previsoes, probas] = nb_predict(XTeste, mu, sigma, logPrior, classes)
    nTeste   = size(XTeste, 1);
    nClasses = numel(classes);

    logPost = zeros(nTeste, nClasses);
    for c = 1:nClasses
        diff      = XTeste - mu(c,:);          
        logL      = -log(sigma(c,:)) - 0.5*log(2*pi) - 0.5*(diff ./ sigma(c,:)).^2;
        logPost(:,c) = logPrior(c) + sum(logL, 2);
    end

    logPost  = logPost - max(logPost, [], 2);          
    probas   = exp(logPost) ./ sum(exp(logPost), 2);   
    [~, idx] = max(probas, [], 2);
    previsoes = classes(idx);
end