function previsoes = ensemble_predict(XTeste, YTrain, sigTrain, bf, ...
                                      mu, sigma, logPrior, classes, hashData, ...
                                      w_nb, w_mh, w_bf, bf_cols, bf_breaks, thresholds)
    nTeste = size(XTeste, 1);
    nClasses = numel(classes);
    previsoes = categorical(strings(nTeste, 1));

    testTokens = cell(nTeste, 1);
    sigTest = zeros(size(sigTrain,1), nTeste);
    for i = 1:nTeste
        testTokens{i} = extract_features(XTeste(i,:), thresholds);
        sigTest(:,i) = minhash_single(testTokens{i}, hashData);
    end

    allSims = zeros(nTeste, size(sigTrain,2));
    for i = 1:nTeste
        matches = sigTrain == sigTest(:,i);
        allSims(i,:) = mean(matches, 1);
    end

    for i = 1:nTeste
        %% 1. Naive Bayes
        [~, log_nb] = nb_predict(XTeste(i,:), mu, sigma, logPrior, classes);
        log_nb = log_nb(:)' - max(log_nb(:));
        p_nb = exp(log_nb) / sum(exp(log_nb));

        %% 2. MinHash (top-20 por classe)
        sims = allSims(i,:);
        p_mh = zeros(1, nClasses);
        for c = 1:nClasses
            idx_c = (YTrain == classes{c});
            topK = maxk(sims(idx_c), min(20, sum(idx_c)));
            p_mh(c) = mean(topK);
        end
        p_mh = p_mh / (sum(p_mh) + 1e-9);

        %% 3. Pesos adaptativos 
        nb_entr = -sum(p_nb .* log(p_nb + 1e-9)) / log(nClasses);
        if nb_entr < 0.3
            w1 = 0.75; w2 = 0.20; w3 = 0.05;
        elseif nb_entr < 0.55
            w1 = 0.55; w2 = 0.40; w3 = 0.05;
        else
            w1 = 0.50; w2 = 0.45; w3 = 0.05;
        end

        %% 4. Bloom Filter — ajuste de pesos por novidade
        key = build_bf_key(XTeste(i,:), bf_cols, bf_breaks);
        if bloom_check(bf, key)
            p_bf = p_nb;
        else
            p_bf = ones(1, nClasses) / nClasses;
            w1 = max(w1 - 0.05, 0.30);
            w2 = min(w2 + 0.05, 0.65);
            w3 = 0.05;
        end
        p_bf = p_bf / sum(p_bf);

        %% 5. Score final
        final_score = w1 * p_nb + w2 * p_mh + w3 * p_bf;
        [~, idx] = max(final_score);
        pred_class = classes{idx};

        %% 5b. Thunder guard de precipitação
        % Fix: o ensemble previa thunder em dias com precipitação mínima (81 % FP).
        % Guard: thunder só é aceite se prcp >= 5 mm OU prcp_hours >= 2 h.
        % Caso contrário, downgrades para rain (o segundo melhor candidado real).
        % O limiar é conservador e generaliza bem — thunder genuíno tem sempre
        % precipitação significativa, enquanto os FP vinham de dias de chuva
        % leve onde o MinHash encontrava vizinhos de thunder por acaso.
        if strcmp(pred_class, 'thunder')
            prcp_i_th  = XTeste(i, 1);   % col 1: precipitation (log1p transformado)
            phr_i_th   = XTeste(i, 21);  % col 21: precip_hours (log1p transformado)
            % Converter de volta de log1p para comparar com limiares físicos
            % log1p(5) ≈ 1.792;  log1p(2) ≈ 1.099
            if prcp_i_th < log1p(5) && phr_i_th < log1p(2)
                % Downgrade para a classe com maior score excluindo thunder
                thunder_idx = strcmp(classes, 'thunder');
                fs_no_thunder = final_score;
                fs_no_thunder(thunder_idx) = -inf;
                [~, idx2] = max(fs_no_thunder);
                pred_class = classes{idx2};
            end
        end

        %% 6. Desempate drizzle/rain COM DEPRESSÃO DO PONTO DE ORVALHO
        score_drizzle = final_score(strcmp(classes, 'drizzle'));
        score_rain = final_score(strcmp(classes, 'rain'));
        diff_dr = abs(score_drizzle - score_rain);
        
        if diff_dr < 0.12 && (strcmp(pred_class,'drizzle') || strcmp(pred_class,'rain'))
            precip_i = XTeste(i, 1);
            temp_i   = XTeste(i, 2);
            hum_i    = XTeste(i, 12);
            dew_i    = XTeste(i, 14);
            cloud_i  = XTeste(i, 16);   
            phr_i    = XTeste(i, 21);   % FIX Bug 2: era col 22 (temp_mean) → col 21 (precip_hours)
            
            % Calcula depressão do orvalho localmente para o desempate
            dep_i = temp_i - dew_i;
        
            % Para rain: maior depressão ganha mais pontos (ar menos saturado)
            rain_score = (precip_i / thresholds.precip_low) * 2 + ...
                         (phr_i / thresholds.phr_short) * 2 + ...
                         (cloud_i / thresholds.cloud_overcast) + ...
                         (hum_i / thresholds.hum_rain) + ...
                         (dep_i / 5); 
        
            % Para drizzle: menor depressão ganha mais pontos (ar saturado)
            driz_score = ((thresholds.precip_low - precip_i) / thresholds.precip_low)  * 2 + ...
                         ((thresholds.phr_short - phr_i) / thresholds.phr_short)   * 2 + ...
                         ((thresholds.cloud_overcast - cloud_i) / thresholds.cloud_overcast)  + ...
                         ((thresholds.hum_rain - hum_i) / thresholds.hum_rain) + ...
                         (max(0, 5 - dep_i) / 5);
        
            if rain_score > driz_score * 1.15
                pred_class = 'rain';
            elseif driz_score > rain_score * 1.15
                pred_class = 'drizzle';
            end
        end

        %% 7. Desempate sun/cloudy COM SUNSHINE + CLOUD + PRESSÃO
        score_sun    = final_score(strcmp(classes, 'sun'));
        score_cloudy = final_score(strcmp(classes, 'cloudy'));
        diff_sc = abs(score_sun - score_cloudy);

        if diff_sc < 0.12 && (strcmp(pred_class,'sun') || strcmp(pred_class,'cloudy'))
            sunshine_i  = XTeste(i, 4);
            shortwave_i = XTeste(i, 5);   % NOVO: shortwave_radiation (col 5)
            cloud_i_sc  = XTeste(i, 16);
            hum_i_sc    = XTeste(i, 12);
            press_i_sc  = XTeste(i, 19);  % FIX Bug 2: era col 20 (pressure_min) → col 19 (pressure_mean)

            % sun:    alta insolação, alta shortwave, baixa nebulosidade, pressão alta
            sun_score_sc = (sunshine_i   / (thresholds.sun_mid   + 1e-9)) * 3 + ...
                           (shortwave_i  / (thresholds.sw_high   + 1e-9)) * 2 + ...  % NOVO peso×2
                           ((thresholds.cloud_partial - cloud_i_sc) ...
                             / (thresholds.cloud_partial + 1e-9))          * 2 + ...
                           (press_i_sc   / (thresholds.press_high + 1e-9)) * 1 + ...
                           ((thresholds.hum_mid - hum_i_sc) ...
                             / (thresholds.hum_mid + 1e-9))                * 1;

            % cloudy: baixa insolação, baixa shortwave, alta nebulosidade
            cloudy_score_sc = ((thresholds.sun_mid - sunshine_i) ...
                                / (thresholds.sun_mid + 1e-9))             * 3 + ...
                              ((thresholds.sw_high - shortwave_i) ...
                                / (thresholds.sw_high + 1e-9))             * 2 + ...  % NOVO peso×2
                              (cloud_i_sc / (thresholds.cloud_partial + 1e-9)) * 2 + ...
                              ((thresholds.press_high - press_i_sc) ...
                                / (thresholds.press_high + 1e-9))          * 1 + ...
                              (hum_i_sc / (thresholds.hum_mid + 1e-9))     * 1;

            if sun_score_sc > cloudy_score_sc * 1.15
                pred_class = 'sun';
            elseif cloudy_score_sc > sun_score_sc * 1.15
                pred_class = 'cloudy';
            end
        end

        previsoes(i) = categorical({pred_class});
    end
end