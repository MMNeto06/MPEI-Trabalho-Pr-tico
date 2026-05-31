function [sig, hashData] = minhash_signature(X_str, nHashOrData)
    [N, M] = size(X_str);
    
    if isnumeric(nHashOrData)
        nHash = nHashOrData;
        universo = unique(X_str);
        U = numel(universo);
        p = nextprime(max(U * 100, 100003));
        a = randi(max(p-1,1), nHash, 1);
        b = randi(p, nHash, 1);
        
        hashData.a = a;
        hashData.b = b;
        hashData.p = p;
        hashData.universo = universo;
    else
        hashData = nHashOrData;
        a = hashData.a;
        b = hashData.b;
        p = hashData.p;
        universo = hashData.universo;
        nHash = length(a);
    end

    [~, token_ids] = ismember(X_str, universo); 
    
    sig = inf(nHash, N);
    
    for k = 1:nHash
        rows_hashes = mod(a(k) * token_ids + b(k), p) + 1;        
        rows_hashes(token_ids == 0) = inf;
        sig(k, :) = min(rows_hashes, [], 2).';
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