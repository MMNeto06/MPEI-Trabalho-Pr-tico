function previsoes = ensemble_predict(XTeste, YTrain, sigTrain, bf, ...
                                      mu, sigma, logPrior, classes, hashData, ...
                                      bf_cols, bf_breaks, thresholds)
    nTeste   = size(XTeste, 1);
    nClasses = numel(classes);
    classes_str = string(classes); 

    %% 1. Naive Bayes
    [~, p_nb_all] = nb_predict(XTeste, mu, sigma, logPrior, classes); 

    %% 2. MinHash
    testTokens_matrix = extract_features(XTeste, thresholds);
    sigTest = minhash_signature(testTokens_matrix, hashData);

    %% 3. Matriz de Similaridades 
    nHash = size(sigTest, 1);
    nTrain = size(sigTrain, 2);
    allSims = zeros(nTeste, nTrain);
    
    sigTest_int  = int32(sigTest);
    sigTrain_int = int32(sigTrain);
    
    for k = 1:nHash
        allSims = allSims + (sigTest_int(k, :).' == sigTrain_int(k, :));
    end
    allSims = allSims / nHash;

    %% 4. Pré-computação de índices das classes no Treino
    classIdx = cell(nClasses, 1);
    classCounts = zeros(nClasses, 1);
    for c = 1:nClasses
        classIdx{c}   = find(YTrain == classes{c});
        classCounts(c) = numel(classIdx{c});
    end

    %% 5. MinHash — Cálculo do Top-20 por Classe 
    p_mh = zeros(nTeste, nClasses);
    for c = 1:nClasses
        k_eff = min(20, classCounts(c));
        topK = maxk(allSims(:, classIdx{c}), k_eff, 2);
        p_mh(:, c) = mean(topK, 2);
    end
    p_mh = p_mh ./ (sum(p_mh, 2) + 1e-9);

    %% 6. Bloom Filter — Verificação de Novidade
    keysTeste = build_bf_key(XTeste, bf_cols, bf_breaks);
    bf_known = false(nTeste, 1);
    for i = 1:nTeste
        bf_known(i) = bloom_check(bf, keysTeste(i));
    end

    %% 7. Pesos Adaptativos por Entropia de Shannon
    nb_entr = -sum(p_nb_all .* log(p_nb_all + 1e-9), 2) / log(nClasses);
    
    w1 = zeros(nTeste, 1);
    w2 = zeros(nTeste, 1);
    w3 = repmat(0.05, nTeste, 1);
    
    idx_low  = nb_entr < 0.3;
    idx_mid  = nb_entr >= 0.3 & nb_entr < 0.55;
    idx_high = nb_entr >= 0.55;
    
    w1(idx_low)  = 0.75; w2(idx_low)  = 0.20;
    w1(idx_mid)  = 0.55; w2(idx_mid)  = 0.40;
    w1(idx_high) = 0.50; w2(idx_high) = 0.45;

    %% 8. Ajuste de Pesos pelo Bloom Filter 
    p_bf = repmat(ones(1, nClasses) / nClasses, nTeste, 1);
    p_bf(bf_known, :) = p_nb_all(bf_known, :);
    
    not_known = ~bf_known;
    w1(not_known) = max(w1(not_known) - 0.05, 0.30);
    w2(not_known) = min(w2(not_known) + 0.05, 0.65);

    %% 9. Score Final e Decisão
    final_score = (w1 .* p_nb_all) + (w2 .* p_mh) + (w3 .* p_bf);
    [~, best] = max(final_score, [], 2);
    pred_classes = classes_str(best);

    %% 10. Tiebreak drizzle/rain 
    idx_drizzle = find(strcmp(classes, 'drizzle'));
    idx_rain    = find(strcmp(classes, 'rain'));
    
    if ~isempty(idx_drizzle) && ~isempty(idx_rain)
        diff_dr = abs(final_score(:, idx_drizzle) - final_score(:, idx_rain));
        is_drizzle_or_rain = (best == idx_drizzle) | (best == idx_rain);
        
        tiebreak_mask = (diff_dr < 0.12) & is_drizzle_or_rain;
        
        if any(tiebreak_mask)
            col_precip = XTeste(:, 1);
            col_phr    = XTeste(:, 17);
            col_cloud  = XTeste(:, 14);
            col_hum    = XTeste(:, 12);
            
            rain_score = (col_precip / thresholds.precip_low) * 2 + ...
                         (col_phr / thresholds.phr_short) * 2 + ...
                         (col_cloud / thresholds.cloud_overcast) + ...
                         (col_hum / thresholds.hum_rain);
                         
            driz_score = ((thresholds.precip_low - col_precip) / thresholds.precip_low) * 2 + ...
                         ((thresholds.phr_short - col_phr) / thresholds.phr_short) * 2 + ...
                         ((thresholds.cloud_overcast - col_cloud) / thresholds.cloud_overcast) + ...
                         ((thresholds.hum_rain - col_hum) / thresholds.hum_rain);
                         
            fix_rain    = tiebreak_mask & (rain_score > driz_score * 1.15);
            fix_drizzle = tiebreak_mask & (driz_score > rain_score * 1.15);
            
            pred_classes(fix_rain)    = "rain";
            pred_classes(fix_drizzle) = "drizzle";
        end
    end

    previsoes = categorical(pred_classes);
end