% Não vai ser utilzado. Pode ser utilizado apenas para fazer comparações de
% performance (esta forma está nos slides, mas é muito mais ineficiente)
function sig = minhash_signature_perm(conjuntos, nHash)
    N = numel(conjuntos);
    universo = unique([conjuntos{:}]);
    U = numel(universo);

    tokenIdx = containers.Map(universo, 1:U);

    M = zeros(U, N);
    for j = 1:N
        for t = conjuntos{j}
            M(tokenIdx(t{1}), j) = 1;
        end
    end

    sig = inf(nHash, N);

    for h = 1:nHash
        perm = randperm(U);

        M_perm = M(perm, :);

        for j = 1:N
            first = find(M_perm(:, j), 1, 'first');
            if ~isempty(first)
                sig(h, j) = first;
            end
        end
    end
end