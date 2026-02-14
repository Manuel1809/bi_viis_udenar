import re
import csv
from pathlib import Path


DUMP_PATH = Path(r"D:\Manuel\Documents\Maestria\Bases de datos\2025\31-12-2025.sql")

# Archivos de salida
OUT_TABLES = Path("tables.csv")
OUT_COLUMNS = Path("columns.csv")

create_table_re = re.compile(r"^CREATE TABLE\s+`(?P<table>[^`]+)`\s*\(", re.IGNORECASE)
column_re = re.compile(r"^\s*`(?P<col>[^`]+)`\s+(?P<type>[^\s,]+)", re.IGNORECASE)
end_table_re = re.compile(r"^\)\s*ENGINE=", re.IGNORECASE)

tables = []
columns = []

current_table = None
in_create = False

with DUMP_PATH.open("r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        m = create_table_re.match(line)
        if m:
            current_table = m.group("table")
            tables.append(current_table)
            in_create = True
            continue

        if in_create and current_table:
            # Captura columnas (líneas tipo: `campo` varchar(255) NOT NULL, ...)
            cm = column_re.match(line)
            if cm:
                columns.append([current_table, cm.group("col"), cm.group("type")])

            # Fin del CREATE TABLE
            if end_table_re.search(line):
                current_table = None
                in_create = False

# Guardar tablas
with OUT_TABLES.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["table_name"])
    for t in sorted(set(tables)):
        w.writerow([t])

# Guardar columnas
with OUT_COLUMNS.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["table_name", "column_name", "data_type"])
    for row in columns:
        w.writerow(row)

print(f"OK: {len(set(tables))} tablas -> {OUT_TABLES.resolve()}")
print(f"OK: {len(columns)} columnas -> {OUT_COLUMNS.resolve()}")
