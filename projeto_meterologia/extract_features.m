function tokens_matrix = extract_features(X, thr)
    N = size(X, 1);
    
    precip       = X(:, 1);
    sunshine     = X(:, 4);
    wind_gusts   = X(:, 7);
    humidity     = X(:, 12);
    cloud        = X(:, 14);
    press_mean   = X(:, 15);
    press_min    = X(:, 16);
    precip_hours = X(:, 17);
    press_drop   = press_mean - press_min;
    
    p_tok = repmat("precip_heavy", N, 1);
    p_tok(precip < thr.precip_med)   = "precip_low";
    p_tok(precip < thr.precip_low)   = "precip_drizzle";
    p_tok(precip < thr.precip_trace) = "precip_trace";
    p_tok(precip == 0)               = "precip_none";
    
    ph_tok = repmat("phr_persistent", N, 1);
    ph_tok(precip_hours < thr.phr_moderate) = "phr_moderate";
    ph_tok(precip_hours < thr.phr_short)    = "phr_short";
    ph_tok(precip_hours < thr.phr_brief)    = "phr_brief";
    ph_tok(precip_hours == 0)               = "phr_none";
    
    c_tok = repmat("cloud_heavy", N, 1);
    c_tok(cloud < thr.cloud_overcast) = "cloud_overcast";
    c_tok(cloud < thr.cloud_partial)  = "cloud_partial";
    c_tok(cloud < thr.cloud_clear)    = "cloud_clear";
    
    h_tok = repmat("hum_rain", N, 1);
    h_tok(humidity < thr.hum_drizzle) = "hum_drizzle";
    h_tok(humidity < thr.hum_mid)     = "hum_mid";
    h_tok(humidity < thr.hum_low)     = "hum_low";
    
    s_tok = repmat("sun_high", N, 1);
    s_tok(sunshine < thr.sun_mid)  = "sun_mid";
    s_tok(sunshine < thr.sun_low)  = "sun_low";
    s_tok(sunshine < thr.sun_none) = "sun_none";
    
    w_tok = repmat("storm_likely", N, 1);
    w_tok(wind_gusts < thr.wind_windy) = "windy";
    w_tok(wind_gusts < thr.wind_calm)  = "calm";
    
    pr_tok = repmat("press_normal", N, 1);
    pr_tok(press_mean > thr.press_high & press_drop < 3) = "press_high";
    pr_tok(press_min < thr.press_drop | press_drop > 8)  = "press_storm";
    
    combo = repmat("ambiguous", N, 1);
    
    cond6 = precip == 0 & wind_gusts > thr.wind_windy;
    cond5 = precip > thr.precip_low & humidity > thr.hum_rain;
    cond4 = precip > thr.precip_low & precip_hours > thr.phr_moderate & cloud > thr.cloud_overcast;
    cond3 = precip < thr.precip_trace & precip_hours < thr.phr_short;
    cond2 = precip == 0 & humidity > thr.hum_drizzle & cloud > thr.cloud_partial;
    cond1 = precip == 0 & cloud < thr.cloud_clear & humidity < thr.hum_mid;
    
    combo(cond6) = "dry_windy";
    combo(cond5) = "heavy_humid";
    combo(cond4) = "sustained_rain";
    combo(cond3) = "light_drizzle";
    combo(cond2) = "dry_humid";
    combo(cond1) = "clear_sun"; 
    
    t1  = p_tok + "_" + ph_tok;
    t2  = p_tok + "_" + h_tok;
    t3  = p_tok + "_" + c_tok;
    t4  = ph_tok + "_" + h_tok;
    t5  = ph_tok + "_" + c_tok;
    t6  = h_tok + "_" + c_tok;
    t7  = combo + "_" + p_tok;
    t8  = combo + "_" + ph_tok;
    t9  = s_tok + "_" + c_tok;
    t10 = w_tok + "_" + pr_tok;
    t11 = p_tok + "_" + w_tok;
    t12 = h_tok + "_" + pr_tok;
    t13 = s_tok + "_" + h_tok;
    
    tokens_matrix = [p_tok, h_tok, c_tok, ph_tok, s_tok, combo, w_tok, pr_tok, ...
                     t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13];
end