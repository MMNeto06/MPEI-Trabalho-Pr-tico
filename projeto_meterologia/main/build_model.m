function model = build_model(dados)
    fprintf('=== BUILD MODEL: início ===\n');
    
    
    variaveis = dados.Properties.VariableNames;
    
    colunasBase = {'precipitation', 'temp_max', 'temp_min', 'wind', ...
                   'snow_depth', 'temp_range', 'month_sin', 'month_cos'};
    
    nomeFeatures = colunasBase;
    
    if ismember('tsun', variaveis)
        nomeFeatures{end+1} = 'tsun';
    end
    if ismember('wsf2', variaveis)
        nomeFeatures{end+1} = 'wsf2';
    end
    
    X = table2array(dados(:, nomeFeatures));
    Y = categorical(dados.weather);
    
    N = size(X,1);
    
    fprintf('Dataset: %d amostras | %d features\n', N, size(X,2));
    
    fprintf('A discretizar dados...\n');
    
    tokensTrain = cell(N,1);
    
    for i = 1:N
        tokensTrain{i} = discretizar_dia(X(i,:));
        tokensTrain{i} = unique(tokensTrain{i}); % importante para MinHash
    end
    
    fprintf('A criar Bloom Filter...\n');
    
    fpr_alvo = 0.01;
    
    m_bf = ceil(-(N * log(fpr_alvo)) / (log(2)^2));
    k_bf = max(1, round((m_bf / N) * log(2)));
    
    bf = bloom_init(m_bf, k_bf);
    
    for i = 1:N
        key = strjoin(tokensTrain{i}, '_');
        bf = bloom_insert(bf, key);
    end
    
    fprintf('Bloom Filter: m=%d | k=%d | FPR=%.4f%%\n', ...
        m_bf, k_bf, bloom_fp_rate(bf)*100);
        
    fprintf('A gerar MinHash signatures...\n');
    
    nHash = 60;
    universo = unique([tokensTrain{:}]);
    U = numel(universo);
    
    p = nextprime(U + 1000);
    a = randi(p-1, nHash, 1);
    b = randi(p, nHash, 1);
    
    hash.a = a;
    hash.b = b;
    hash.p = p;
    
    tokenIdx = containers.Map(universo, 1:U);
    
    sigTrain = inf(nHash, N);
    
    for j = 1:N
        tokens = tokensTrain{j};
    
        indices = [];
        for t = tokens
            if isKey(tokenIdx, t{1})
                indices(end+1) = tokenIdx(t{1});
            end
        end
    
        if isempty(indices)
            continue;
        end
    
        hashes = mod(a * indices + b, p);
        sigTrain(:, j) = min(hashes, [], 2);
    end
    
    %% ================================
    % 5) NAIVE BAYES GLOBAL
    %% ================================
    
    fprintf('A treinar Naive Bayes...\n');
    
    [mu, sigma, logPrior, classes] = nb_train(X, Y);
    
    %% ================================
    % 6) MODELO FINAL
    %% ================================
    
    model.XTrain = X;
    model.YTrain = Y;
    
    model.tokensTrain = tokensTrain;
    
    model.bf = bf;
    
    model.sigTrain = sigTrain;
    
    model.hash = hash;
    model.tokenIdx = tokenIdx;
    
    model.nb.mu = mu;
    model.nb.sigma = sigma;
    model.nb.logPrior = logPrior;
    model.nb.classes = classes;
    
    model.nomeFeatures = nomeFeatures;
    
    fprintf('=== BUILD MODEL: concluído ===\n');

end