function thr = compute_thresholds(XTrain, YTrain)
    pall = @(col, pct) prctile(XTrain(:, col), pct);
    pcls = @(cls, col, pct) prctile(XTrain(YTrain == cls, col), pct);

    mu_d = mean(XTrain(YTrain=='drizzle', 1));
    mu_r = mean(XTrain(YTrain=='rain', 1));
    thr.precip_trace = pcls('drizzle', 1, 30);
    thr.precip_low = (mu_d + mu_r) / 2;        
    thr.precip_med = pcls('rain', 1, 75);

    mu_ph_d = mean(XTrain(YTrain=='drizzle', 21));  % FIX Bug 2: era col 22 (temp_mean) → col 21 (precip_hours)
    mu_ph_r = mean(XTrain(YTrain=='rain',    21));
    thr.phr_brief    = pcls('drizzle', 21, 30);
    thr.phr_short = (mu_ph_d + mu_ph_r) / 2;  
    thr.phr_moderate = pcls('rain', 21, 70);

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

    % Shortwave Radiation (col 5) — 2.º melhor discriminador sun/cloudy
    % sun p25≈18.2 MJ/m², cloudy p75≈23.2 MJ/m²
    has_sun = any(YTrain == 'sun');
    thr.sw_low  = pall(5, 30);
    thr.sw_high = pall(5, 65);
    if has_sun && sum(YTrain=='sun') > 5
        thr.sw_sun = pcls('sun', 5, 25);   % limiar conservador para dias de sol
    else
        thr.sw_sun = pall(5, 40);
    end
    thr.sw_low  = min(thr.sw_low,  thr.sw_high - 0.1);
    thr.sw_sun  = min(thr.sw_sun,  thr.sw_high - 0.1);

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
    if has_sun
        thr.press_high = pcls('sun', 19, 40);      % FIX Bug 2: era col 20 (pressure_min) → col 19 (pressure_mean)
    else
        thr.press_high = pall(19, 60);
    end
    thr.press_drop = pall(20, 20);                 % FIX Bug 2: era col 21 (precip_hours) → col 20 (pressure_min)

    % Limiar Dew point baseado nas classes (nevoeiro tem dew point alto)
    has_fog = any(YTrain == 'fog');
    if has_fog
        thr.dew_high = pcls('fog', 14, 60);
    else
        thr.dew_high = pall(14, 70);
    end
    thr.dew_low = pall(14, 30);

    % Limiares Dew Depression (col 25: temp_mean − dew_point_mean) — NOVO
    % Fog tem depressão muito baixa (<2 °C); sun/dust tem depressão alta (>10 °C)
    % Usamos percentis por classe para calibrar os 3 cortes.
    has_sun_dd = any(YTrain == 'sun');
    has_fog_dd = any(YTrain == 'fog');
    if has_fog_dd && sum(YTrain == 'fog') > 5
        thr.dewdep_fog   = pcls('fog',    25, 70);   % p70 fog → tecto da zona "fog"
    else
        thr.dewdep_fog   = pall(25, 15);
    end
    if any(YTrain == 'cloudy') && sum(YTrain == 'cloudy') > 5
        thr.dewdep_cloud = pcls('cloudy', 25, 60);   % p60 cloudy → divide cloudy/mid
    else
        thr.dewdep_cloud = pall(25, 40);
    end
    if has_sun_dd && sum(YTrain == 'sun') > 5
        thr.dewdep_sun   = pcls('sun',    25, 35);   % p35 sun → limiar entrada zona "sun"
    else
        thr.dewdep_sun   = pall(25, 65);
    end
    % Garantir ordenação estrita
    thr.dewdep_fog   = min(thr.dewdep_fog,   thr.dewdep_cloud - 0.1);
    thr.dewdep_cloud = min(thr.dewdep_cloud, thr.dewdep_sun   - 0.1);

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

    has_cloudy = any(YTrain == 'cloudy');
    if has_cloudy
        thr.cloud_cloudy = pcls('cloudy', 16, 40);
        thr.sun_cloudy   = mean([pcls('sun',16,60), pcls('cloudy',16,40)]);
    else
        thr.cloud_cloudy = pall(16, 55);
        thr.sun_cloudy   = pall(16, 50);
    end
    thr.cloud_clear   = min(thr.cloud_clear,   thr.cloud_cloudy  - 0.1);
    thr.cloud_cloudy  = min(thr.cloud_cloudy,  thr.cloud_partial - 0.1);
end