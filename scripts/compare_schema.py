import re
import csv
from pathlib import Path

# ====== CONFIGURA AQUÍ ======
DUMP_A = Path(r"D:\Manuel\Documents\Maestria\Bases de datos\2025\31-12-2025.sql")
DUMP_B = Path(r"D:\Manuel\Documents\Maestria\Bases de datos\2025\30-11-2025.sql")
LABEL  = "2025-11_vs_2025-12"

# ============================

def extract(dump_path: Path):
    create_table_re = re.compile(r"^CREATE TABLE\s+`(?P<table>[^`]+)`\s*\(", re.IGNORECASE)
    column_re = re.compile(r"^\s*`(?P<col>[^`]+)`\s+(?P<type>[^\s,]+)", re.IGNORECASE)
    end_table_re = re.compile(r"^\)\s*ENGINE=", re.IGNORECASE)

    tables = set()
    columns = set()  # (table, col, type)

    current_table = None
    in_create = False

    with dump_path.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            m = create_table_re.match(line)
            if m:
                current_table = m.group("table")
                tables.add(current_table)
                in_create = True
                continue

            if in_create and current_table:
                cm = column_re.match(line)
                if cm:
                    columns.add((current_table, cm.group("col"), cm.group("type")))

                if end_table_re.search(line):
                    current_table = None
                    in_create = False

    return tables, columns

def save_csv(path: Path, header, rows):
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        for r in rows:
            w.writerow(r if isinstance(r, (list, tuple)) else [r])

tables_a, cols_a = extract(DUMP_A)
tables_b, cols_b = extract(DUMP_B)

tables_added = sorted(tables_a - tables_b)
tables_removed = sorted(tables_b - tables_a)

cols_added = sorted(cols_a - cols_b)       # (table, col, type) en A pero no en B
cols_removed = sorted(cols_b - cols_a)     # en B pero no en A

out_tables = Path(f"schema_diff_tables__{LABEL}.csv")
out_cols   = Path(f"schema_diff_columns__{LABEL}.csv")

save_csv(out_tables, ["change", "table_name"],
         [["ADDED", t] for t in tables_added] + [["REMOVED", t] for t in tables_removed])

save_csv(out_cols, ["change", "table_name", "column_name", "data_type"],
         [["ADDED", *c] for c in cols_added] + [["REMOVED", *c] for c in cols_removed])

print(f"A (baseline):  {len(tables_a)} tablas, {len(cols_a)} columnas")
print(f"B (comparado): {len(tables_b)} tablas, {len(cols_b)} columnas")
print(f"Tablas ADDED: {len(tables_added)} | Tablas REMOVED: {len(tables_removed)}")
print(f"Columnas ADDED: {len(cols_added)} | Columnas REMOVED: {len(cols_removed)}")
print(f"OK: {out_tables.name} y {out_cols.name}")
