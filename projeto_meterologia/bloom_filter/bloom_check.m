function exists = bloom_check(bf, element)
    idx = bloom_hash(element, bf);

    exists = true;

    for i = 1:length(idx)
        if bf.bits(idx(i)) == false
            exists = false;
            return;
        end
    end
end