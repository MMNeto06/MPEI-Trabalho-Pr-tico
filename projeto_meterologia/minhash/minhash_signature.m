function sig = minhash_signature(conjuntos, nHash)
    N           = numel(conjuntos);
    universo    = unique([conjuntos{:}]);    % todos os tokens únicos
    U           = numel(universo);           % tamanho do universo

    % Gerar parâmetros aleatórios para nHash funções hash universais
    % h_i(x) = (a_i * x + b_i) mod p  — família universal de hashes
    p = 2147483647;   % primo de Mersenne: 2^31 - 1
    a  = randi(p-1, nHash, 1);              % a ∈ [1, p-1]
    b  = randi(p,   nHash, 1);              % b ∈ [1, p]

    % Mapear cada token do universo para um índice numérico
    tokenIdx = containers.Map(universo, 1:U);

    % Inicializar assinaturas com +inf
    sig = inf(nHash, N);

    % Para cada dia, calcular o mínimo hash para cada função
    for j = 1:N
        tokens = conjuntos{j};
        if isempty(tokens), continue; end

        % Índices numéricos dos tokens deste dia
        indices = cellfun(@(t) tokenIdx(t), tokens);

        % Para cada função hash, calcular h(x) para todos os tokens e guardar o mínimo
        % h_i(x) = mod(a_i * x + b_i, p)   [operação vectorizada]
        hashes = mod(a * indices + b, p);   % (nHash × |tokens|)
        sig(:, j) = min(hashes, [], 2);     % mínimo por linha
    end
end
