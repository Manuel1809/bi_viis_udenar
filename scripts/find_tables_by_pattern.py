import csv
from pathlib import Path

# Ruta real donde está tu inventario de tablas
ROOT = Path(r"D:\Manuel\Documents\Maestria\scripts\reports_core")
TABLES = ROOT / "tables.csv"

# Patrones para ubicar nombres reales en el esquema (sin inventar)
PATTERNS = ["cdp", "comprom", "imputacion", "rp", "registro", "presup", "rubro"]

def detect_table_name_field(fieldnames):
    if not fieldnames:
        return None
    lower = [h.lower().strip() for h in fieldnames]
    for cand in ["table_name", "table", "tabla", "name"]:
        if cand in lower:
            return fieldnames[lower.index(cand)]
    return None

def main():
    if not TABLES.exists():
        raise FileNotFoundError(f"No existe: {TABLES}")

    matches = set()

    with TABLES.open("r", encoding="utf-8-sig", newline="") as f:
        r = csv.DictReader(f)
        key = detect_table_name_field(r.fieldnames)
        if not key:
            raise ValueError(f"No encuentro columna con nombre de tabla en {TABLES}. Header={r.fieldnames}")

        for row in r:
            t = (row.get(key) or "").strip()
            if not t:
                continue
            lt = t.lower()
            if any(p in lt for p in PATTERNS):
                matches.add(t)

    print("Coincidencias encontradas en tables.csv:")
    for t in sorted(matches):
        print("-", t)

if __name__ == "__main__":
    main()
