function bf = bloom_insert(bf, key)
    pos = bloom_hash(key, bf);
    bf.bits(pos) = 1;
    bf.elemCount = bf.elemCount + 1;
end