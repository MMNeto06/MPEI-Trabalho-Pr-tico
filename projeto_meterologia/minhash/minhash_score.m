function scores = minhash_score(sigTrain, YTrain, sigQuery, classes, k)
    nClasses = numel(classes);
    scores = zeros(1, nClasses);
    sigQuery = sigQuery(:);          

    matches = sigTrain == sigQuery;  
    allSims = mean(matches, 1);      

    for c = 1:nClasses
        idx = (YTrain == classes{c});
        sims = allSims(idx);
        if isempty(sims)
            scores(c) = 0;
            continue;
        end
        k_eff = min(k, numel(sims));
        topK = maxk(sims, k_eff);   
        scores(c) = mean(topK);
    end

    s = sum(scores);
    if s > 1e-9
        scores = scores / s;
    else
        scores = ones(1, nClasses) / nClasses;
    end
end