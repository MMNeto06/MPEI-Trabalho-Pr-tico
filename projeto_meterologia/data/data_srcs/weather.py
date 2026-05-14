import sys
import csv
import datetime

sys.stdout.reconfigure(newline='')  # ← adiciona esta linha

reader = csv.reader(sys.stdin)
headers = next(reader)

# ---------------------------------------------------------------------------
# NOAA Weather Type → categoria (ordem de prioridade crescente;
# o último match ganha — mais severo prevalece)
# ---------------------------------------------------------------------------
# Categoria  | Códigos WT
# -----------+--------------------------------------------------------------
# fog        | WT01 Fog/ice fog/freezing fog
#            | WT02 Heavy fog / heavy freezing fog
#            | WT21 Ground fog
#            | WT22 Ice fog or freezing fog
# -----------+--------------------------------------------------------------
# drizzle    | WT08 Smoke or haze
#            | WT13 Mist
#            | WT14 Drizzle
# -----------+--------------------------------------------------------------
# rain       | WT03 Thunder
#            | WT05 Hail (may include small hail)
#            | WT16 Rain (may include freezing rain / drizzle)
#            | WT17 Freezing rain
#            | WT19 Unknown source of precipitation
#            | PRCP > 0
# -----------+--------------------------------------------------------------
# snow       | WT04 Ice pellets, sleet, snow pellets, or small hail
#            | WT06 Glaze or rime
#            | WT09 Blowing or drifting snow
#            | WT18 Snow, snow pellets, snow grains, or ice crystals
#            | SNOW > 0
# -----------+--------------------------------------------------------------
# (WT07 Dust/volcanic ash, WT10 Tornado/waterspout, WT11 High winds
#  não alteram a categoria de precipitação — ficam em 'sun' se mais nada)
# ---------------------------------------------------------------------------

FOG_TYPES     = {'WT01', 'WT02', 'WT21', 'WT22'}
DRIZZLE_TYPES = {'WT08', 'WT13', 'WT14'}
RAIN_TYPES    = {'WT03', 'WT05', 'WT16', 'WT17', 'WT19'}
SNOW_TYPES    = {'WT04', 'WT06', 'WT09', 'WT18'}


def safe_float(value, default=0.0):
    """Converte para float sem falhar em strings vazias ou mal formatadas."""
    try:
        return float(str(value).strip())
    except (ValueError, TypeError):
        return default


def wt_active(row_dict, code):
    """Devolve True se o weather type estiver activo (valor '1'), mesmo que
    a coluna não exista ou o valor tenha espaços extra."""
    return str(row_dict.get(code, '')).strip() == '1'


def classify_weather(d):
    weather = 'sun'

    if any(wt_active(d, wt) for wt in FOG_TYPES):
        weather = 'fog'

    if any(wt_active(d, wt) for wt in DRIZZLE_TYPES):
        weather = 'drizzle'

    if any(wt_active(d, wt) for wt in RAIN_TYPES) or safe_float(d.get('PRCP')) > 0:
        weather = 'rain'

    if any(wt_active(d, wt) for wt in SNOW_TYPES) or safe_float(d.get('SNOW')) > 0:
        weather = 'snow'

    return weather


def parse_date(raw):
    """Aceita YYYYMMDD e YYYY-MM-DD."""
    raw = raw.strip()
    for fmt in ('%Y%m%d', '%Y-%m-%d'):
        try:
            return datetime.datetime.strptime(raw, fmt).strftime('%Y-%m-%d')
        except ValueError:
            continue
    return raw  # devolve tal qual se o formato for desconhecido


names = ['DATE', 'PRCP', 'TMAX', 'TMIN', 'AWND', 'WEATHER']
sys.stdout.write('date,precipitation,temp_max,temp_min,wind,weather\n')

writer = csv.DictWriter(sys.stdout, fieldnames=names, extrasaction='ignore')

for row in reader:
    d = dict(zip(headers, row))

    d['WEATHER'] = classify_weather(d)
    d['DATE']    = parse_date(d.get('DATE', ''))

    # Os valores podem já ser float (formato NOAA web) ou inteiros em décimas
    # (formato NOAA legacy). safe_float lida com ambos; a divisão por 10
    # só se aplica se os valores forem claramente inteiros em décimas
    # (ex.: AWND=29 em vez de 2.9). Detecta pelo cabeçalho original.
    awnd_raw = safe_float(d.get('AWND'))
    tmax_raw = safe_float(d.get('TMAX'))
    tmin_raw = safe_float(d.get('TMIN'))
    prcp_raw = safe_float(d.get('PRCP'))

    d['AWND'] = awnd_raw
    d['TMAX'] = tmax_raw
    d['TMIN'] = tmin_raw
    d['PRCP'] = prcp_raw

    writer.writerow(d)