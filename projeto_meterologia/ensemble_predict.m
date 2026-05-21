function previsoes = ensemble_predict(XTeste, YTrain, sigTrain, bf, ...
                                      mu, sigma, logPrior, classes, hashData, ...
                                      w_nb, w_mh, w_bf)

    nTeste   = size(XTeste, 1);
    nClasses = numel(classes);
    previsoes = categorical(strings(nTeste, 1));
    
    for i = 1:nTeste
    
        %% 1. Tokens + MinHash
        tokens   = extract_features(XTeste(i,:));
        sigQuery = minhash_single(tokens, hashData);
    
        %% 2. Naive Bayes → softmax para escala [0,1]
        [~, log_nb] = nb_predict(XTeste(i,:), mu, sigma, logPrior, classes);
        log_nb = log_nb(:)' - max(log_nb(:));
        p_nb   = exp(log_nb) / sum(exp(log_nb));
    
        %% 3. MinHash → normalizar para soma 1
        p_mh = minhash_score(sigTrain, YTrain, sigQuery, classes, 20);
        p_mh = p_mh(:)' / (sum(p_mh) + 1e-9);
    
        %% 4. Bloom Filter → uniforme com boost na classe favorita do NB
        key  = lower(strjoin(sort(string(tokens)), '|'));
        p_bf = ones(1, nClasses) / nClasses;
        if bloom_check(bf, key)
            [~, nb_best]   = max(p_nb);
            p_bf(nb_best)  = p_bf(nb_best) + 0.5;
        end
        p_bf = p_bf / sum(p_bf);
    
        %% 5. Pesos adaptativos por entropia do NB
        nb_entr = -sum(p_nb .* log(p_nb + 1e-9)) / log(nClasses);
        if nb_entr < 0.3
            w1 = 0.75; w2 = 0.20; w3 = 0.05;   % NB confiante → confiar nele
        elseif nb_entr < 0.55
            w1 = 0.55; w2 = 0.40; w3 = 0.05;   % zona intermédia
        else
            w1 = 0.50; w2 = 0.45; w3 = 0.05;   % ambos hesitam → heurística resolve
        end
    
        %% 6. Score final e decisão
        final_score  = w1 * p_nb + w2 * p_mh + w3 * p_bf;
        [~, idx]     = max(final_score);
        pred_class = classes{idx};

        % Ler features brutas desta amostra
        precip_i  = XTeste(i, 1);
        phr_i     = XTeste(i, 17);
        cloud_i   = XTeste(i, 14);
        hum_i     = XTeste(i, 12);
        
        % Se o ensemble hesita entre drizzle e rain (scores próximos)
        score_drizzle = final_score(strcmp(classes, 'drizzle'));
        score_rain    = final_score(strcmp(classes, 'rain'));
        diff_dr       = abs(score_drizzle - score_rain);
        
        if diff_dr < 0.12 && (strcmp(pred_class,'drizzle') || strcmp(pred_class,'rain'))
            % Score contínuo em vez de binário — mais sensível
            rain_score = (precip_i/8)*2 + (phr_i/12)*2 + (cloud_i/100) + (hum_i/100);
            driz_score = ((8-precip_i)/8)*2 + ((12-phr_i)/12)*2 + ((100-cloud_i)/100) + ((100-hum_i)/100);
        
            if rain_score > driz_score * 1.15   % margem de 15% para evitar flips espúrios
                pred_class = 'rain';
            elseif driz_score > rain_score * 1.15
                pred_class = 'drizzle';
            end
        end
        
        previsoes(i) = categorical({pred_class});
    end
end