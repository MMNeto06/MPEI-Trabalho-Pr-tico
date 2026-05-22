function tokens = extract_features(row, thr)
    precip       = row(1);
    sunshine     = row(4);
    wind_gusts   = row(7);
    humidity     = row(12);
    cloud        = row(14);   % cloud_cover_mean
    cloud_max    = row(15);   % cloud_cover_max  ← nova coluna
    cloud_min    = row(16);   % cloud_cover_min  ← nova coluna
    press_mean   = row(17);   % era row(15)
    press_min    = row(18);   % era row(16)
    precip_hours = row(19);   % era row(17)
    press_drop   = press_mean - press_min;

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

    % Cobertura de nuvens (média)
    if     cloud < thr.cloud_clear,         c_tok = 'cloud_clear';
    elseif cloud < thr.cloud_partial,       c_tok = 'cloud_partial';
    elseif cloud < thr.cloud_overcast,      c_tok = 'cloud_overcast';
    else,                                   c_tok = 'cloud_heavy';
    end

    % Pico de cobertura — distingue nublado persistente de passageiro
    if     cloud_max > 90,                  cm_tok = 'cmax_full';
    elseif cloud_max > 70,                  cm_tok = 'cmax_high';
    elseif cloud_max > 40,                  cm_tok = 'cmax_mid';
    else,                                   cm_tok = 'cmax_low';
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
    else,                                                    pr_tok = 'press_normal';
    end

    % Combo — limiares dinâmicos + casos de fog + cloudy
    if     precip == 0 && cloud < thr.cloud_clear && humidity < thr.hum_mid
                                                            combo = 'clear_sun';
    elseif precip == 0 && cloud > thr.cloud_partial && cloud_max > 80
                                                            combo = 'overcast_dry';   % cloudy territory
    elseif precip == 0 && humidity > thr.hum_drizzle && cloud > thr.cloud_partial
                                                            combo = 'dry_humid';      % fog territory
    elseif precip < thr.precip_trace && precip_hours < thr.phr_short
                                                            combo = 'light_drizzle';
    elseif precip > thr.precip_low && precip_hours > thr.phr_moderate && cloud > thr.cloud_overcast
                                                            combo = 'sustained_rain';
    elseif precip > thr.precip_low && humidity > thr.hum_rain
                                                            combo = 'heavy_humid';
    elseif precip == 0 && wind_gusts > thr.wind_windy
                                                            combo = 'dry_windy';      % thunder/föhn
    else,                                                   combo = 'ambiguous';
    end

    % Tokens de interacção par-a-par
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
    t11 = strcat(p_tok,  '_', w_tok);    % precip + vento → separa thunder de rain
    t12 = strcat(h_tok,  '_', pr_tok);   % humidade + pressão → fog vs drizzle
    t13 = strcat(s_tok,  '_', h_tok);    % sunshine + humidade → fog vs sun
    t14 = strcat(c_tok,  '_', cm_tok);   % cloud_mean × cloud_max → distingue cloudy

    tokens = {p_tok, h_tok, c_tok, ph_tok, s_tok, combo, w_tok, pr_tok, cm_tok, ...
              t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14};
end