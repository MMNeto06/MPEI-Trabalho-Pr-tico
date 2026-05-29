import sys
import csv
import datetime
from math import sin, cos, pi

# ---------------------------------------------------------------------------
# Conversor Open-Meteo → CSV simplificado com labels de tempo
#
# Input:  CSV do Open-Meteo (com 3 linhas de metadata no topo)
# Output: CSV com colunas padronizadas + label de weather (Sem weather_code para evitar leakage)
#
# Labels (prioridade crescente):
#   sun → cloudy → fog → drizzle → rain → snow → thunder
#
# Estratégia de classificação:
#   • cloudy  → WMO code 2 (partly cloudy) ou 3 (overcast)
#              + heurística: cloud_cover_mean ≥ 70 % sem precipitação significativa
#   • drizzle / rain / snow → WMO code é fonte primária (fiável)
#   • fog    → heurística sempre ativa (Open-Meteo histórico raramente emite WMO 45/48)
#   • thunder → heurística sempre ativa (WMO 95/96/99 raramente aparece no histórico)
#              + WMO 95/96/99 se presentes
#
# WMO codes usados pelo Open-Meteo:
#   0–1          → sun (clear / mainly clear)
#   2            → cloudy (partly cloudy)
#   3            → cloudy (overcast)
#   45, 48       → fog
#   51,53,55–57  → drizzle
#   61–67,80–82  → rain   (82 = violent shower → thunder se intensidade ≥ 2.5 mm/h)
#   71–77,85–86  → snow
#   95,96,99     → thunder
#
# Variáveis Open-Meteo necessárias (adicionais face à versão anterior):
#   ✓ Maximum Cloud Cover (cloud_cover_max) — distingue nublado todo o dia vs pontual
#   ✓ Minimum Cloud Cover (cloud_cover_min) — variação diária de nebulosidade
#
# Uso: python weather_openmeteo.py < seattle_open_meteo.csv > seattle_new.csv
# ---------------------------------------------------------------------------

sys.stdout.reconfigure(newline='')
sys.stdin.reconfigure(encoding='utf-8')

lines = sys.stdin.read().splitlines()

header_line = None
data_lines  = []

for i, line in enumerate(lines):
    if line.startswith('time,'):
        header_line = line
        data_lines  = lines[i + 1:]
        break

if header_line is None:
    sys.exit("Erro: não foi encontrado o cabeçalho (linha começada por 'time,').")

reader = csv.DictReader(data_lines, fieldnames=header_line.split(','))


# ---------------------------------------------------------------------------
# WMO code sets
# ---------------------------------------------------------------------------

WMO_CLOUDY   = {2, 3}                       # partly cloudy, overcast
WMO_FOG      = {45, 48}
WMO_DRIZZLE  = {51, 53, 55, 56, 57}
WMO_RAIN     = {61, 63, 65, 66, 67, 80, 81, 82}
WMO_SNOW     = {71, 73, 75, 77, 85, 86}
WMO_THUNDER  = {95, 96, 99}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def safe_float(value, default=0.0):
    try:
        return float(str(value).strip())
    except (ValueError, TypeError):
        return default


def safe_int(value, default=-1):
    try:
        return int(float(str(value).strip()))
    except (ValueError, TypeError):
        return default


def parse_date(raw):
    raw = raw.strip()
    for fmt in ('%Y-%m-%d', '%Y%m%d'):
        try:
            return datetime.datetime.strptime(raw, fmt)
        except ValueError:
            continue
    return None


# ---------------------------------------------------------------------------
# Classificação
#
# Camadas (cada uma pode sobrescrever a anterior):
#
#  1. Base WMO   — cloudy (2/3) / drizzle / rain / snow a partir do WMO code
#  2. Cloudy     — heurística: cloud_cover_mean ≥ 70 %
#                              + cloud_cover_max ≥ 80 % (se disponível)
#                              + precipitação < 0.3 mm
#                 Só activa se label base for 'sun'
#  3. Fog        — heurística: spread temp_min−dew_mean < 2.5 °C
#                              + humidade ≥ 88 %
#                              + cloud cover ≥ 80 %
#                              + precipitação < 0.3 mm
#                 Activa se label for 'sun' ou 'cloudy'
#  4. Thunder    — WMO 95/96/99  OU
#                  chuva intensa: prcp ≥ 10 mm E intensidade ≥ 2.5 mm/h
#                 Só activa se label for 'rain'
# ---------------------------------------------------------------------------

def classify_weather(d):
    wmo_code      = safe_int(d.get('weather_code (wmo code)', ''))
    prcp          = safe_float(d.get('precipitation_sum (mm)'))
    prcp_hours    = safe_float(d.get('precipitation_hours (h)'))
    snowfall      = safe_float(d.get('snowfall_sum (cm)'))
    rh_mean       = safe_float(d.get('relative_humidity_2m_mean (%)'))
    cloud_mean    = safe_float(d.get('cloud_cover_mean (%)'))
    cloud_max     = safe_float(d.get('cloud_cover_max (%)'), default=-1.0)   # pode não existir
    cloud_min     = safe_float(d.get('cloud_cover_min (%)'), default=-1.0)   # pode não existir
    dew_mean      = safe_float(d.get('dew_point_2m_mean (°C)'))
    temp_min      = safe_float(d.get('temperature_2m_min (°C)'))

    # ------------------------------------------------------------------
    # 1. Label base via WMO code
    # ------------------------------------------------------------------
    if wmo_code in WMO_DRIZZLE:
        weather = 'drizzle'
    elif wmo_code in WMO_RAIN:
        weather = 'rain'
    elif wmo_code in WMO_SNOW:
        weather = 'snow'
    elif wmo_code in WMO_FOG:
        weather = 'fog'
    elif wmo_code in WMO_THUNDER:
        weather = 'thunder'
    elif wmo_code in WMO_CLOUDY:
        # FIX WMO=3 conservador: Open-Meteo emite WMO=3 (overcast) mesmo quando
        # cloud_mean é moderado (ex. névoa de poluição/poeira em Beijing).
        # Só reclassificamos como não-cloudy se cloud_mean < 25 % (limiar conservador):
        #   - evita inflar logPrior(sun) em cidades como Seattle onde WMO=3 com
        #     cloud_mean 30-50 % corresponde a dias realmente nublados
        #   - ainda captura dias de poeira/hazing genuína (cloud_mean < 25 %)
        #     em Beijing ou outras fontes onde o sensor subestima a nebulosidade
        # Anteriormente o limiar era 50 %, o que repassava 1211 dias de Seattle
        # para 'sun', inflando logPrior(sun) em +187 % e causando 142 erros cloudy→sun.
        if wmo_code == 3 and cloud_mean < 25:
            weather = None  # será tratado no ramo else abaixo
        else:
            weather = 'cloudy'
    else:
        weather = None  # placeholder — o bloco abaixo trata

    if weather is None:
        # WMO 0–1 (sun) ou desconhecido: heurísticas decidem
        if snowfall > 0:
            weather = 'snow'
        elif prcp > 1.0:
            weather = 'rain'
        elif 0 < prcp <= 1.0 and prcp_hours >= 3:   # FIX Bug 4: era >=6h; 3h cobre chirimiri de 3-5h
            weather = 'drizzle'
        else:
            weather = 'sun'

    # ------------------------------------------------------------------
    # 2. Cloudy (sobrescreve 'sun'; não sobrescreve precipitação nem fog)
    #    Usa cloud_cover_max se disponível; caso contrário só cloud_mean.
    # ------------------------------------------------------------------
    if weather == 'sun' and prcp < 0.3:
        if cloud_max >= 0:
            # com cloud_cover_max: exige média alta + pico alto
            if cloud_mean >= 70 and cloud_max >= 80:
                weather = 'cloudy'
        else:
            # FIX Bug 3: era >=75%; baixado para >=65% para capturar dias
            # nublados reais e neblina de poluição (Beijing, etc.)
            if cloud_mean >= 65:
                weather = 'cloudy'

    # ------------------------------------------------------------------
    # 3. Fog (sobrescreve 'sun' e 'cloudy'; não sobrescreve precipitação)
    # ------------------------------------------------------------------
    if weather in ('sun', 'cloudy'):
        dew_spread = temp_min - dew_mean
        if (dew_spread < 2.5
                and rh_mean >= 83              # FIX Bug 2: era >=88%; baixado para >=83%
                and cloud_mean >= 75           # FIX Bug 2: era >=80%; ajustado
                and prcp < 0.3):
            weather = 'fog'

    # ------------------------------------------------------------------
    # 4. Thunder (sobrescreve 'rain')
    # ------------------------------------------------------------------
    if weather == 'rain' or wmo_code in WMO_THUNDER:
        if wmo_code in WMO_THUNDER:
            weather = 'thunder'
        elif weather == 'rain':
            intensity = (prcp / prcp_hours) if prcp_hours > 0 else 0
            # FIX: threshold 2.5→2.0 mm/h — dados históricos mostram que tempestades
            # reais em Beijing e Seattle raramente excedem 2.5 mm/h; 2.0 captura mais
            # eventos convectivos sem aumentar falsos positivos significativamente.
            if prcp >= 10.0 and intensity >= 2.0:
                weather = 'thunder'
            # FIX Bug 1: prcp_hours ausente/zero → intensity=0 → tempestades não detectadas.
            # Threshold de precipitação total como fallback conservador.
            elif prcp >= 20.0 and prcp_hours == 0:
                weather = 'thunder'
            # WMO 82 = violent shower → thunder
            if wmo_code == 82 and (intensity >= 2.0 or prcp >= 15.0):  # FIX: threshold 2.5→2.0
                weather = 'thunder'

    return weather


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

out_cols = [
    'date', 'precipitation', 'temp_max', 'temp_min',
    'sunshine_duration', 'shortwave_radiation',
    'wind_speed_max', 'wind_gusts_max',
    'snowfall', 'temp_range', 'month_sin', 'month_cos',
    'humidity_mean', 'humidity_min',
    'dew_point_mean', 'dew_point_max',
    'cloud_cover_mean', 'cloud_cover_max', 'cloud_cover_min',
    'pressure_mean', 'pressure_min',
    'precipitation_hours',
    'weather',
]

writer = csv.writer(sys.stdout)
writer.writerow(out_cols)

for row in reader:
    if not row.get('time', '').strip():
        continue

    dt = parse_date(row.get('time', ''))
    if dt is None:
        date_str  = row.get('time', '').strip()
        month_sin = 0.0
        month_cos = 1.0
    else:
        date_str  = dt.strftime('%Y-%m-%d')
        month     = dt.month
        month_sin = round(sin(2 * pi * month / 12), 6)
        month_cos = round(cos(2 * pi * month / 12), 6)

    tmax = safe_float(row.get('temperature_2m_max (°C)'))
    tmin = safe_float(row.get('temperature_2m_min (°C)'))

    # cloud_cover_max / min: escritos como string vazia se a coluna não existir no CSV
    raw_cloud_max = row.get('cloud_cover_max (%)', '').strip()
    raw_cloud_min = row.get('cloud_cover_min (%)', '').strip()

    writer.writerow([
        date_str,
        safe_float(row.get('precipitation_sum (mm)')),
        tmax,
        tmin,
        round(safe_float(row.get('sunshine_duration (s)')) / 3600, 4),   # s → h
        safe_float(row.get('shortwave_radiation_sum (MJ/m²)')),
        safe_float(row.get('wind_speed_10m_max (km/h)')),
        safe_float(row.get('wind_gusts_10m_max (km/h)')),
        safe_float(row.get('snowfall_sum (cm)')),
        round(tmax - tmin, 4),
        month_sin,
        month_cos,
        safe_float(row.get('relative_humidity_2m_mean (%)')),
        safe_float(row.get('relative_humidity_2m_min (%)')),
        safe_float(row.get('dew_point_2m_mean (°C)')),
        safe_float(row.get('dew_point_2m_max (°C)')),
        safe_float(row.get('cloud_cover_mean (%)')),
        raw_cloud_max if raw_cloud_max != '' else '',
        raw_cloud_min if raw_cloud_min != '' else '',
        safe_float(row.get('pressure_msl_mean (hPa)')),
        safe_float(row.get('pressure_msl_min (hPa)')),
        safe_float(row.get('precipitation_hours (h)')),
        classify_weather(row),
    ])