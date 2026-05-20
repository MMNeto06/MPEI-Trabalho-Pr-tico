function [sig, hashData] = minhash_signature(conjuntos, nHashOrData)
    N = numel(conjuntos);

    if isnumeric(nHashOrData)
        nHash = nHashOrData;
        universo = unique([conjuntos{:}]);
        U = numel(universo);
        p = nextprime(max(U * 100, 100003));
        a = randi(max(p-1,1), nHash, 1);
        b = randi(p, nHash, 1);
        tokenIdx = containers.Map(universo, 1:U);
        hashData.a = a;
        hashData.b = b;
        hashData.p = p;
        hashData.tokenIdx = tokenIdx;
    else
        hashData = nHashOrData;
        a = hashData.a;
        b = hashData.b;
        p = hashData.p;
        tokenIdx = hashData.tokenIdx;
        nHash = length(a);
    end

    sig = inf(nHash, N);
    for j = 1:N
        tokens = conjuntos{j};
        if isempty(tokens)
            continue; 
        end

        validTokens = tokens(isKey(tokenIdx, tokens));
        if isempty(validTokens)
            continue;
        end

        indices = cellfun(@(t) tokenIdx(t), validTokens);
        hashes = mod(a * indices + b, p) + 1;
        sig(:,j) = min(hashes, [], 2);
    end
end

function p = nextprime(n)
    p = n;
    if p < 2
        p = 2;
        return;
    end

    if mod(p,2)==0
        p = p + 1;
    end

    while ~isprime(p)
        p = p + 2;
    end
end