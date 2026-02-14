import pandas as pd
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
COLUMNS = BASE_DIR / "columns.csv"
OUT_DIR = BASE_DIR / "reports_core"
OUT_DIR.mkdir(exist_ok=True)

df = pd.read_csv(COLUMNS)
df["col"] = df["column_name"].str.lower()

ide = df[df["col"].str.startswith("ide_")].copy()

# 1) Frecuencia de cada ide_* (en cuántas tablas aparece)
freq = (ide.groupby("col")["table_name"]
        .nunique()
        .sort_values(ascending=False)
        .reset_index())
freq.columns = ["ide_key", "table_count"]
freq.to_csv(OUT_DIR / "ide_key_frequency.csv", index=False)

# 2) Lista completa ide_key -> tabla
pairs = ide[["col", "table_name"]].drop_duplicates().sort_values(["col", "table_name"])
pairs.columns = ["ide_key", "table_name"]
pairs.to_csv(OUT_DIR / "ide_key_tables.csv", index=False)

# 3) Top llaves “hub” (las 12 más frecuentes) con sus tablas
top_keys = freq.head(12)["ide_key"].tolist()
top_pairs = pairs[pairs["ide_key"].isin(top_keys)]
top_pairs.to_csv(OUT_DIR / "ide_key_tables_top12.csv", index=False)

print("OK: ide_key_frequency.csv, ide_key_tables.csv, ide_key_tables_top12.csv en", OUT_DIR)
