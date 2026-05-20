function tokens = extract_features(x)

    tokens = {};

    % =========================
    % FEATURES BASE
    % =========================
    p  = x(1);   % precipitation
    tM = x(2);   % temp max
    tN = x(3);   % temp min
    w  = x(4);   % wind
    s  = x(5);   % snow depth
    ms = x(6);   % month sin
    mc = x(7);   % month cos
    ts = x(8);   % sunshine hours
    gs = x(9);   % gust

    deltaT = tM - tN;

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
    % BLOCO 4 — AMPLITUDE TÉRMICA (discrimina sun vs drizzle)
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
    % BLOCO 7 — NEVE (profundidade)
    % =========================================================
    if s == 0
        tokens{end+1} = 'snow_absent';
    elseif s < 2
        tokens{end+1} = 'snow_trace';
    elseif s < 5
        tokens{end+1} = 'snow_light';
    elseif s < 15
        tokens{end+1} = 'snow_moderate';
    else
        tokens{end+1} = 'snow_deep';
    end

    % =========================================================
    % BLOCO 8 — HORAS DE SOL (crítico: drizzle vs sun)
    % =========================================================
    if ts == 0
        tokens{end+1} = 'sun_zero';
    elseif ts < 1
        tokens{end+1} = 'sun_trace';
    elseif ts < 2
        tokens{end+1} = 'sun_very_low';
    elseif ts < 3.5
        tokens{end+1} = 'sun_low';
    elseif ts < 5
        tokens{end+1} = 'sun_moderate';
    elseif ts < 7
        tokens{end+1} = 'sun_high';
    else
        tokens{end+1} = 'sun_very_high';
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
    % Este é o token mais discriminativo para drizzle vs sun.
    % Drizzle: p pequeno, ts pequeno → rácio ~1
    % Sun: p=0, ts alto → rácio ~0
    % Rain: p alto, ts=0 → rácio muito alto
    % =========================================================
    psr = p / (ts + 0.5);   % evita divisão por zero

    if psr == 0
        tokens{end+1} = 'psr_zero';           % sol claro sem chuva
    elseif psr < 0.1
        tokens{end+1} = 'psr_very_low';       % sol com trace de chuva
    elseif psr < 0.5
        tokens{end+1} = 'psr_low';            % maioritariamente seco
    elseif psr < 1.5
        tokens{end+1} = 'psr_moderate';       % misto — zona de drizzle
    elseif psr < 4
        tokens{end+1} = 'psr_high';           % chuva moderada
    else
        tokens{end+1} = 'psr_very_high';      % chuva intensa, sem sol
    end

    % =========================================================
    % BLOCO 11 — ÍNDICE DE NEBULOSIDADE ESTIMADO
    % Proxy: combina falta de sol e presença de chuva
    % =========================================================
    cloud_idx = (p * 1.5 + max(8 - ts, 0)) / 10;

    if cloud_idx < 0.3
        tokens{end+1} = 'cloud_clear';
    elseif cloud_idx < 0.6
        tokens{end+1} = 'cloud_partly';
    elseif cloud_idx < 1.0
        tokens{end+1} = 'cloud_mostly';
    else
        tokens{end+1} = 'cloud_overcast';
    end

    % =========================================================
    % BLOCO 12 — PADRÕES COMPOSTOS DRIZZLE
    % Drizzle: precipitação fraca + pouco sol + temperatura amena
    % A ausência de padrões fortes de rain/sun é tão importante
    % quanto a presença de precipitação fraca.
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
    % Drizzle invernal (frio + pouca chuva + sem sol)
    if p > 0 && p < 1.5 && tM < 10 && ts < 2
        tokens{end+1} = 'drizzle_winter_grey';
    end

    % =========================================================
    % BLOCO 13 — PADRÕES COMPOSTOS SUN
    % Distinção chave: p=0 é condição necessária mas não suficiente.
    % Sun real tem ts alto + tM razoável.
    % =========================================================
    if p == 0 && ts > 4
        tokens{end+1} = 'sun_core';
    end
    if p == 0 && ts > 5 && tM > 12
        tokens{end+1} = 'sun_classic';
    end
    if p == 0 && ts > 6 && w < 5
        tokens{end+1} = 'sun_calm_clear';
    end
    if p == 0 && deltaT > 10
        tokens{end+1} = 'sun_dry_day';           % amplitude alta → sem nuvens
    end
    if p == 0 && ts > 3 && tM > 15 && tN > 5
        tokens{end+1} = 'sun_warm_day';
    end
    if p == 0 && ts > 5 && deltaT > 8
        tokens{end+1} = 'sun_definite';
    end
    % Sol de inverno (frio mas sem chuva e com algum sol)
    if p == 0 && tM < 10 && ts > 2
        tokens{end+1} = 'sun_winter_clear';
    end
    % Dia seco com vento (Seattle tem isto no verão)
    if p == 0 && w > 5 && ts > 3
        tokens{end+1} = 'sun_breezy';
    end

    % =========================================================
    % BLOCO 14 — PADRÕES COMPOSTOS RAIN
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
        tokens{end+1} = 'rain_warm';              % chuva de verão
    end
    if p > 1 && tM < 8 && tN < 3
        tokens{end+1} = 'rain_cold';              % chuva de inverno
    end

    % =========================================================
    % BLOCO 15 — PADRÕES COMPOSTOS SNOW
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
        tokens{end+1} = 'snow_bright_cold';       % neve com sol
    end
    if tN < -3 && p > 0 && ts < 2
        tokens{end+1} = 'snow_blizzard_like';
    end
    if s > 0 && p == 0 && ts > 2
        tokens{end+1} = 'snow_melting_sun';       % neve a derreter
    end
    if tM < 2 && tN < -2 && s == 0
        tokens{end+1} = 'snow_dry_freeze';        % gelado sem neve
    end

    % =========================================================
    % BLOCO 16 — HÍBRIDOS DISCRIMINATIVOS
    % Capturam as fronteiras difusas entre classes
    % =========================================================

    % Zona ambígua drizzle/sun (o caso problemático)
    if p < 1 && ts < 4 && tM > 6 && tM < 16
        tokens{end+1} = 'ambiguous_grey_mild';
    end
    if p == 0 && ts < 3 && tM > 8
        tokens{end+1} = 'dry_but_overcast';       % sem chuva mas nublado
    end

    % Dias húmidos escuros (rain vs drizzle)
    if p > 0 && ts == 0
        tokens{end+1} = 'wet_dark';
    end
    if p > 0 && ts < 1
        tokens{end+1} = 'wet_nearly_dark';
    end

    % Temperatura + precipitação
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

    % Vento + condições
    if p == 0 && w > 7
        tokens{end+1} = 'dry_windy';
    end
    if p > 2 && gs > 12
        tokens{end+1} = 'wet_gusty';
    end

    % =========================================================
    % BLOCO 17 — INTERAÇÕES TRIPLAS
    % Combinações de três features para máxima especificidade
    % =========================================================

    % Sol claro de verão
    if p == 0 && ts > 6 && tM > 20
        tokens{end+1} = 'summer_sun';
    end
    % Chuva de verão (raro em Seattle → marcador forte)
    if p > 2 && tM > 18 && ts < 2
        tokens{end+1} = 'summer_rain_event';
    end
    % Drizzle de outono (mais comum)
    if p > 0 && p < 2 && tM < 14 && angle > pi && angle < 3*pi/2
        tokens{end+1} = 'autumn_drizzle';
    end
    % Sol de verão com brisa
    if p == 0 && tM > 18 && w > 3 && w < 8
        tokens{end+1} = 'summer_breeze_sun';
    end
    % Neve com vento forte
    if (tN < 0 || s > 0) && w > 6
        tokens{end+1} = 'snow_wind';
    end
    % Dia cinzento de inverno (drizzle vs overcast sun)
    if tM < 10 && ts < 3 && p < 2
        tokens{end+1} = 'winter_grey_day';
    end
    % Dia frio e seco (sun de inverno)
    if p == 0 && tM < 12 && tN < 4 && ts > 3
        tokens{end+1} = 'cold_clear_day';
    end
    % Chuva leve com vento moderado (drizzle vs rain)
    if p > 0 && p < 3 && w > 4 && w < 9
        tokens{end+1} = 'light_rain_breezy';
    end

    % =========================================================
    % BLOCO 18 — EXTREMOS CLIMÁTICOS
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
    if s > 20
        tokens{end+1} = 'snow_record';
    end

end