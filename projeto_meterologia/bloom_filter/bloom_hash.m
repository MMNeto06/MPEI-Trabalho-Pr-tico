%{
Esta função usa double hashing para reduzir colisões. 
Might be too much, idk. 
DJB2 em h1 e FNV-1a em h2
%}
function positions = bloom_hash(str, bf)
    s = double(str);
    h1 = uint32(5381);
    
    for c = s
        h1 = bitand(bitxor(bitshift(h1,5) + h1, uint32(c)), uint32(4294967295));
    end

    h2 = uint32(2166136261);
    for c = s
        h2 = bitand(bitxor(h2, uint32(c)) * uint32(16777619), uint32(4294967295));
    end

    h1 = double(h1);
    h2 = double(h2);
    if mod(h2, 2) == 0
        h2 = h2 + 1; 
    end

    positions = zeros(1, bf.k);
    for i = 0:(bf.k-1)
        positions(i+1) = mod(h1 + i*h2, bf.m) + 1;
    end
end

%{
A de cima é muito (pode ser demasiado) op, vou deixar aqui esta 
pelo sim, pelo não
function positions = bloom_hash(str, bf)
    s = double(str);

    h = sum(s);

    positions = zeros(1, bf.k);

    for i = 1:bf.k
        positions(i) = mod(h + i*31, bf.m) + 1;
    end

end
%}
