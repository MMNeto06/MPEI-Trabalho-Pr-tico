function fp = bloom_fp_rate(bf)
    fp = (1 - exp(-bf.k * bf.elemCount / bf.m))^bf.k;
end