function previsoes = ensemble_predict(XTeste, YTrain, sigTrain, bf, ...
                                      mu, sigma, logPrior, classes, hashData, ...
                                      w_nb, w_mh, w_bf)
    
    nTeste = size(XTeste,1);
    nClasses = numel(classes);
    
    previsoes = categorical(strings(nTeste,1));
    
    for i = 1:nTeste
    
        %% 1. FEATURES → tokens → MinHash signature
        tokens = extract_features(XTeste(i,:));
        sigQuery = minhash_single(tokens, hashData);
    
        %% 2. NAIVE BAYES
        [~, p_nb] = nb_predict(XTeste(i,:), mu, sigma, logPrior, classes);
        % Garantir que p_nb é um vetor linha
        p_nb = p_nb(:)';
    
        %% 3. MINHASH (por classe)
        p_mh = minhash_score(sigTrain, YTrain, sigQuery, classes, 5);
        p_mh = p_mh(:)';
    
        %% 4. BLOOM FILTER (Ajustado)
        % IMPORTANTE: Tem de usar o mesmo separador '|' do treino
        key = lower(strjoin(sort(string(tokens)), '|'));
        
        p_nb = p_nb / (sum(p_nb) + 1e-9);
        p_mh = p_mh / (sum(p_mh) + 1e-9);
        p_bf = ones(1, nClasses) / nClasses;
        if bloom_check(bf, key)
            % boost leve na classe que o NB já favorece
            [~, nb_best] = max(p_nb);
            p_bf(nb_best) = p_bf(nb_best) + 0.5;
        end
        p_bf = p_bf / sum(p_bf);
    
    
        %% 5. ENSEMBLE FINAL
        nb_entr = -sum(p_nb .* log(p_nb + 1e-9)) / log(nClasses);
        
        if nb_entr < 0.3        % confiante
            w1 = 0.70; w2 = 0.25; w3 = 0.05;
        elseif nb_entr < 0.6    % moderado
            w1 = 0.55; w2 = 0.40; w3 = 0.05;
        else                    % inseguro
            w1 = 0.35; w2 = 0.60; w3 = 0.05;
        end
        
        final_score = w1 * p_nb + w2 * p_mh + w3 * p_bf;
        %% 7. DECISÃO
        [~, idx] = max(final_score);
        previsoes(i) = classes{idx};
    
    end
end