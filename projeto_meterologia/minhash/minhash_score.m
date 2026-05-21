function scores = minhash_score(sigTrain, YTrain, sigQuery, classes, k)
    nClasses = numel(classes);
    scores   = zeros(1, nClasses);
    sigQuery = sigQuery(:);          % (numHashes × 1)

    % Similaridade Jaccard aproximada: fracção de posições iguais
    % sigTrain é (numHashes × nTrain) — comparação vectorizada com broadcast
    matches = sigTrain == sigQuery;  % (numHashes × nTrain), lógico
    allSims = mean(matches, 1);      % (1 × nTrain)

    for c = 1:nClasses
        idx  = (YTrain == classes{c});
        sims = allSims(idx);
        if isempty(sims)
            scores(c) = 0;
            continue;
        end
        k_eff     = min(k, numel(sims));
        topK      = maxk(sims, k_eff);   % top-K sem sort completo
        scores(c) = mean(topK);
    end

    s = sum(scores);
    if s > 1e-9
        scores = scores / s;
    else
        scores = ones(1, nClasses) / nClasses;
    end
end