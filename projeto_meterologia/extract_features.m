function tokens = extract_features(row, thr)
    precip       = row(1);
    temp_max     = row(2);
    sunshine     = row(4);
    shortwave    = row(5);   % shortwave_radiation — col 5
    wind_gusts   = row(7);
    humidity     = row(12);
    dew_mean     = row(14);
    cloud        = row(16);
    cloud_max    = row(17);
    cloud_min    = row(18);
    press_mean   = row(19);  % FIX Bug 2: era row(20) → lia pressure_min por engano
    press_min    = row(20);  % FIX Bug 2: era row(21) → lia log1p(precip_hours) por engano
    precip_hours = row(21);  % FIX Bug 2: era row(22) → lia temp_mean por engano
    % col 22 = temp_mean, col 23 = season_temp, col 24 = cos_x_tmax
    dew_depression = row(25); % NOVO: dew_depression = temp_mean − dew_point_mean
    press_drop   = press_mean - press_min;

    % Temperatura
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

    % Cobertura de nuvens — 5 níveis usando thr.cloud_cloudy
    % Ordem garantida: cloud_clear < cloud_cloudy < cloud_partial < cloud_overcast
    if     cloud < thr.cloud_clear,         c_tok = 'cloud_clear';
    elseif cloud < thr.cloud_cloudy,        c_tok = 'cloud_few';      % FIX: era ignorado
    elseif cloud < thr.cloud_partial,       c_tok = 'cloud_cloudy';   % FIX: nível novo
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

    % Shortwave Radiation — discriminador sun/cloudy em dias de inverno
    if     shortwave < thr.sw_low,          sw_tok = 'sw_low';
    elseif shortwave < thr.sw_high,         sw_tok = 'sw_mid';
    else,                                   sw_tok = 'sw_high';
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

    % Ponto de Orvalho
    if     dew_mean < thr.dew_low,   d_tok = 'dew_low';
    elseif dew_mean < thr.dew_high,  d_tok = 'dew_mid';
    else,                            d_tok = 'dew_high';
    end

    % Depressão do Ponto de Orvalho (temp_mean − dew_mean) — NOVO
    % Valores baixos (<2 °C) → névoa/nevoeiro; valores altos (>10 °C) → sol/poeira seca
    if     dew_depression < thr.dewdep_fog,    dd_tok = 'dewdep_fog';
    elseif dew_depression < thr.dewdep_cloud,  dd_tok = 'dewdep_cloud';
    elseif dew_depression < thr.dewdep_sun,    dd_tok = 'dewdep_mid';
    else,                                      dd_tok = 'dewdep_sun';
    end

    % Combo — inclui 'cloudy_dry' para dias nublados sem precipitação
    if     precip == 0 && cloud < thr.cloud_clear && humidity < thr.hum_mid
                                                            combo = 'clear_sun';
    elseif precip == 0 && cloud >= thr.sun_cloudy && cloud < thr.cloud_overcast ...
           && sunshine < thr.sun_mid
                                                            combo = 'cloudy_dry';   % FIX: usa thr.sun_cloudy (ponto médio p60|sun/p40|cloudy)
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
    t16 = strcat(t_tok,  '_', h_tok);
    t17 = strcat(t_tok,  '_', p_tok);
    t18 = strcat(s_tok,  '_', combo);  % NOVO: sunshine + combo (sun vs cloudy)
    t19 = strcat(sw_tok, '_', c_tok);  % NOVO: shortwave + cloud (discriminador inverno)
    t20_sw = strcat(sw_tok, '_', s_tok);  % NOVO: shortwave + sunshine
    % Tokens dew_depression — discriminam fog/sun/dry
    t21_dd = strcat(dd_tok, '_', h_tok);   % depressão + humidade
    t22_dd = strcat(dd_tok, '_', c_tok);   % depressão + nebulosidade
    t23_dd = strcat(dd_tok, '_', d_tok);   % depressão + dew absoluto
    t24_dd = strcat(dd_tok, '_', combo);   % depressão + combo

    tokens = {t_tok, p_tok, h_tok, c_tok, ph_tok, s_tok, combo, w_tok, pr_tok, d_tok, ...
              t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15, t16, t17, t18, ...
              sw_tok, t19, t20_sw, t21_dd, t22_dd, t23_dd, t24_dd};
    % NOTA: dd_tok removido como token standalone — dewdep_fog disparava em 61 %
    % dos dias de chuva e 31 % de drizzle, causando 43 erros cloudy→fog e fog
    % precision de 49 %. O sinal de dew depression mantém-se nos tokens combinados
    % (t21_dd…t24_dd) onde é contextualizado pela humidade, nebulosidade, orvalho
    % e combo, o que elimina o ruído sem perder o poder discriminante para fog.

    % cloud_cover_max — FIX: movido para DEPOIS de tokens estar definido
    if cloud_max >= 0
        if   cloud_max < thr.cloud_partial,    cm_tok = 'cmax_partial';
        elseif cloud_max < thr.cloud_overcast,  cm_tok = 'cmax_overcast';
        else,                                   cm_tok = 'cmax_heavy';
        end
        t20 = strcat(cm_tok, '_', c_tok);
        tokens = [tokens, {cm_tok, t20}];
    end
end