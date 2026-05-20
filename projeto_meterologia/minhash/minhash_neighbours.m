function [neighboursIdx, neighboursSim] = minhash_neighbours(sigTrain, sigQuery, k)
    sigQuery = sigQuery(:);          % garante coluna (nHash x 1)
    sims = mean(sigTrain == sigQuery, 1);   % broadcast seguro agora
    [orderedSims, orderedIdxs] = sort(sims, 'descend');
    k = min(k, numel(orderedSims));
    neighboursIdx = orderedIdxs(1:k);
    neighboursSim = orderedSims(1:k);
end