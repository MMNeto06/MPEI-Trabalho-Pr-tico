function thr = compute_thresholds(XTrain, YTrain)
    pall = @(col, pct) prctile(XTrain(:, col), pct);
    pcls = @(cls, col, pct) prctile(XTrain(YTrain == cls, col), pct);

    mu_d = mean(XTrain(YTrain=='drizzle', 1));
    mu_r = mean(XTrain(YTrain=='rain', 1));
    thr.precip_trace = pcls('drizzle', 1, 30);
    thr.precip_low = (mu_d + mu_r) / 2;        
    thr.precip_med = pcls('rain', 1, 75);

    mu_ph_d = mean(XTrain(YTrain=='drizzle', 19));
    mu_ph_r = mean(XTrain(YTrain=='rain', 19));
    thr.phr_brief = pcls('drizzle', 19, 30);
    thr.phr_short = (mu_ph_d + mu_ph_r) / 2;  
    thr.phr_moderate = pcls('rain', 19, 70);

    mu_c_d = mean(XTrain(YTrain=='drizzle', 16));
    mu_c_r = mean(XTrain(YTrain=='rain', 16));
    thr.cloud_clear = pall(16, 20);
    thr.cloud_partial = pall(16, 45);
    thr.cloud_overcast = (mu_c_d + mu_c_r) / 2;

    mu_h_d = mean(XTrain(YTrain=='drizzle', 12));
    mu_h_r = mean(XTrain(YTrain=='rain', 12));
    thr.hum_low = pall(12, 20);
    thr.hum_mid = pall(12, 45);
    thr.hum_drizzle = mu_h_d;                     
    thr.hum_rain = (mu_h_d + mu_h_r) / 2;   

    % Temperatura
    thr.temp_cold = pall(2, 33);
    thr.temp_hot = pall(2, 66);

    % fog tem sunshine muito baixa — limiar sun_none crítico para fog vs sun
    thr.sun_none = max(pcls('fog', 4, 75), pall(4, 15)); 
    thr.sun_low = pall(4, 40);
    thr.sun_mid = pall(4, 75);

    % thunder tem vento mais alto — limiar storm calibrado para isso
    has_thunder = any(YTrain == 'thunder');
    if has_thunder && sum(YTrain=='thunder') > 5
        thr.wind_calm = pall(7, 35);
        thr.wind_windy = mean([mean(XTrain(YTrain=='rain',    7)), ...
                               mean(XTrain(YTrain=='thunder', 7))]);
    else
        thr.wind_calm = pall(7, 35);
        thr.wind_windy = pall(7, 75);
    end

    % press_high: limiar para dias de sol (alta pressão = bom tempo)
    has_sun = any(YTrain == 'sun');
    if has_sun
        thr.press_high = pcls('sun', 17, 40);     
    else
        thr.press_high = pall(17, 60);
    end
    thr.press_drop = pall(18, 20);             

    % Limiar Dew point baseado nas classes (nevoeiro tem dew point alto)
    has_fog = any(YTrain == 'fog');
    if has_fog
        thr.dew_high = pcls('fog', 14, 60);
    else
        thr.dew_high = pall(14, 70);
    end
    thr.dew_low = pall(14, 30);

    thr.precip_trace = min(thr.precip_trace, thr.precip_low - 0.1);
    thr.precip_low = min(thr.precip_low, thr.precip_med - 0.1);
    thr.phr_brief = min(thr.phr_brief, thr.phr_short - 0.1);
    thr.phr_short = min(thr.phr_short, thr.phr_moderate - 0.1);
    thr.cloud_clear = min(thr.cloud_clear,  thr.cloud_partial - 0.1);
    thr.cloud_partial = min(thr.cloud_partial,thr.cloud_overcast - 0.1);
    thr.hum_low = min(thr.hum_low, thr.hum_mid - 0.1);
    thr.hum_mid = min(thr.hum_mid, thr.hum_drizzle - 0.1);
    thr.hum_drizzle = min(thr.hum_drizzle, thr.hum_rain - 0.1);
    thr.wind_calm = min(thr.wind_calm, thr.wind_windy - 0.1);
    thr.dew_low = min(thr.dew_low, thr.dew_high - 0.1);
end