import sys
import csv
import datetime
from math import sin, cos, pi

sys.stdout.reconfigure(newline='')

reader = csv.reader(sys.stdin)
headers = next(reader)

# ---------------------------------------------------------------------------
# NOAA Weather Type → categoria (ordem de prioridade crescente;
# o último match ganha — mais severo prevalece)
# ---------------------------------------------------------------------------
# fog        | WT01 WT02 WT08 WT21 WT22
# drizzle    | WT13 WT14
# rain       | WT03 WT05 WT16 WT17 WT19 | PRCP > 0
# snow       | WT04 WT06 WT09 WT18      | SNOW > 0 | SNWD > 0
# ---------------------------------------------------------------------------

FOG_TYPES     = {'WT01', 'WT02', 'WT08', 'WT21', 'WT22'}
DRIZZLE_TYPES = {'WT13', 'WT14'}
RAIN_TYPES    = {'WT03', 'WT05', 'WT16', 'WT17', 'WT19'}
SNOW_TYPES    = {'WT04', 'WT06', 'WT09', 'WT18'}


def safe_float(value, default=0.0):
    try:
        return float(str(value).strip())
    except (ValueError, TypeError):
        return default


def wt_active(row_dict, code):
    return str(row_dict.get(code, '')).strip() == '1'


def classify_weather(d):
    weather = 'sun'
    if any(wt_active(d, wt) for wt in FOG_TYPES):
        weather = 'fog'
    if any(wt_active(d, wt) for wt in DRIZZLE_TYPES):
        weather = 'drizzle'
    if any(wt_active(d, wt) for wt in RAIN_TYPES) or safe_float(d.get('PRCP')) > 0:
        weather = 'rain'
    if any(wt_active(d, wt) for wt in SNOW_TYPES) \
            or safe_float(d.get('SNOW')) > 0 \
            or safe_float(d.get('SNWD')) > 0:
        weather = 'snow'
    return weather


def parse_date(raw):
    raw = raw.strip()
    for fmt in ('%Y%m%d', '%Y-%m-%d'):
        try:
            return datetime.datetime.strptime(raw, fmt)
        except ValueError:
            continue
    return None


# ---------------------------------------------------------------------------
# Detectar colunas opcionais (TSUN e WSF2 só existem em certas estações NOAA)
# O cabeçalho de saída é construído dinamicamente para evitar desalinhamentos.
# ---------------------------------------------------------------------------
TEM_TSUN = 'TSUN' in headers
TEM_WSF2 = 'WSF2' in headers

colunas_base  = ['date', 'precipitation', 'temp_max', 'temp_min', 'wind',
                 'snow_depth', 'temp_range', 'month_sin', 'month_cos']
colunas_extra = (['tsun'] if TEM_TSUN else []) + (['wsf2'] if TEM_WSF2 else [])
todas_colunas = colunas_base + colunas_extra + ['weather']

sys.stdout.write(','.join(todas_colunas) + '\n')

writer = csv.writer(sys.stdout)

for row in reader:
    d = dict(zip(headers, row))

    weather  = classify_weather(d)
    dt       = parse_date(d.get('DATE', ''))

    if dt is None:
        date_str  = d.get('DATE', '').strip()
        month_sin = 0.0
        month_cos = 1.0
    else:
        date_str  = dt.strftime('%Y-%m-%d')
        month     = dt.month
        month_sin = round(sin(2 * pi * month / 12), 6)
        month_cos = round(cos(2 * pi * month / 12), 6)

    tmax_raw = safe_float(d.get('TMAX'))
    tmin_raw = safe_float(d.get('TMIN'))

    linha = [
        date_str,
        safe_float(d.get('PRCP')),
        tmax_raw,
        tmin_raw,
        safe_float(d.get('AWND')),
        safe_float(d.get('SNWD')),
        round(tmax_raw - tmin_raw, 4),   # temp_range
        month_sin,
        month_cos,
    ]

    if TEM_TSUN:
        linha.append(safe_float(d.get('TSUN')))
    if TEM_WSF2:
        linha.append(safe_float(d.get('WSF2')))

    linha.append(weather)
    writer.writerow(linha)