import csv
import os
from datetime import datetime

BASE_DIR = r"D:\Manuel\Documents\Maestria\Bases de datos"
OUTPUT_FILE = "manifest.csv"

rows = []

for year in sorted(os.listdir(BASE_DIR)):
    year_path = os.path.join(BASE_DIR, year)
    if not os.path.isdir(year_path):
        continue

    for file_name in sorted(os.listdir(year_path)):
        file_path = os.path.join(year_path, file_name)
        if not os.path.isfile(file_path):
            continue

        stats = os.stat(file_path)

        rows.append([
            year,
            file_name,
            round(stats.st_size / (1024 * 1024), 2),  # MB
            datetime.fromtimestamp(stats.st_mtime).strftime("%Y-%m-%d %H:%M:%S")
        ])

with open(OUTPUT_FILE, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["year", "file_name", "size_mb", "last_modified"])
    writer.writerows(rows)

print(f"Manifest generado: {OUTPUT_FILE} con {len(rows)} archivos.")
