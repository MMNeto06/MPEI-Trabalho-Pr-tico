function tokens = extract_features(row, thr)
    precip       = row(1);
    temp_max     = row(2);  % <- NOVA VARIÁVEL ATIVADA
    sunshine     = row(4);
    wind_gusts   = row(7);
    humidity     = row(12);
    dew_mean     = row(14); 
    cloud        = row(16); 
    press_mean   = row(17); 
    press_min    = row(18); 
    precip_hours = row(19); 
    press_drop   = press_mean - press_min;

    % Temperatura (Tokens Novos)
    if     temp_max < thr.temp_cold,        t_tok = 'temp_cold';
    elseif temp_max < thr.temp_hot,         t_tok = 'temp_mild';
    else,                                   t_tok = 'temp_hot';
    end

    % Precipitação
    if     precip == 0,                     p_tok = 'precip_none';
    elseif precip < thr.precip_trace,       p_tok = 'precip_trace';
    elseif precip < thr.precip_low,         p_tok = 'precip_drizzle';
    elseif precip < thr.precip_med,         p_tok = 'precip_low';
    else,                                   p_tok = 'precip_heavy';
    end

    % Horas de precipitação
    if     precip_hours == 0,               ph_tok = 'phr_none';
    elseif precip_hours < thr.phr_brief,    ph_tok = 'phr_brief';
    elseif precip_hours < thr.phr_short,    ph_tok = 'phr_short';
    elseif precip_hours < thr.phr_moderate, ph_tok = 'phr_moderate';
    else,                                   ph_tok = 'phr_persistent';
    end

    % Cobertura de nuvens
    if     cloud < thr.cloud_clear,         c_tok = 'cloud_clear';
    elseif cloud < thr.cloud_partial,       c_tok = 'cloud_partial';
    elseif cloud < thr.cloud_overcast,      c_tok = 'cloud_overcast';
    else,                                   c_tok = 'cloud_heavy';
    end

    % Humidade
    if     humidity < thr.hum_low,          h_tok = 'hum_low';
    elseif humidity < thr.hum_mid,          h_tok = 'hum_mid';
    elseif humidity < thr.hum_drizzle,      h_tok = 'hum_drizzle';
    else,                                   h_tok = 'hum_rain';
    end

    % Sunshine
    if     sunshine < thr.sun_none,         s_tok = 'sun_none';
    elseif sunshine < thr.sun_low,          s_tok = 'sun_low';
    elseif sunshine < thr.sun_mid,          s_tok = 'sun_mid';
    else,                                   s_tok = 'sun_high';
    end

    % Vento
    if     wind_gusts < thr.wind_calm,      w_tok = 'calm';
    elseif wind_gusts < thr.wind_windy,     w_tok = 'windy';
    else,                                   w_tok = 'storm_likely';
    end

    % Pressão
    if     press_mean > thr.press_high && press_drop < 3,   pr_tok = 'press_high';
    elseif press_min  < thr.press_drop || press_drop > 8,   pr_tok = 'press_storm';
    else,                                                   pr_tok = 'press_normal';
    end
    
    % Token Ponto de Orvalho
    if     dew_mean < thr.dew_low,   d_tok = 'dew_low';
    elseif dew_mean < thr.dew_high,  d_tok = 'dew_mid';
    else,                            d_tok = 'dew_high';
    end

    % Combo — limiares dinâmicos + casos de fog
    if     precip == 0 && cloud < thr.cloud_clear && humidity < thr.hum_mid
                                                            combo = 'clear_sun';
    elseif precip == 0 && humidity > thr.hum_drizzle && cloud > thr.cloud_partial
                                                            combo = 'dry_humid';     
    elseif precip < thr.precip_trace && precip_hours < thr.phr_short
                                                            combo = 'light_drizzle';
    elseif precip > thr.precip_low && precip_hours > thr.phr_moderate && cloud > thr.cloud_overcast
                                                            combo = 'sustained_rain';
    elseif precip > thr.precip_low && humidity > thr.hum_rain
                                                            combo = 'heavy_humid';
    elseif precip == 0 && wind_gusts > thr.wind_windy
                                                            combo = 'dry_windy';      
    else,                                                   combo = 'ambiguous';
    end

    t1  = strcat(p_tok,  '_', ph_tok);
    t2  = strcat(p_tok,  '_', h_tok);
    t3  = strcat(p_tok,  '_', c_tok);
    t4  = strcat(ph_tok, '_', h_tok);
    t5  = strcat(ph_tok, '_', c_tok);
    t6  = strcat(h_tok,  '_', c_tok);
    t7  = strcat(combo,  '_', p_tok);
    t8  = strcat(combo,  '_', ph_tok);
    t9  = strcat(s_tok,  '_', c_tok);
    t10 = strcat(w_tok,  '_', pr_tok);
    t11 = strcat(p_tok,  '_', w_tok);    
    t12 = strcat(h_tok,  '_', pr_tok);   
    t13 = strcat(s_tok,  '_', h_tok);
    t14 = strcat(d_tok,  '_', h_tok); 
    t15 = strcat(d_tok,  '_', c_tok); 
    
    % Combinações c/ Temperatura
    t16 = strcat(t_tok,  '_', h_tok);
    t17 = strcat(t_tok,  '_', p_tok);

    tokens = {t_tok, p_tok, h_tok, c_tok, ph_tok, s_tok, combo, w_tok, pr_tok, d_tok, ...
              t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17};
end