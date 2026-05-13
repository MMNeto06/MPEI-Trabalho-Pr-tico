function bf = bloom_init(m,k)
    bf.bits = zeros(1,m); 
    bf.m = m; 
    bf.k = k; 
    bf.elemCount = 0;
end