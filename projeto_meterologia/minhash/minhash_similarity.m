function sim = minhash_similarity(sig1, sig2)
    sim = mean(sig1(:) == sig2(:));
end