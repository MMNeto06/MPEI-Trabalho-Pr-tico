function [previsoes, probas] = nb_predict(XTeste, mu, sigma, logPrior, classes)
    % log da densidade Gaussiana: logN(x | m, s)
    logGauss = @(x, m, s) -log(s) - 0.5*log(2*pi) - 0.5*((x - m)./s).^2;

    nTeste   = size(XTeste, 1);
    nClasses = numel(classes);

    previsoes = categorical(repmat("", nTeste, 1));
    probas    = zeros(nTeste, nClasses);

    for i = 1:nTeste
        x       = XTeste(i, :);
        logPost = zeros(nClasses, 1);

        for c = 1:nClasses
            % log P(c | x) ∝ log P(c) + Σ_j log P(x_j | c)
            logPost(c) = logPrior(c) + sum(logGauss(x, mu(c,:), sigma(c,:)));
        end

        logPost  = logPost - max(logPost);
        prob     = exp(logPost) / sum(exp(logPost));
        probas(i, :) = prob';

        [~, idxMax]  = max(prob);
        previsoes(i) = classes{idxMax};
    end
end