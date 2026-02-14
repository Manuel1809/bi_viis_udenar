import csv
import re
from pathlib import Path
from collections import defaultdict

# Rutas según tu estructura real
SCRIPTS = Path(r"D:\Manuel\Documents\Maestria\scripts")
REPORTS = SCRIPTS / "reports_core"

COLUMNS = REPORTS / "columns.csv"
FACTS   = REPORTS / "fact_candidates.csv"
OUT     = REPORTS / "fact_signals_summary.csv"

# Tipos numéricos típicos en MySQL (se comparan por prefijo)
NUMERIC_PREFIX = ("int", "bigint", "smallint", "tinyint", "decimal", "numeric", "double", "float", "real")
DATE_HINT = re.compile(r"(^fec_)|(_fec_)|(^fecha)|(_fecha)|time|date|timestamp|datetime", re.IGNORECASE)

def is_numeric(dt: str) -> bool:
    d = (dt or "").lower()
    return d.startswith(NUMERIC_PREFIX)

def is_date(dt: str, col: str) -> bool:
    d = (dt or "").lower()
    c = (col or "").lower()
    return ("date" in d or "time" in d or "timestamp" in d or "datetime" in d) or bool(DATE_HINT.search(c))

def is_ide(col: str) -> bool:
    return (col or "").lower().startswith("ide_")

def is_value_measure(col: str) -> bool:
    c = (col or "").lower()
    return (
        c.startswith("val_") or
        c.startswith("monto") or
        c.startswith("valor") or
        c.startswith("total") or
        c.endswith("_tot") or
        c.startswith("saldo") or
        c.startswith("cant")
    )

# 1) cargar lista de tablas fact candidatas
fact_tables = []
with FACTS.open("r", encoding="utf-8-sig") as f:
    r = csv.DictReader(f)
    # intenta detectar el nombre de la columna que trae la tabla
    fieldnames = [x.lower() for x in (r.fieldnames or [])]
    if "table_name" in fieldnames:
        key = r.fieldnames[fieldnames.index("table_name")]
    elif "table" in fieldnames:
        key = r.fieldnames[fieldnames.index("table")]
    else:
        raise ValueError(f"No encuentro columna table_name/table en {FACTS}. Header={r.fieldnames}")

    for row in r:
        fact_tables.append((row.get(key) or "").strip())

fact_tables = list(dict.fromkeys([t for t in fact_tables if t]))  # unique, preserve order
fact_set = set(fact_tables)

# 2) indexar columnas por tabla
cols_by_table = defaultdict(list)
with COLUMNS.open("r", encoding="utf-8-sig") as f:
    r = csv.DictReader(f)
    fieldnames = [x.lower() for x in (r.fieldnames or [])]

    # detectar nombres esperados
    def pick(*cands):
        for c in cands:
            if c in fieldnames:
                return r.fieldnames[fieldnames.index(c)]
        return None

    tkey = pick("table_name", "table", "tabla")
    ckey = pick("column_name", "column", "columna", "field")
    dkey = pick("data_type", "type", "tipo", "column_type")

    if not (tkey and ckey):
        raise ValueError(f"No encuentro columnas table/column en {COLUMNS}. Header={r.fieldnames}")

    for row in r:
        t = (row.get(tkey) or "").strip()
        if t not in fact_set:
            continue
        col = (row.get(ckey) or "").strip()
        dt  = (row.get(dkey) or "").strip() if dkey else ""
        cols_by_table[t].append((col, dt))

# 3) construir resumen
rows = []
for t in fact_tables:
    cols = cols_by_table.get(t, [])
    ide_cols   = sorted({c for c, _ in cols if is_ide(c)})
    date_cols  = sorted({c for c, dt in cols if is_date(dt, c)})
    num_cols   = sorted({c for c, dt in cols if is_numeric(dt)})
    val_cols   = sorted({c for c, _ in cols if is_value_measure(c)})

    rows.append({
        "table_name": t,
        "col_count": len(cols),
        "n_ide": len(ide_cols),
        "n_date": len(date_cols),
        "n_numeric": len(num_cols),
        "n_value_measures": len(val_cols),
        "ide_cols": ";".join(ide_cols),
        "date_cols": ";".join(date_cols),
        "numeric_cols": ";".join(num_cols),
        "value_measures": ";".join(val_cols),
    })

# 4) guardar
with OUT.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(
        f,
        fieldnames=[
            "table_name", "col_count", "n_ide", "n_date", "n_numeric", "n_value_measures",
            "ide_cols", "date_cols", "numeric_cols", "value_measures"
        ]
    )
    w.writeheader()
    w.writerows(rows)

print(f"OK: {OUT} ({len(rows)} tablas)")
