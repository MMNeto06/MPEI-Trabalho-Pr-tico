function tokens = extract_features(row)
    precip       = row(1);
    sunshine     = row(4);
    wind_gusts   = row(7);
    temp_range   = row(9);
    humidity     = row(12);
    cloud        = row(14);
    press_mean   = row(15);
    press_min    = row(16);
    precip_hours = row(17);

    press_drop = press_mean - press_min;

    % --- tokens existentes (sem alteração) ---
    if precip == 0
        p_tok = 'precip_none';

    elseif precip < 1
        p_tok = 'precip_trace';
    
    elseif precip < 3
        p_tok = 'precip_drizzle';
    
    elseif precip < 6
        p_tok = 'precip_light_rain';
    
    elseif precip < 12
        p_tok = 'precip_rain';
    
    else
        p_tok = 'precip_heavy';
    end
        
    if precip_hours == 0
        ph_tok = 'phr_none';
    
    elseif precip_hours < 2
        ph_tok = 'phr_brief';
    
    elseif precip_hours < 5
        ph_tok = 'phr_short';
    
    elseif precip_hours < 9
        ph_tok = 'phr_medium';
    
    elseif precip_hours < 15
        ph_tok = 'phr_long';
    
    else
        ph_tok = 'phr_persistent';
    end

    if     cloud > 82,         c_tok = 'cloud_heavy';
    elseif cloud > 60,         c_tok = 'cloud_overcast';
    elseif cloud > 35,         c_tok = 'cloud_partial';
    else,                      c_tok = 'cloud_clear';
    end

    if     humidity > 82,      h_tok = 'hum_rain';
    elseif humidity > 70,      h_tok = 'hum_drizzle';
    elseif humidity > 50,      h_tok = 'hum_mid';
    else,                      h_tok = 'hum_low';
    end

    if     sunshine > 25200,   s_tok = 'sun_high';
    elseif sunshine > 10800,   s_tok = 'sun_mid';
    elseif sunshine > 3600,    s_tok = 'sun_low';
    else,                      s_tok = 'sun_none';
    end

    % --- token de vento/tempestade (novo) ---
    if     wind_gusts > 50 && temp_range > 12,  w_tok = 'storm_likely';
    elseif wind_gusts > 40,                      w_tok = 'windy';
    else,                                         w_tok = 'calm';
    end

    % --- token de pressão (novo) ---
    if     press_drop > 8 && press_min < 1008,   pr_tok = 'press_storm';
    elseif press_drop > 4,                        pr_tok = 'press_drop';
    elseif press_min > 1018,                      pr_tok = 'press_high';
    else,                                          pr_tok = 'press_normal';
    end

    % --- combo (limiares reais) ---
    if     precip == 0   && cloud < 35,                        combo = 'clear_sun';
    elseif precip == 0   && humidity > 70,                     combo = 'dry_humid';
    elseif precip < 2    && precip_hours < 6  && cloud < 75,   combo = 'light_drizzle';
    elseif precip > 5 && precip_hours > 5 && cloud > 75,       combo = 'sustained_rain';
    elseif precip > 10   && humidity > 82,                     combo = 'heavy_humid';
    else,                                                       combo = 'ambiguous';
    end

    cross_tokens = {
        strcat(p_tok, '_', ph_tok)
        strcat(p_tok, '_', h_tok)
        strcat(p_tok, '_', c_tok)
    
        strcat(ph_tok, '_', h_tok)
        strcat(ph_tok, '_', c_tok)
    
        strcat(h_tok, '_', c_tok)
    
        strcat(combo, '_', p_tok)
        strcat(combo, '_', ph_tok)
    
        strcat(s_tok, '_', c_tok)
        strcat(w_tok, '_', pr_tok)
    };

    tokens = {
        p_tok,
        h_tok,
        c_tok,
        ph_tok,
        s_tok,
        combo,
        w_tok,
        pr_tok
    };

    tokens = [tokens(:)' cross_tokens(:)'];
end