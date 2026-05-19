function sim = minhash_similarity(sig, i, j)
    sim = mean(sig(:, i) == sig(:, j));
end