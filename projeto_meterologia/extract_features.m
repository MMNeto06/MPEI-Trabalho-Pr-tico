function tokens = extract_features(x)
%EXTRACT_FEATURES  Discretiza um vetor de features numéricas em tokens textuais.
%
%   Mapeamento das colunas de X (após pré-processamento em main_demo.m):
%     x( 1) precipitation        x( 2) temp_max
%     x( 3) temp_min             x( 4) sunshine_duration  (horas)
%     x( 5) shortwave_radiation  x( 6) wind_speed_max
%     x( 7) wind_gusts_max       x( 8) snowfall           (mm)
%     x( 9) temp_range           x(10) month_sin
%     x(11) month_cos            x(12) humidity_mean      (%)
%     x(13) humidity_min         x(14) cloud_cover_mean   (%)
%     x(15) pressure_mean        x(16) pressure_min       (hPa)
%     x(17) precipitation_hours  x(18..20) compostas — ignoradas aqui

    tokens = {};

    % =========================
    % LEITURA DAS FEATURES BASE
    % =========================
    p   = x(1);    % precipitation (mm)
    tM  = x(2);    % temp_max (°C)
    tN  = x(3);    % temp_min (°C)
    ts  = x(4);    % sunshine_duration (horas)
    sr  = x(5);    % shortwave_radiation (W/m²)
    w   = x(6);    % wind_speed_max (m/s)
    gs  = x(7);    % wind_gusts_max (m/s)
    s   = x(8);    % snowfall (mm)
    deltaT = x(9); % temp_range = temp_max - temp_min (pré-calculado)
    ms  = x(10);   % month_sin
    mc  = x(11);   % month_cos
    hm  = x(12);   % humidity_mean (%)
    hmin = x(13);  % humidity_min (%)
    cc  = x(14);   % cloud_cover_mean (%)
    pm  = x(15);   % pressure_mean (hPa)
    pmin = x(16);  % pressure_min (hPa)
    ph  = x(17);   % precipitation_hours

    % =========================================================
    % BLOCO 1 — PRECIPITAÇÃO (granularidade alta)
    % =========================================================
    if p == 0
        tokens{end+1} = 'precip_zero';
    elseif p < 0.2
        tokens{end+1} = 'precip_trace';
    elseif p < 0.5
        tokens{end+1} = 'precip_vlight';
    elseif p < 1
        tokens{end+1} = 'precip_light';
    elseif p < 2
        tokens{end+1} = 'precip_light_mod';
    elseif p < 4
        tokens{end+1} = 'precip_moderate';
    elseif p < 7
        tokens{end+1} = 'precip_heavy';
    elseif p < 12
        tokens{end+1} = 'precip_vheavy';
    else
        tokens{end+1} = 'precip_extreme';
    end

    % =========================================================
    % BLOCO 2 — TEMPERATURA MÁXIMA
    % =========================================================
    if tM < -2
        tokens{end+1} = 'tmax_hard_freeze';
    elseif tM < 2
        tokens{end+1} = 'tmax_freeze';
    elseif tM < 6
        tokens{end+1} = 'tmax_very_cold';
    elseif tM < 10
        tokens{end+1} = 'tmax_cold';
    elseif tM < 14
        tokens{end+1} = 'tmax_cool';
    elseif tM < 18
        tokens{end+1} = 'tmax_mild';
    elseif tM < 22
        tokens{end+1} = 'tmax_warm';
    elseif tM < 27
        tokens{end+1} = 'tmax_hot';
    else
        tokens{end+1} = 'tmax_extreme';
    end

    % =========================================================
    % BLOCO 3 — TEMPERATURA MÍNIMA
    % =========================================================
    if tN < -5
        tokens{end+1} = 'tmin_deep_freeze';
    elseif tN < 0
        tokens{end+1} = 'tmin_freeze';
    elseif tN < 3
        tokens{end+1} = 'tmin_near_freeze';
    elseif tN < 6
        tokens{end+1} = 'tmin_cold';
    elseif tN < 10
        tokens{end+1} = 'tmin_cool';
    elseif tN < 14
        tokens{end+1} = 'tmin_mild';
    else
        tokens{end+1} = 'tmin_warm';
    end

    % =========================================================
    % BLOCO 4 — AMPLITUDE TÉRMICA
    % deltaT alto + p=0 → sol. deltaT baixo + p>0 → drizzle/chuva.
    % =========================================================
    if deltaT < 3
        tokens{end+1} = 'dT_very_low';
    elseif deltaT < 5
        tokens{end+1} = 'dT_low';
    elseif deltaT < 8
        tokens{end+1} = 'dT_mid';
    elseif deltaT < 12
        tokens{end+1} = 'dT_high';
    else
        tokens{end+1} = 'dT_very_high';
    end

    % =========================================================
    % BLOCO 5 — VENTO
    % =========================================================
    if w < 1.5
        tokens{end+1} = 'wind_calm';
    elseif w < 3
        tokens{end+1} = 'wind_very_light';
    elseif w < 5
        tokens{end+1} = 'wind_light';
    elseif w < 7
        tokens{end+1} = 'wind_moderate';
    elseif w < 10
        tokens{end+1} = 'wind_fresh';
    else
        tokens{end+1} = 'wind_strong';
    end

    % =========================================================
    % BLOCO 6 — RAJADAS
    % =========================================================
    if gs < 3
        tokens{end+1} = 'gust_none';
    elseif gs < 7
        tokens{end+1} = 'gust_weak';
    elseif gs < 12
        tokens{end+1} = 'gust_medium';
    elseif gs < 18
        tokens{end+1} = 'gust_strong';
    else
        tokens{end+1} = 'gust_extreme';
    end

    % =========================================================
    % BLOCO 7 — NEVE (snowfall em mm)
    % =========================================================
    if s == 0
        tokens{end+1} = 'snow_absent';
    elseif s < 0.5
        tokens{end+1} = 'snow_trace';
    elseif s < 2
        tokens{end+1} = 'snow_light';
    elseif s < 5
        tokens{end+1} = 'snow_moderate';
    else
        tokens{end+1} = 'snow_heavy';
    end

    % =========================================================
    % BLOCO 8 — HORAS DE SOL (crítico: drizzle vs sun)
    % =========================================================
    if ts == 0
        tokens{end+1} = 'sun_zero';
    elseif ts < 1
        tokens{end+1} = 'sun_trace';
    elseif ts < 3
        tokens{end+1} = 'sun_very_low';
    elseif ts < 5
        tokens{end+1} = 'sun_low';
    elseif ts < 8
        tokens{end+1} = 'sun_moderate';
    elseif ts < 11
        tokens{end+1} = 'sun_high';
    elseif ts < 14
        tokens{end+1} = 'sun_very_high';
    else
        tokens{end+1} = 'sun_full_day';
    end

    % =========================================================
    % BLOCO 9 — ESTAÇÃO DO ANO
    % =========================================================
    angle = atan2(ms, mc);
    if angle < 0
        angle = angle + 2*pi;
    end
    if angle < pi/4
        tokens{end+1} = 'season_early_spring';
    elseif angle < pi/2
        tokens{end+1} = 'season_late_spring';
    elseif angle < 3*pi/4
        tokens{end+1} = 'season_early_summer';
    elseif angle < pi
        tokens{end+1} = 'season_late_summer';
    elseif angle < 5*pi/4
        tokens{end+1} = 'season_early_autumn';
    elseif angle < 3*pi/2
        tokens{end+1} = 'season_late_autumn';
    elseif angle < 7*pi/4
        tokens{end+1} = 'season_early_winter';
    else
        tokens{end+1} = 'season_late_winter';
    end

    % =========================================================
    % BLOCO 10 — RÁCIO PRECIPITAÇÃO/SOL
    % =========================================================
    psr = p / (ts + 0.5);
    if psr == 0
        tokens{end+1} = 'psr_zero';
    elseif psr < 0.1
        tokens{end+1} = 'psr_very_low';
    elseif psr < 0.5
        tokens{end+1} = 'psr_low';
    elseif psr < 1.5
        tokens{end+1} = 'psr_moderate';
    elseif psr < 4
        tokens{end+1} = 'psr_high';
    else
        tokens{end+1} = 'psr_very_high';
    end

    % =========================================================
    % BLOCO 11 — COBERTURA DE NUVENS (cloud_cover_mean, %)
    % =========================================================
    if cc < 10
        tokens{end+1} = 'cloud_clear';
    elseif cc < 30
        tokens{end+1} = 'cloud_mostly_clear';
    elseif cc < 50
        tokens{end+1} = 'cloud_partly';
    elseif cc < 75
        tokens{end+1} = 'cloud_mostly_cloudy';
    else
        tokens{end+1} = 'cloud_overcast';
    end

    % =========================================================
    % BLOCO 12 — HUMIDADE RELATIVA (%)
    % =========================================================
    if hm < 50
        tokens{end+1} = 'hum_low';
    elseif hm < 65
        tokens{end+1} = 'hum_moderate';
    elseif hm < 78
        tokens{end+1} = 'hum_high';
    elseif hm < 90
        tokens{end+1} = 'hum_very_high';
    else
        tokens{end+1} = 'hum_saturated';
    end

    % =========================================================
    % BLOCO 13 — PRESSÃO ATMOSFÉRICA (hPa)
    % =========================================================
    if pm < 1005
        tokens{end+1} = 'pressure_very_low';
    elseif pm < 1010
        tokens{end+1} = 'pressure_low';
    elseif pm < 1017
        tokens{end+1} = 'pressure_normal';
    elseif pm < 1025
        tokens{end+1} = 'pressure_high';
    else
        tokens{end+1} = 'pressure_very_high';
    end

    % =========================================================
    % BLOCO 14 — HORAS DE PRECIPITAÇÃO
    % =========================================================
    if ph == 0
        tokens{end+1} = 'phours_none';
    elseif ph < 3
        tokens{end+1} = 'phours_brief';
    elseif ph < 8
        tokens{end+1} = 'phours_moderate';
    elseif ph < 16
        tokens{end+1} = 'phours_long';
    else
        tokens{end+1} = 'phours_all_day';
    end

    % =========================================================
    % BLOCO 15 — RADIAÇÃO DE ONDA CURTA (W/m²)
    % =========================================================
    if sr < 30
        tokens{end+1} = 'rad_very_low';
    elseif sr < 80
        tokens{end+1} = 'rad_low';
    elseif sr < 150
        tokens{end+1} = 'rad_moderate';
    elseif sr < 220
        tokens{end+1} = 'rad_high';
    else
        tokens{end+1} = 'rad_very_high';
    end

    % =========================================================
    % BLOCO 16 — PADRÕES COMPOSTOS DRIZZLE
    % =========================================================
    if p > 0 && p < 2 && ts < 3
        tokens{end+1} = 'drizzle_core';
    end
    if p > 0 && p < 1 && ts < 2 && w < 5
        tokens{end+1} = 'drizzle_classic';
    end
    if p > 0 && p < 0.5 && ts == 0
        tokens{end+1} = 'drizzle_grey';
    end
    if p > 0 && p < 3 && deltaT < 6 && tM > 5 && tM < 18
        tokens{end+1} = 'drizzle_mild_humid';
    end
    if p > 0 && p < 2 && ts < 4 && gs < 10
        tokens{end+1} = 'drizzle_calm_wet';
    end
    if p > 0 && p < 1.5 && tM < 10 && ts < 2
        tokens{end+1} = 'drizzle_winter_grey';
    end
    if p > 0 && p < 2 && hm > 80 && cc > 70
        tokens{end+1} = 'drizzle_humid_overcast';
    end
    if ph > 0 && ph < 6 && p < 2
        tokens{end+1} = 'drizzle_brief_hours';
    end

    % =========================================================
    % BLOCO 17 — PADRÕES COMPOSTOS SUN
    % =========================================================
    if p == 0 && ts > 6
        tokens{end+1} = 'sun_core';
    end
    if p == 0 && ts > 8 && tM > 12
        tokens{end+1} = 'sun_classic';
    end
    if p == 0 && ts > 9 && w < 5
        tokens{end+1} = 'sun_calm_clear';
    end
    if p == 0 && deltaT > 10
        tokens{end+1} = 'sun_dry_day';
    end
    if p == 0 && ts > 5 && tM > 15 && tN > 5
        tokens{end+1} = 'sun_warm_day';
    end
    if p == 0 && ts > 8 && deltaT > 8
        tokens{end+1} = 'sun_definite';
    end
    if p == 0 && tM < 10 && ts > 3
        tokens{end+1} = 'sun_winter_clear';
    end
    if p == 0 && w > 5 && ts > 4
        tokens{end+1} = 'sun_breezy';
    end
    if p == 0 && cc < 20 && ts > 8
        tokens{end+1} = 'sun_low_cloud';
    end

    % =========================================================
    % BLOCO 18 — PADRÕES COMPOSTOS RAIN
    % =========================================================
    if p >= 5
        tokens{end+1} = 'rain_core';
    end
    if p >= 3 && ts == 0
        tokens{end+1} = 'rain_dark';
    end
    if p > 5 && w > 5
        tokens{end+1} = 'rain_storm';
    end
    if p > 8 && gs > 10
        tokens{end+1} = 'rain_heavy_storm';
    end
    if p > 2 && p < 6 && ts < 2
        tokens{end+1} = 'rain_steady';
    end
    if p > 3 && tM > 15
        tokens{end+1} = 'rain_warm';
    end
    if p > 1 && tM < 8 && tN < 3
        tokens{end+1} = 'rain_cold';
    end
    if ph > 10 && p > 2
        tokens{end+1} = 'rain_long_duration';
    end
    if p > 3 && pm < 1010
        tokens{end+1} = 'rain_low_pressure';
    end

    % =========================================================
    % BLOCO 19 — PADRÕES COMPOSTOS SNOW
    % =========================================================
    if tM < 2 || s > 0 || tN < -1
        tokens{end+1} = 'snow_conditions';
    end
    if tN < 0 && p > 0
        tokens{end+1} = 'snow_freezing_precip';
    end
    if s > 0 && tM < 4
        tokens{end+1} = 'snow_persistent';
    end
    if tM < 0 && ts > 3
        tokens{end+1} = 'snow_bright_cold';
    end
    if tN < -3 && p > 0 && ts < 2
        tokens{end+1} = 'snow_blizzard_like';
    end
    if s > 0 && p == 0 && ts > 2
        tokens{end+1} = 'snow_melting_sun';
    end
    if tM < 2 && tN < -2 && s == 0
        tokens{end+1} = 'snow_dry_freeze';
    end
    if s > 2 && w > 5
        tokens{end+1} = 'snow_wind_driven';
    end

    % =========================================================
    % BLOCO 20 — PADRÕES COMPOSTOS FOG
    % =========================================================
    if hm > 88 && ts < 3 && p < 1
        tokens{end+1} = 'fog_core';
    end
    if hm > 90 && cc > 80 && p == 0
        tokens{end+1} = 'fog_dry_saturated';
    end
    if hm > 85 && ts == 0 && p == 0
        tokens{end+1} = 'fog_zero_sun_dry';
    end
    if hm > 85 && deltaT < 4 && ts < 2
        tokens{end+1} = 'fog_low_dT';
    end
    if hm > 80 && cc > 85 && p < 0.5 && w < 4
        tokens{end+1} = 'fog_calm_humid';
    end
    if hm > 88 && tM > 5 && tM < 18 && p < 0.5
        tokens{end+1} = 'fog_mild_saturated';
    end
    if hm > 90 && ph == 0
        tokens{end+1} = 'fog_no_precip_saturated';
    end
    if hmin > 80 && deltaT > 6 && p == 0
        tokens{end+1} = 'fog_radiation_type';
    end

    % =========================================================
    % BLOCO 21 — PADRÕES COMPOSTOS THUNDER
    % =========================================================
    if p > 5 && gs > 15
        tokens{end+1} = 'thunder_core';
    end
    if p > 3 && gs > 12 && tM > 15
        tokens{end+1} = 'thunder_warm_gusty';
    end
    if p > 8 && gs > 18
        tokens{end+1} = 'thunder_heavy';
    end
    if p > 2 && gs > 10 && pm < 1010
        tokens{end+1} = 'thunder_low_pressure';
    end
    if gs > 15 && pmin < 1005
        tokens{end+1} = 'thunder_pressure_drop';
    end
    if p > 5 && tM > 18 && gs > 10
        tokens{end+1} = 'thunder_summer_storm';
    end

    % =========================================================
    % BLOCO 22 — HÍBRIDOS DISCRIMINATIVOS
    % =========================================================
    if p < 1 && ts < 4 && tM > 6 && tM < 16
        tokens{end+1} = 'ambiguous_grey_mild';
    end
    if p == 0 && ts < 3 && tM > 8
        tokens{end+1} = 'dry_but_overcast';
    end
    if p > 0 && ts == 0
        tokens{end+1} = 'wet_dark';
    end
    if p > 0 && ts < 1
        tokens{end+1} = 'wet_nearly_dark';
    end
    if ts == 0 && hm > 85 && p < 1
        tokens{end+1} = 'dark_humid_dry';
    end
    if tN < 3 && p > 0
        tokens{end+1} = 'cold_wet';
    end
    if tN > 8 && p > 2
        tokens{end+1} = 'mild_wet';
    end
    if p == 0 && tM < 7
        tokens{end+1} = 'cold_dry';
    end
    if p == 0 && tM > 20
        tokens{end+1} = 'hot_dry';
    end
    if p == 0 && w > 7
        tokens{end+1} = 'dry_windy';
    end
    if p > 2 && gs > 12
        tokens{end+1} = 'wet_gusty';
    end

    % =========================================================
    % BLOCO 23 — INTERAÇÕES TRIPLAR
    % =========================================================
    if p == 0 && ts > 10 && tM > 20
        tokens{end+1} = 'summer_sun';
    end
    if p > 2 && tM > 18 && ts < 2
        tokens{end+1} = 'summer_rain_event';
    end
    if p > 0 && p < 2 && tM < 14 && angle > pi && angle < 3*pi/2
        tokens{end+1} = 'autumn_drizzle';
    end
    if p == 0 && tM > 18 && w > 3 && w < 8
        tokens{end+1} = 'summer_breeze_sun';
    end
    if (tN < 0 || s > 0) && w > 6
        tokens{end+1} = 'snow_wind';
    end
    if tM < 10 && ts < 3 && p < 2
        tokens{end+1} = 'winter_grey_day';
    end
    if p == 0 && tM < 12 && tN < 4 && ts > 4
        tokens{end+1} = 'cold_clear_day';
    end
    if p > 0 && p < 3 && w > 4 && w < 9
        tokens{end+1} = 'light_rain_breezy';
    end
    if hm > 88 && tM < 12 && p < 0.5 && ts < 2
        tokens{end+1} = 'winter_coastal_fog';
    end
    if p == 0 && ts > 6 && hm < 70
        tokens{end+1} = 'sun_low_humidity';
    end

    % =========================================================
    % BLOCO 24 — EXTREMOS CLIMÁTICOS
    % =========================================================
    if tM > 28
        tokens{end+1} = 'heat_extreme';
    end
    if tM > 32
        tokens{end+1} = 'heat_record';
    end
    if tN < -5
        tokens{end+1} = 'freeze_severe';
    end
    if tN < -8
        tokens{end+1} = 'freeze_extreme';
    end
    if gs > 15
        tokens{end+1} = 'gust_extreme';
    end
    if gs > 20
        tokens{end+1} = 'gust_storm';
    end
    if p > 15
        tokens{end+1} = 'precip_record';
    end
    if s > 10
        tokens{end+1} = 'snow_record';
    end
    if hm > 95
        tokens{end+1} = 'humidity_record';
    end
    if pm < 998
        tokens{end+1} = 'pressure_storm';
    end
end