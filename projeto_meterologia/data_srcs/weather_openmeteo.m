INPUT_FILE  = 'seattle_open_meteo.csv'; % .csv do open-meteo (com 3 linhas de metadata)
OUTPUT_FILE = 'seattle.csv';% csv de saída simplificado

WMO_FOG = [45, 48];
WMO_DRIZZLE = [51, 53, 55, 56, 57];
WMO_RAIN = [61, 63, 65, 66, 67, 80, 81, 82];
WMO_SNOW = [71, 73, 75, 77, 85, 86];
WMO_THUNDER = [95, 96, 99];

fid = fopen(INPUT_FILE, 'r', 'n', 'UTF-8');
if fid == -1
    error('Não foi possível abrir o ficheiro: %s', INPUT_FILE);
end

all_lines = {};
tline = fgetl(fid);
while ischar(tline)
    all_lines{end+1} = tline;
    tline = fgetl(fid);
end
fclose(fid);

header_idx = -1;
for i = 1:numel(all_lines)
    if strncmp(strtrim(all_lines{i}), 'time,', 5)
        header_idx = i;
        break;
    end
end
if header_idx == -1
    error('Erro: cabeçalho não encontrado (linha começada por "time,").');
end

header_line = all_lines{header_idx};
data_lines = all_lines(header_idx+1 : end);

col_names = strsplit(header_line, ',');
col_names = strtrim(col_names);
col_map = containers.Map(col_names, num2cell(1:numel(col_names)));

out_header = ['date,precipitation,temp_max,temp_min,' ...
              'sunshine_duration,shortwave_radiation,' ...
              'wind_speed_max,wind_gusts_max,' ...
              'snowfall,temp_range,month_sin,month_cos,' ...
              'humidity_mean,humidity_min,' ...
              'dew_point_mean,dew_point_max,' ...
              'cloud_cover_mean,pressure_mean,pressure_min,' ...
              'precipitation_hours,weather'];

fout = fopen(OUTPUT_FILE, 'w', 'n', 'UTF-8');
if fout == -1
    error('Não foi possível criar o ficheiro de saída: %s', OUTPUT_FILE);
end
fprintf(fout, '%s\n', out_header);

for li = 1:numel(data_lines)
    line = strtrim(data_lines{li});
    if isempty(line)
        continue;
    end

    fields = strsplit(line, ',');
    while numel(fields) < numel(col_names)
        fields{end+1} = '';
    end

    raw_date = strtrim(fields{col_map('time')});
    if isempty(raw_date)
        continue;
    end

    try
        dt = datetime(raw_date, 'InputFormat', 'yyyy-MM-dd');
        date_str  = char(datetime(dt, 'Format', 'yyyy-MM-dd'));
        m = month(dt);
        month_sin = round(sin(2 * pi * m / 12), 6);
        month_cos = round(cos(2 * pi * m / 12), 6);
    catch
        date_str = raw_date;
        month_sin = 0.0;
        month_cos = 1.0;
    end

    tmax       = get_float(fields, col_map, 'temperature_2m_max (°C)',          0.0);
    tmin       = get_float(fields, col_map, 'temperature_2m_min (°C)',          0.0);
    prcp       = get_float(fields, col_map, 'precipitation_sum (mm)',           0.0);
    prcp_hours = get_float(fields, col_map, 'precipitation_hours (h)',          0.0);
    snowfall   = get_float(fields, col_map, 'snowfall_sum (cm)',                0.0);
    sunshine_s = get_float(fields, col_map, 'sunshine_duration (s)',            0.0);
    radiation  = get_float(fields, col_map, 'shortwave_radiation_sum (MJ/m²)', 0.0);
    wind_speed = get_float(fields, col_map, 'wind_speed_10m_max (km/h)',        0.0);
    wind_gusts = get_float(fields, col_map, 'wind_gusts_10m_max (km/h)',        0.0);
    rh_mean    = get_float(fields, col_map, 'relative_humidity_2m_mean (%)',    0.0);
    rh_min     = get_float(fields, col_map, 'relative_humidity_2m_min (%)',     0.0);
    dew_mean   = get_float(fields, col_map, 'dew_point_2m_mean (°C)',           0.0);
    dew_max    = get_float(fields, col_map, 'dew_point_2m_max (°C)',            0.0);
    cloud_mean = get_float(fields, col_map, 'cloud_cover_mean (%)',             0.0);
    pres_mean  = get_float(fields, col_map, 'pressure_msl_mean (hPa)',          0.0);
    pres_min   = get_float(fields, col_map, 'pressure_msl_min (hPa)',           0.0);
    wmo_code   = get_int  (fields, col_map, 'weather_code (wmo code)',          -1);

    weather = classify_weather(wmo_code, prcp, prcp_hours, snowfall, ...
                               rh_mean, cloud_mean, dew_mean, tmin, ...
                               WMO_FOG, WMO_DRIZZLE, WMO_RAIN, WMO_SNOW, WMO_THUNDER);

    sunshine_h = round(sunshine_s / 3600, 4);
    temp_range = round(tmax - tmin, 4);

    fprintf(fout, '%s,%g,%g,%g,%.4f,%g,%g,%g,%g,%.4f,%.6f,%.6f,%g,%g,%g,%g,%g,%g,%g,%g,%s\n', ...
        date_str, ...
        prcp, tmax, tmin, ...
        sunshine_h, radiation, ...
        wind_speed, wind_gusts, ...
        snowfall, temp_range, ...
        month_sin, month_cos, ...
        rh_mean, rh_min, ...
        dew_mean, dew_max, ...
        cloud_mean, pres_mean, pres_min, ...
        prcp_hours, weather);
end

fclose(fout);
fprintf('Concluído. Ficheiro gerado: %s\n', OUTPUT_FILE);

function val = get_float(fields, col_map, name, default).
    if ~isKey(col_map, name)
        val = default;
        return;
    end
    raw = strtrim(fields{col_map(name)});
    num = str2double(raw);
    if isnan(num)
        val = default;
    else
        val = num;
    end
end

function val = get_int(fields, col_map, name, default)
    if ~isKey(col_map, name)
        val = default;
        return;
    end
    raw = strtrim(fields{col_map(name)});
    num = str2double(raw);
    if isnan(num)
        val = default;
    else
        val = floor(num);
    end
end


function weather = classify_weather(wmo_code, prcp, prcp_hours, snowfall, ...
                                    rh_mean, cloud_mean, dew_mean, temp_min, ...
                                    WMO_FOG, WMO_DRIZZLE, WMO_RAIN, WMO_SNOW, WMO_THUNDER)
    if ismember(wmo_code, WMO_DRIZZLE)
        weather = 'drizzle';
    elseif ismember(wmo_code, WMO_RAIN)
        weather = 'rain';
    elseif ismember(wmo_code, WMO_SNOW)
        weather = 'snow';
    elseif ismember(wmo_code, WMO_FOG)
        weather = 'fog';
    elseif ismember(wmo_code, WMO_THUNDER)
        weather = 'thunder';
    else
        % WMO 0-3 (sol/nublado) heurísticas
        if snowfall > 0
            weather = 'snow';
        elseif prcp > 1.0
            weather = 'rain';
        elseif prcp > 0 && prcp <= 1.0 && prcp_hours >= 6
            weather = 'drizzle';
        else
            weather = 'sun';
        end
    end

    if strcmp(weather, 'sun')
        dew_spread = temp_min - dew_mean;
        if dew_spread < 2.5 && rh_mean >= 88 && cloud_mean >= 80 && prcp < 0.3
            weather = 'fog';
        end
    end

    if strcmp(weather, 'rain') || ismember(wmo_code, WMO_THUNDER)
        if ismember(wmo_code, WMO_THUNDER)
            weather = 'thunder';
        elseif strcmp(weather, 'rain')
            if prcp_hours > 0
                intensity = prcp / prcp_hours;
            else
                intensity = 0;
            end
            if prcp >= 10.0 && intensity >= 2.5
                weather = 'thunder';
            end
            if wmo_code == 82 && intensity >= 2.5
                weather = 'thunder';
            end
        end
    end

end