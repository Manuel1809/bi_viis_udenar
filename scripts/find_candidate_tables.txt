import csv
from pathlib import Path

TABLES_CSV = Path(r"D:\Manuel\Documents\Maestria\scripts\tables.csv")  # tu tables.csv (baseline)
OUT = Path("candidate_tables.csv")

KEYWORDS = [
    "proy", "proyecto",
    "inv", "investig",
    "facul", "depen", "unidad", "program",
    "pres", "presup", "rubro", "gasto", "ejec",
    "convoc",
    "estu", "estud", "alumn",
    "grupo", "linea",
    "producto", "public", "articulo",
    "usuario", "rol", "permiso",
]

def hit(name: str) -> bool:
    n = name.lower()
    return any(k in n for k in KEYWORDS)

rows = []
with TABLES_CSV.open("r", encoding="utf-8") as f:
    r = csv.DictReader(f)
    for row in r:
        t = row["table_name"]
        if hit(t):
            rows.append([t])

rows.sort(key=lambda x: x[0].lower())

with OUT.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["table_name"])
    w.writerows(rows)

print(f"OK: {len(rows)} tablas candidatas -> {OUT.resolve()}")
