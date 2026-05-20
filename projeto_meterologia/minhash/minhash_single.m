function sigQuery = minhash_single(tokens, hashData)
    [sig, ~] = minhash_signature({tokens}, hashData);
    sigQuery = sig(:,1);
end