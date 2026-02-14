import csv
import re
from pathlib import Path
from collections import Counter, defaultdict

BASE_DIR = Path(__file__).resolve().parent

TABLES_CSV = BASE_DIR / "tables.csv"
COLUMNS_CSV = BASE_DIR / "columns.csv"
DIFF_TABLES_CSV = BASE_DIR / "schema_diff_tables__2019-01_vs_2025-12.csv"

OUT_DIR = BASE_DIR / "reports_core"
OUT_DIR.mkdir(exist_ok=True)

# --- Configurable: vocabulario por dominio (puedes ampliarlo) ---
DOMAINS = {
    "proyectos": ["proy", "proyecto", "ide_pro", "contenidoproyecto", "prorroga", "novedadproyecto"],
    "personas": ["persona", "invest", "coinvest", "colaborador", "evaluador", "autor", "usuario", "rol", "doc", "correo"],
    "organizacion": ["facult", "depar", "program", "centro", "entidad", "areaconocimiento", "disciplina", "grupo", "semillero"],
    "finanzas": ["presup", "rubro", "cdp", "comprom", "cofin", "imput", "poliza", "proveedor", "contrat", "banco", "benef", "movim", "plancompras", "tiquete"],
    "productos": ["articulo", "libro", "ponencia", "revista", "premio", "cita", "producto"],
    "convocatorias": ["convoc"],
}

ID_COL_RE = re.compile(r"(^id$)|(_id$)|(^id_)|(^cod_)|(^codigo)|(^ide_)", re.IGNORECASE)

def read_single_col_csv(path: Path, col_name: str):
    out = []
    with path.open("r", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            out.append(row[col_name])
    return out

def read_diff_tables(path: Path):
    added, removed = set(), set()
    with path.open("r", encoding="utf-8") as f:
        r = csv.DictReader(f)
        for row in r:
            ch = row["change"].strip().upper()
            t = row["table_name"].strip()
            if ch == "ADDED":
                added.add(t)
            elif ch == "REMOVED":
                removed.add(t)
    return added, removed

def dtype_class(dt: str) -> str:
    d = dt.lower()
    if "date" in d or "time" in d or "timestamp" in d or "datetime" in d:
        return "date"
    if d.startswith(("int", "bigint", "smallint", "tinyint", "decimal", "numeric", "double", "float", "real")):
        return "numeric"
    if d.startswith(("varchar", "char")) or "text" in d:
        return "text"
    return "other"

def write_list_csv(path: Path, header: str, values):
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([header])
        for v in sorted(values):
            w.writerow([v])

# --- 1) Cargar tablas baseline ---
baseline_tables = set(read_single_col_csv(TABLES_CSV, "table_name"))

# --- 2) Cargar diff histórico para persistencia ---
added_tables, removed_tables = read_diff_tables(DIFF_TABLES_CSV)
persistent_tables = baseline_tables - added_tables  # = tablas que existen en 2019 y 2025

# --- 3) Cargar columnas y construir perfil por tabla ---
cols_by_table = defaultdict(list)  # table -> [(col, dtype)]
ide_col_counter = Counter()        # cuenta columnas ide_ globales

with COLUMNS_CSV.open("r", encoding="utf-8") as f:
    r = csv.DictReader(f)
    for row in r:
        t = row["table_name"].strip()
        c = row["column_name"].strip()
        dt = row["data_type"].strip()
        cols_by_table[t].append((c, dt))
        if c.lower().startswith("ide_"):
            ide_col_counter[c.lower()] += 1

# columnas ide_ más frecuentes (señales de “entidades centrales” en el OLTP)
top_ide_cols = [name for name, cnt in ide_col_counter.most_common(12)]

profiles = []
domain_scores = []

for t in sorted(baseline_tables):
    cols = cols_by_table.get(t, [])
    col_names = [c.lower() for c, _ in cols]
    dtypes = [dtype_class(dt) for _, dt in cols]

    n_date = sum(x == "date" for x in dtypes)
    n_numeric = sum(x == "numeric" for x in dtypes)
    n_text = sum(x == "text" for x in dtypes)

    n_ide = sum(c.startswith("ide_") for c in col_names)
    n_id_like = sum(bool(ID_COL_RE.search(c)) for c in col_names)

    # flags: presencia de ide_cols “centrales”
    ide_flags = {f"has_{k}": int(k in col_names) for k in top_ide_cols}

    # scoring por dominios: hits en nombre de tabla + hits en columnas
    t_low = t.lower()
    scores = {}
    for dom, kws in DOMAINS.items():
        score = 0
        for kw in kws:
            kw_low = kw.lower()
            if kw_low in t_low:
                score += 2
            # columnas
            score += sum(1 for c in col_names if kw_low in c)
        scores[dom] = score

    hit_total = sum(scores.values())

    # heurística fact-like: no es “verdad”, es priorización para revisar
    fact_like = (2 * n_ide) + (2 * n_date) + (1 * n_numeric) + (0.1 * len(cols))

    profiles.append({
        "table_name": t,
        "is_persistent_2019_2025": int(t in persistent_tables),
        "is_added_since_2019": int(t in added_tables),
        "col_count": len(cols),
        "n_date": n_date,
        "n_numeric": n_numeric,
        "n_text": n_text,
        "n_ide": n_ide,
        "n_id_like": n_id_like,
        "fact_like_score": round(fact_like, 2),
        **ide_flags
    })

    domain_scores.append({
        "table_name": t,
        "hit_total": hit_total,
        **{f"hit_{dom}": scores[dom] for dom in DOMAINS}
    })

# --- 4) Guardar reportes base ---
write_list_csv(OUT_DIR / "tables_persistent_2019_2025.csv", "table_name", persistent_tables)
write_list_csv(OUT_DIR / "tables_added_since_2019.csv", "table_name", added_tables)
write_list_csv(OUT_DIR / "tables_removed_since_2019.csv", "table_name", removed_tables)

# table_profile.csv
profile_path = OUT_DIR / "table_profile.csv"
with profile_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(profiles[0].keys()))
    w.writeheader()
    w.writerows(profiles)

# table_domain_scores.csv
scores_path = OUT_DIR / "table_domain_scores.csv"
with scores_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(domain_scores[0].keys()))
    w.writeheader()
    w.writerows(domain_scores)

# --- 5) Candidatos v2 (criterios conservadores para NO perder tablas) ---
# Incluimos si:
#   - tiene hits por dominio, o
#   - contiene alguna ide_ “central”, o
#   - tiene estructura “interesante” (muchas ide_ / muchas columnas)
profiles_by_table = {p["table_name"]: p for p in profiles}
scores_by_table = {s["table_name"]: s for s in domain_scores}

candidate_v2 = []
review_queue = []
fact_candidates = []

for t in sorted(baseline_tables):
    p = profiles_by_table[t]
    s = scores_by_table[t]

    has_central_ide = any(p.get(f"has_{k}", 0) == 1 for k in top_ide_cols)
    interesting_structure = (p["n_ide"] >= 3) or (p["col_count"] >= 18)
    domain_hit = s["hit_total"] > 0

    is_candidate = domain_hit or has_central_ide or interesting_structure

    if is_candidate:
        candidate_v2.append({
            "table_name": t,
            "is_persistent_2019_2025": p["is_persistent_2019_2025"],
            "is_added_since_2019": p["is_added_since_2019"],
            "col_count": p["col_count"],
            "n_ide": p["n_ide"],
            "n_date": p["n_date"],
            "n_numeric": p["n_numeric"],
            "fact_like_score": p["fact_like_score"],
            "hit_total": s["hit_total"]
        })
    else:
        # cola de revisión: persistentes con señales suaves (para “no se nos queda”)
        if p["is_persistent_2019_2025"] == 1 and (p["n_ide"] >= 2 or p["col_count"] >= 15):
            review_queue.append({
                "table_name": t,
                "col_count": p["col_count"],
                "n_ide": p["n_ide"],
                "n_date": p["n_date"],
                "n_numeric": p["n_numeric"],
                "fact_like_score": p["fact_like_score"],
            })

    # candidatos a hechos (para revisar): varias llaves + numéricos y/o fechas
    if p["n_ide"] >= 2 and (p["n_numeric"] >= 5 or p["n_date"] >= 2):
        fact_candidates.append({
            "table_name": t,
            "is_persistent_2019_2025": p["is_persistent_2019_2025"],
            "n_ide": p["n_ide"],
            "n_date": p["n_date"],
            "n_numeric": p["n_numeric"],
            "col_count": p["col_count"],
            "fact_like_score": p["fact_like_score"],
        })

# Guardar candidatos v2
cand_path = OUT_DIR / "candidate_tables_v2.csv"
with cand_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(candidate_v2[0].keys()))
    w.writeheader()
    w.writerows(sorted(candidate_v2, key=lambda x: (-x["hit_total"], -x["fact_like_score"], x["table_name"].lower())))

# Guardar cola revisión
rev_path = OUT_DIR / "review_queue.csv"
with rev_path.open("w", newline="", encoding="utf-8") as f:
    if review_queue:
        w = csv.DictWriter(f, fieldnames=list(review_queue[0].keys()))
        w.writeheader()
        w.writerows(sorted(review_queue, key=lambda x: (-x["fact_like_score"], x["table_name"].lower())))
    else:
        f.write("table_name,col_count,n_ide,n_date,n_numeric,fact_like_score\n")

# Guardar candidatos a hechos
fact_path = OUT_DIR / "fact_candidates.csv"
with fact_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(fact_candidates[0].keys()))
    w.writeheader()
    w.writerows(sorted(fact_candidates, key=lambda x: (-x["fact_like_score"], x["table_name"].lower())))

print("OK: reportes generados en:", OUT_DIR)
print(" - tables_persistent_2019_2025.csv")
print(" - tables_added_since_2019.csv")
print(" - table_profile.csv")
print(" - table_domain_scores.csv")
print(" - candidate_tables_v2.csv")
print(" - review_queue.csv")
print(" - fact_candidates.csv")
