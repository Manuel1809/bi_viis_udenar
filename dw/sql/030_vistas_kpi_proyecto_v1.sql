/* 030_vistas_kpi_proyecto_v1.sql
   Vistas KPI Proyecto v1 (baseline fuente: siviis_2025_12)
*/

/* 1) KPI: Tasa de aprobación */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_tasa_aprobacion AS
SELECT
  COUNT(*) AS proyectos_financiados,
  SUM(fec_ins_pro IS NOT NULL) AS con_inscripcion,
  SUM(fec_ins_pro IS NOT NULL AND fec_apr IS NOT NULL) AS aprobados_con_inscripcion,
  ROUND(
    SUM(fec_ins_pro IS NOT NULL AND fec_apr IS NOT NULL) / NULLIF(SUM(fec_ins_pro IS NOT NULL), 0),
    4
  ) AS tasa_aprobacion
FROM dw_siviis.vw_proyecto_kpi_fin;


/* 2) KPI: Tiempo de aprobación (días) con control de negativos */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_tiempo_aprobacion AS
SELECT
  COUNT(*) AS n_con_ins_y_apr,
  SUM(DATEDIFF(fec_apr, DATE(fec_ins_pro)) < 0) AS n_negativos,
  ROUND(AVG(CASE WHEN DATEDIFF(fec_apr, DATE(fec_ins_pro)) >= 0
                 THEN DATEDIFF(fec_apr, DATE(fec_ins_pro)) END), 2) AS prom_dias_ok,
  MIN(CASE WHEN DATEDIFF(fec_apr, DATE(fec_ins_pro)) >= 0
           THEN DATEDIFF(fec_apr, DATE(fec_ins_pro)) END) AS min_dias_ok,
  MAX(CASE WHEN DATEDIFF(fec_apr, DATE(fec_ins_pro)) >= 0
           THEN DATEDIFF(fec_apr, DATE(fec_ins_pro)) END) AS max_dias_ok
FROM dw_siviis.vw_proyecto_kpi_fin
WHERE fec_ins_pro IS NOT NULL
  AND fec_apr IS NOT NULL;


/* 3) KPI: Vigentes vencidos a corte 2025-12-31 (plan inicial vs ajustado + salvados) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_vencidos_corte_2025_12_31 AS
SELECT
  DATE('2025-12-31') AS fecha_corte,
  COUNT(*) AS proyectos_base_fin,
  SUM(CASE WHEN p.es_vigente = 1 THEN 1 ELSE 0 END) AS proyectos_vigentes,

  SUM(CASE
        WHEN p.es_vigente = 1
         AND f.fec_fin_inicial IS NOT NULL
         AND f.fec_fin_inicial < DATE('2025-12-31')
        THEN 1 ELSE 0 END) AS vencidos_plan_inicial,

  SUM(CASE
        WHEN p.es_vigente = 1
         AND f.fec_fin_ajustada IS NOT NULL
         AND f.fec_fin_ajustada < DATE('2025-12-31')
        THEN 1 ELSE 0 END) AS vencidos_plan_ajustado,

  SUM(CASE
        WHEN p.es_vigente = 1
         AND f.fec_fin_inicial IS NOT NULL
         AND f.fec_fin_inicial < DATE('2025-12-31')
         AND f.fec_fin_ajustada >= DATE('2025-12-31')
        THEN 1 ELSE 0 END) AS salvados_por_prorroga,

  ROUND(
    SUM(CASE
          WHEN p.es_vigente = 1
           AND f.fec_fin_inicial IS NOT NULL
           AND f.fec_fin_inicial < DATE('2025-12-31')
          THEN 1 ELSE 0 END)
    / NULLIF(SUM(CASE WHEN p.es_vigente = 1 THEN 1 ELSE 0 END), 0)
  , 4) AS pct_vencidos_plan_inicial,

  ROUND(
    SUM(CASE
          WHEN p.es_vigente = 1
           AND f.fec_fin_ajustada IS NOT NULL
           AND f.fec_fin_ajustada < DATE('2025-12-31')
          THEN 1 ELSE 0 END)
    / NULLIF(SUM(CASE WHEN p.es_vigente = 1 THEN 1 ELSE 0 END), 0)
  , 4) AS pct_vencidos_plan_ajustado

FROM dw_siviis.vw_proyecto_kpi_fin p
JOIN dw_siviis.vw_proyecto_fin_ajustada f
  ON f.ide_pro = p.ide_pro;


/* 4) KPI: Cierre en tiempo o antes vs tarde (contra plan ajustado) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_cierre_en_tiempo AS
SELECT
  COUNT(*) AS n_terminados,
  SUM(DATEDIFF(fec_ter_pro, fec_fin_ajustada) <= 0) AS n_en_tiempo_o_antes,
  SUM(DATEDIFF(fec_ter_pro, fec_fin_ajustada) > 0) AS n_tarde,
  ROUND(SUM(DATEDIFF(fec_ter_pro, fec_fin_ajustada) <= 0) / COUNT(*), 4) AS pct_en_tiempo_o_antes,
  ROUND(SUM(DATEDIFF(fec_ter_pro, fec_fin_ajustada) > 0) / COUNT(*), 4) AS pct_tarde
FROM dw_siviis.vw_proyecto_fin_ajustada
WHERE est_pro = 'Terminado'
  AND fec_ter_pro IS NOT NULL
  AND fec_fin_ajustada IS NOT NULL;


/* 5) KPI: Retraso de cierre (resumen robusto: p50/p75/p90 + anticipados) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_retraso_cierre_resumen AS
WITH base AS (
  SELECT
    DATEDIFF(fec_ter_pro, fec_fin_ajustada) AS retraso_dias
  FROM dw_siviis.vw_proyecto_fin_ajustada
  WHERE est_pro = 'Terminado'
    AND fec_ter_pro IS NOT NULL
    AND fec_fin_ajustada IS NOT NULL
),
pos AS (
  SELECT retraso_dias
  FROM base
  WHERE retraso_dias >= 0
),
ranked AS (
  SELECT
    retraso_dias,
    ROW_NUMBER() OVER (ORDER BY retraso_dias) AS rn,
    COUNT(*) OVER () AS n
  FROM pos
),
pct AS (
  SELECT
    MAX(CASE WHEN rn = CEIL(0.50*n) THEN retraso_dias END) AS p50,
    MAX(CASE WHEN rn = CEIL(0.75*n) THEN retraso_dias END) AS p75,
    MAX(CASE WHEN rn = CEIL(0.90*n) THEN retraso_dias END) AS p90,
    MAX(CASE WHEN rn = n THEN retraso_dias END) AS max_retraso
  FROM ranked
)
SELECT
  (SELECT COUNT(*) FROM base) AS n_terminados_con_fechas,
  (SELECT SUM(retraso_dias < 0) FROM base) AS n_anticipados,
  (SELECT SUM(retraso_dias = 0) FROM base) AS n_en_fecha,
  (SELECT ROUND(AVG(retraso_dias),2) FROM pos) AS prom_retraso_dias_ok,
  p50, p75, p90, max_retraso
FROM pct;
