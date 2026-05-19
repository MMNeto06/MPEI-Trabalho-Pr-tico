function conjunto = discretizar_dia(x, data)
% DISCRETIZAR_DIA Converte um registo meteorológico num conjunto de tokens discretos.
%
%   conjunto = discretizar_dia(x)
%   conjunto = discretizar_dia(x, data)
%
%   x    : linha de tabela, cell array ou vetor numérico (sem coluna 'weather' no treino)
%   data : (opcional) string/datetime com a data, ex: '2000-01-01'
%
%   Devolve um cell array de strings com os tokens discretizados.

    % ------------------------------------------------------------------ %
    %  1. NORMALIZAÇÃO DO INPUT                                            %
    % ------------------------------------------------------------------ %
    weather = [];  % default: sem label (modo previsão)

    if istable(x)
        % Extrai a data da tabela se não for fornecida externamente
        if any(strcmp(x.Properties.VariableNames, 'date'))
            if nargin < 2 || isempty(data)
                data = x.date(1);
            end
            x = removevars(x, 'date');
        end
        % Extrai weather antes de converter (é string/categorical)
        if any(strcmp(x.Properties.VariableNames, 'weather'))
            weather = x.weather(1);
            x = removevars(x, 'weather');
        end
        x = table2array(x);   % agora é só numérico → vetor de doubles
    end

    if iscell(x)
        % Cell array: últimos elementos podem ser strings
        % Ordem esperada: precipitation,temp_max,temp_min,wind,
        %                 snow_depth,temp_range,month_sin,month_cos,tsun,wsf2[,weather]
        precipitation = x{1};
        temp_max      = x{2};
        temp_min      = x{3};
        wind          = x{4};
        snow_depth    = x{5};
        temp_range    = x{6};
        month_sin     = x{7};
        month_cos     = x{8};
        tsun          = x{9};
        wsf2          = x{10};
        if length(x) >= 11 && isempty(weather)
            weather = x{11};
        end
    else
        % Vetor numérico puro (caso mais comum no treino/teste)
        precipitation = x(1);
        temp_max      = x(2);
        temp_min      = x(3);
        wind          = x(4);
        snow_depth    = x(5);
        temp_range    = x(6);
        month_sin     = x(7);
        month_cos     = x(8);
        tsun          = x(9);
        wsf2          = x(10);
        % weather NÃO vem no vetor numérico (é string)
    end

    conjunto = {};

    % ------------------------------------------------------------------ %
    %  2. DISCRETIZAÇÃO DAS FEATURES                                      %
    % ------------------------------------------------------------------ %

    % --- temp_max (°C) ---
    if temp_max < 5
        conjunto{end+1} = 'tmax_FRIA';
    elseif temp_max < 15
        conjunto{end+1} = 'tmax_AMENA';
    elseif temp_max < 25
        conjunto{end+1} = 'tmax_QUENTE';
    else
        conjunto{end+1} = 'tmax_MUITO_QUENTE';
    end

    % --- temp_min (°C) ---
    if temp_min < 0
        conjunto{end+1} = 'tmin_GELADA';
    elseif temp_min < 10
        conjunto{end+1} = 'tmin_FRESCA';
    else
        conjunto{end+1} = 'tmin_MORNA';
    end

    % --- precipitation (mm) ---
    if precipitation == 0
        conjunto{end+1} = 'precip_NULA';
    elseif precipitation < 2
        conjunto{end+1} = 'precip_FRACA';
    elseif precipitation < 10
        conjunto{end+1} = 'precip_MODERADA';
    else
        conjunto{end+1} = 'precip_FORTE';
    end

    % --- wind (m/s) ---
    if wind < 3
        conjunto{end+1} = 'vento_FRACO';
    elseif wind < 7
        conjunto{end+1} = 'vento_MODERADO';
    else
        conjunto{end+1} = 'vento_FORTE';
    end

    % --- snow_depth (cm) ---
    if snow_depth == 0
        conjunto{end+1} = 'neve_NULA';
    elseif snow_depth < 5
        conjunto{end+1} = 'neve_LEVE';
    else
        conjunto{end+1} = 'neve_INTENSA';
    end

    % --- temp_range (°C) ---
    if temp_range < 5
        conjunto{end+1} = 'amplitude_BAIXA';
    elseif temp_range < 10
        conjunto{end+1} = 'amplitude_MEDIA';
    else
        conjunto{end+1} = 'amplitude_ALTA';
    end

    % --- month_sin (sinal cíclico do mês) ---
    if month_sin < -0.5
        conjunto{end+1} = 'msin_NEGATIVO';
    elseif month_sin <= 0.5
        conjunto{end+1} = 'msin_NEUTRO';
    else
        conjunto{end+1} = 'msin_POSITIVO';
    end

    % --- month_cos (coseno cíclico do mês) ---
    if month_cos < -0.5
        conjunto{end+1} = 'mcos_NEGATIVO';
    elseif month_cos <= 0.5
        conjunto{end+1} = 'mcos_NEUTRO';
    else
        conjunto{end+1} = 'mcos_POSITIVO';
    end

    % --- tsun (horas de sol) ---
    if tsun == 0
        conjunto{end+1} = 'tsun_NULA';
    elseif tsun < 4
        conjunto{end+1} = 'tsun_BAIXA';
    elseif tsun < 8
        conjunto{end+1} = 'tsun_MEDIA';
    else
        conjunto{end+1} = 'tsun_ALTA';
    end

    % --- wsf2 (rajada máxima de vento, m/s) ---
    if wsf2 < 5
        conjunto{end+1} = 'wsf2_FRACO';
    elseif wsf2 < 10
        conjunto{end+1} = 'wsf2_MODERADO';
    else
        conjunto{end+1} = 'wsf2_FORTE';
    end

    % ------------------------------------------------------------------ %
    %  3. WEATHER (só incluído quando disponível — fase de treino)        %
    % ------------------------------------------------------------------ %
    if ~isempty(weather)
        if isnumeric(weather) || islogical(weather)
            nomes = {'weather_drizzle','weather_fog','weather_rain', ...
                     'weather_snow','weather_sun'};
            idx = round(double(weather));
            if idx >= 1 && idx <= numel(nomes)
                conjunto{end+1} = nomes{idx};
            end
        elseif iscategorical(weather)
            conjunto{end+1} = ['weather_', char(string(weather))];
        else
            conjunto{end+1} = ['weather_', strtrim(char(weather))];
        end
    end

    % ------------------------------------------------------------------ %
    %  4. MÊS EXPLÍCITO (só se data fornecida externamente)              %
    %     Omitido por defeito — month_sin/cos já codificam a sazonalidade %
    % ------------------------------------------------------------------ %
    if nargin >= 2 && ~isempty(data)
        meses = {'mes_JAN','mes_FEV','mes_MAR','mes_ABR','mes_MAI','mes_JUN', ...
                 'mes_JUL','mes_AGO','mes_SET','mes_OUT','mes_NOV','mes_DEZ'};
        if ischar(data) || isstring(data)
            data = datetime(data, 'InputFormat', 'yyyy-MM-dd');
        elseif iscell(data)
            data = datetime(data{1}, 'InputFormat', 'yyyy-MM-dd');
        end
        conjunto{end+1} = meses{month(data)};
    end
end