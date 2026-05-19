function [neighboursIdx, neighboursSim] = minhash_neighbours(sigTrain, sigQuery, k)
    sims = mean(sigTrain == sigQuery, 1);   
    [orderedSims, orderedIdxs] = sort(sims, 'descend');
    k = min(k, numel(orderedSims));
    neighboursIdx = orderedIdxs(1:k);
    neighboursSim = orderedSims(1:k);
end