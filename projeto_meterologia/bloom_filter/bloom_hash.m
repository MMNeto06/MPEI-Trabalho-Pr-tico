function positions = bloom_hash(str, bf)
    s = uint32(double(char(str)));
    h1 = uint32(5381);
    for c = s
        h1 = bitxor(uint32(mod(double(bitshift(h1,5)) + double(h1), 2^32)), c);
    end
    h2 = uint32(2166136261);
    for c = s
        h2 = uint32(mod(double(bitxor(h2, c)) * 16777619, 2^32));
    end

    h1 = double(h1);
    h2 = double(h2) | 1;

    i  = (0:bf.k-1)';
    positions = mod(h1 + i.*h2, bf.m) + 1;
end

%{
Função de hash muito simples (má). Poderá ser utilizada para comparação de
resultados
function positions = bloom_hash(str, bf)
    s = double(str);

    h = sum(s);

    positions = zeros(1, bf.k);

    for i = 1:bf.k
        positions(i) = mod(h + i*31, bf.m) + 1;
    end

end
%}