import os
from getpass import getpass
import mysql.connector

# Por defecto (puedes cambiar con variables de entorno)
SRC_DB = os.getenv("MYSQL_SOURCE_DB", "siviis_2025_12")
DW_DB  = os.getenv("MYSQL_DW_DB", "dw_siviis")

MEASURES_PRESUP = [
    "bib","cap","eqlab","matpri","monit",
    "mov","ops","pap","pub","respel",
    "salcam","servlab","servnocal","sweq"
]

def main():
    host = os.getenv("MYSQL_HOST", "127.0.0.1")
    port = int(os.getenv("MYSQL_PORT", "3306"))
    user = os.getenv("MYSQL_USER", "root")

    # Si defines MYSQL_PWD en PowerShell, no pedirá contraseña
    pwd = os.getenv("MYSQL_PWD")
    if not pwd:
        pwd = getpass("MySQL password: ")

    cnx = mysql.connector.connect(
        host=host, port=port, user=user, password=pwd, autocommit=False
    )
    cur = cnx.cursor()

    # --- helpers ---
    def exec_sql(sql: str):
        cur.execute(sql)

    def table_exists(db: str, table: str) -> bool:
        cur.execute(
            """
            SELECT COUNT(*)
            FROM information_schema.tables
            WHERE table_schema=%s AND table_name=%s
            """,
            (db, table),
        )
        return int(cur.fetchone()[0]) > 0

    def count(sql: str) -> int:
        cur.execute(sql)
        return int(cur.fetchone()[0])

    # 0) sanity: existen BD
    cur.execute("SHOW DATABASES LIKE %s", (SRC_DB,))
    if cur.fetchone() is None:
        raise RuntimeError(f"No existe la BD fuente: {SRC_DB}")

    cur.execute("SHOW DATABASES LIKE %s", (DW_DB,))
    if cur.fetchone() is None:
        raise RuntimeError(f"No existe la BD DW: {DW_DB}")

    # 1) limpiar DW (facts -> dims)
    for t in [
        "fact_presupuesto_proyecto",
        "fact_imputacioncdp",
        "fact_compromiso",
        "fact_cdp",
        "dim_proyecto",
        "dim_fecha",
    ]:
        exec_sql(f"DELETE FROM {DW_DB}.{t};")
    cnx.commit()

    # 2) dim_proyecto (NK ide_pro)
    # Tomamos ide_pro desde varias tablas para no perder proyectos referenciados
    for tbl, col in [
        ("proyecto", "ide_pro"),
        ("cdp", "ide_pro"),
        ("compromiso", "ide_pro"),
        ("presupuestos", "ide_pro"),
        ("temporalpresupuestos", "ide_pro"),
    ]:
        if table_exists(SRC_DB, tbl):
            exec_sql(
                f"""
                INSERT IGNORE INTO {DW_DB}.dim_proyecto (ide_pro)
                SELECT DISTINCT {col}
                FROM {SRC_DB}.{tbl}
                WHERE {col} IS NOT NULL;
                """
            )
    cnx.commit()

    # 3) dim_fecha (solo fechas realmente presentes en eventos CDP/Compromiso)
    # Manejo SEGURO de 0000-00-00: trabajamos con texto.
    if table_exists(SRC_DB, "cdp"):
        exec_sql(
            f"""
            INSERT IGNORE INTO {DW_DB}.dim_fecha (date_key, full_date)
            SELECT DISTINCT
              CAST(REPLACE(date_str,'-','') AS UNSIGNED) AS date_key,
              STR_TO_DATE(date_str,'%Y-%m-%d') AS full_date
            FROM (
              SELECT NULLIF(LEFT(CAST(fec_cdp AS CHAR),10),'0000-00-00') AS date_str
              FROM {SRC_DB}.cdp
            ) x
            WHERE date_str IS NOT NULL;
            """
        )

    if table_exists(SRC_DB, "compromiso"):
        exec_sql(
            f"""
            INSERT IGNORE INTO {DW_DB}.dim_fecha (date_key, full_date)
            SELECT DISTINCT
              CAST(REPLACE(date_str,'-','') AS UNSIGNED) AS date_key,
              STR_TO_DATE(date_str,'%Y-%m-%d') AS full_date
            FROM (
              SELECT NULLIF(LEFT(CAST(fec_cum AS CHAR),10),'0000-00-00') AS date_str
              FROM {SRC_DB}.compromiso
            ) x
            WHERE date_str IS NOT NULL;
            """
        )

    cnx.commit()

    # 4) facts

    # 4.1 fact_cdp
    if table_exists(SRC_DB, "cdp"):
        exec_sql(
            f"""
            INSERT INTO {DW_DB}.fact_cdp (ide_cdp, ide_pro, date_key_cdp, val_cdp)
            SELECT
              ide_cdp,
              ide_pro,
              CASE
                WHEN NULLIF(LEFT(CAST(fec_cdp AS CHAR),10),'0000-00-00') IS NULL THEN NULL
                ELSE CAST(REPLACE(LEFT(CAST(fec_cdp AS CHAR),10),'-','') AS UNSIGNED)
              END AS date_key_cdp,
              val_cdp
            FROM {SRC_DB}.cdp;
            """
        )

    # 4.2 fact_compromiso
    if table_exists(SRC_DB, "compromiso"):
        exec_sql(
            f"""
            INSERT INTO {DW_DB}.fact_compromiso (ide_com, ide_pro, date_key_cum, pun_act)
            SELECT
              ide_com,
              ide_pro,
              CASE
                WHEN NULLIF(LEFT(CAST(fec_cum AS CHAR),10),'0000-00-00') IS NULL THEN NULL
                ELSE CAST(REPLACE(LEFT(CAST(fec_cum AS CHAR),10),'-','') AS UNSIGNED)
              END AS date_key_cum,
              pun_act
            FROM {SRC_DB}.compromiso;
            """
        )

    # 4.3 fact_imputacioncdp
    if table_exists(SRC_DB, "imputacioncdp"):
        exec_sql(
            f"""
            INSERT INTO {DW_DB}.fact_imputacioncdp (ide_reg, ide_cdp, ide_acto, val_imp)
            SELECT ide_reg, ide_cdp, ide_acto, val_imp
            FROM {SRC_DB}.imputacioncdp;
            """
        )

    # 4.4 fact_presupuesto_proyecto (presupuestos + temporalpresupuestos)
    cols = ", ".join(["ide_pro"] + MEASURES_PRESUP)

    if table_exists(SRC_DB, "presupuestos"):
        exec_sql(
            f"""
            INSERT INTO {DW_DB}.fact_presupuesto_proyecto ({cols})
            SELECT {cols}
            FROM {SRC_DB}.presupuestos;
            """
        )

    # completar faltantes (si existen) con temporalpresupuestos
    if table_exists(SRC_DB, "temporalpresupuestos"):
        exec_sql(
            f"""
            INSERT IGNORE INTO {DW_DB}.fact_presupuesto_proyecto ({cols})
            SELECT {cols}
            FROM {SRC_DB}.temporalpresupuestos;
            """
        )

    cnx.commit()

    # 5) Conteos (control)
    print("OK carga v1.2")
    print("dim_proyecto:", count(f"SELECT COUNT(*) FROM {DW_DB}.dim_proyecto;"))
    print("dim_fecha:", count(f"SELECT COUNT(*) FROM {DW_DB}.dim_fecha;"))
    print("fact_cdp:", count(f"SELECT COUNT(*) FROM {DW_DB}.fact_cdp;"))
    print("fact_compromiso:", count(f"SELECT COUNT(*) FROM {DW_DB}.fact_compromiso;"))
    print("fact_imputacioncdp:", count(f"SELECT COUNT(*) FROM {DW_DB}.fact_imputacioncdp;"))
    print("fact_presupuesto_proyecto:", count(f"SELECT COUNT(*) FROM {DW_DB}.fact_presupuesto_proyecto;"))

    cur.close()
    cnx.close()

if __name__ == "__main__":
    main()
