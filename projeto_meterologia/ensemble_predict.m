function previsoes = ensemble_predict(XTeste, YTrain, sigTrain, bf, ...
                                      mu, sigma, logPrior, classes, hashData, ...
                                      w_nb, w_mh, w_bf, bf_cols, bf_breaks, thresholds)
    nTeste   = size(XTeste, 1);
    nClasses = numel(classes);
    previsoes = categorical(strings(nTeste, 1));

    % Pré-calcular tokens e assinaturas de teste
    testTokens = cell(nTeste, 1);
    sigTest    = zeros(size(sigTrain,1), nTeste);
    for i = 1:nTeste
        testTokens{i} = extract_features(XTeste(i,:), thresholds);
        sigTest(:,i)  = minhash_single(testTokens{i}, hashData);
    end

    % Similaridades vectorizadas: (nTeste × nTrain)
    allSims = zeros(nTeste, size(sigTrain,2));
    for i = 1:nTeste
        matches      = sigTrain == sigTest(:,i);
        allSims(i,:) = mean(matches, 1);
    end

    for i = 1:nTeste
        %% 1. Naive Bayes → softmax
        [~, log_nb] = nb_predict(XTeste(i,:), mu, sigma, logPrior, classes);
        log_nb = log_nb(:)' - max(log_nb(:));
        p_nb   = exp(log_nb) / sum(exp(log_nb));

        %% 2. MinHash → top-20 por classe
        sims = allSims(i,:);
        p_mh = zeros(1, nClasses);
        for c = 1:nClasses
            idx_c    = (YTrain == classes{c});
            topK     = maxk(sims(idx_c), min(20, sum(idx_c)));
            p_mh(c)  = mean(topK);
        end
        p_mh = p_mh / (sum(p_mh) + 1e-9);

        %% 3. Pesos adaptativos por entropia do NB
        nb_entr = -sum(p_nb .* log(p_nb + 1e-9)) / log(nClasses);
        if nb_entr < 0.3
            w1 = 0.75; w2 = 0.20; w3 = 0.05;
        elseif nb_entr < 0.55
            w1 = 0.55; w2 = 0.40; w3 = 0.05;
        else
            w1 = 0.50; w2 = 0.45; w3 = 0.05;
        end

        %% 4. Bloom Filter — ajuste de pesos por novidade
        key  = build_bf_key(XTeste(i,:), bf_cols, bf_breaks);
        if bloom_check(bf, key)
            % Amostra familiar → p_bf reforça o NB
            p_bf = p_nb;
        else
            % Amostra nova → conservador, redistribuir pesos
            p_bf = ones(1, nClasses) / nClasses;
            w1   = max(w1 - 0.05, 0.30);
            w2   = min(w2 + 0.05, 0.65);
            w3   = 0.05;
        end
        p_bf = p_bf / sum(p_bf);

        %% 5. Score final
        final_score = w1 * p_nb + w2 * p_mh + w3 * p_bf;
        [~, idx]    = max(final_score);
        pred_class  = classes{idx};

        %% 6. Desempate drizzle/rain com mini-NB dedicado
        score_drizzle = final_score(strcmp(classes, 'drizzle'));
        score_rain    = final_score(strcmp(classes, 'rain'));
        diff_dr       = abs(score_drizzle - score_rain);

        if diff_dr < 0.12 && (strcmp(pred_class,'drizzle') || strcmp(pred_class,'rain'))
            precip_i = XTeste(i, 1);
            phr_i    = XTeste(i, 17);
            cloud_i  = XTeste(i, 14);
            hum_i    = XTeste(i, 12);

            rain_score = (precip_i/8)*2 + (phr_i/12)*2 + (cloud_i/100) + (hum_i/100);
            driz_score = ((8-precip_i)/8)*2 + ((12-phr_i)/12)*2 + ((100-cloud_i)/100) + ((100-hum_i)/100);

            if     rain_score > driz_score * 1.15
                pred_class = 'rain';
            elseif driz_score > rain_score * 1.15
                pred_class = 'drizzle';
            end
        end

        previsoes(i) = categorical({pred_class});

    end
end