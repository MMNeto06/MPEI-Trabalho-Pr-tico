function scores = minhash_score(sigTrain, YTrain, sigQuery, classes, k)
    nClasses = numel(classes);
    scores = zeros(1, nClasses);
    
    sigQuery = sigQuery(:);
    
    for c = 1:nClasses
    
        idx = (YTrain == classes{c});
        sigC = sigTrain(:, idx);
    
        if isempty(sigC)
            scores(c) = 0;
            continue;
        end
    
        sims = zeros(1, size(sigC,2));
    
        for j = 1:size(sigC,2)
            sims(j) = minhash_similarity(sigC(:,j), sigQuery);
        end
    
        sims = sort(sims, 'descend');
        k_eff = min(k, numel(sims));
    
        scores(c) = mean(sims(1:k_eff));
    
    end
    
    % normalizar para [0,1]
    s = sum(scores);
    if s > 1e-9
        scores = scores / s;
    else
        scores = ones(1, nClasses) / nClasses;
    end

end