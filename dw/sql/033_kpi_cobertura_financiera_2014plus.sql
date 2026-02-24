/* 033_kpi_cobertura_financiera_2014plus.sql
   KPIs financieros restringidos a cobertura (>=2014-01-01)
   Baseline fuente: siviis_2025_12
*/

/* KPI: Terminados con CDP (2014+) pero sin movimientos (2014+) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_terminados_cdp_sin_mov_2014plus AS
SELECT
  DATE('2014-01-01') AS inicio_cobertura,
  p.ide_conv,
  c.nom_conv,

  COUNT(*) AS n_terminados_valpos,

  SUM(CASE WHEN COALESCE(cd.n_cdp_2014,0) > 0 THEN 1 ELSE 0 END) AS n_terminados_con_cdp_2014plus,
  SUM(CASE WHEN COALESCE(mv.n_mov_2014,0) > 0 THEN 1 ELSE 0 END) AS n_con_mov_2014plus,

  SUM(CASE WHEN COALESCE(cd.n_cdp_2014,0) > 0 AND COALESCE(mv.n_mov_2014,0) = 0 THEN 1 ELSE 0 END) AS n_cdp_sin_mov_2014plus,

  ROUND(
    SUM(CASE WHEN COALESCE(cd.n_cdp_2014,0) > 0 AND COALESCE(mv.n_mov_2014,0) = 0 THEN 1 ELSE 0 END)
    / NULLIF(SUM(CASE WHEN COALESCE(cd.n_cdp_2014,0) > 0 THEN 1 ELSE 0 END),0)
  , 4) AS pct_cdp_sin_mov_2014plus,

  ROUND(
    SUM(CASE WHEN COALESCE(cd.n_cdp_2014,0) > 0 AND COALESCE(mv.n_mov_2014,0) = 0 THEN COALESCE(cd.sum_cdp_2014,0) END)
  , 2) AS monto_cdp_sin_mov_2014plus

FROM dw_siviis.vw_proyecto_kpi_fin p
JOIN dw_siviis.dim_convocatoria c ON c.ide_conv = p.ide_conv

LEFT JOIN (
  SELECT
    ide_pro,
    COUNT(*) AS n_cdp_2014,
    ROUND(SUM(val_cdp),2) AS sum_cdp_2014
  FROM dw_siviis.fact_cdp
  WHERE date_key_cdp IS NOT NULL
    AND date_key_cdp >= 20140101
  GROUP BY ide_pro
) cd ON cd.ide_pro = p.ide_pro

LEFT JOIN (
  SELECT
    ide_pro,
    COUNT(*) AS n_mov_2014,
    ROUND(SUM(val_mov),2) AS sum_mov_2014
  FROM dw_siviis.fact_movimiento
  WHERE COALESCE(date_key_mov, date_key_reg, date_key_env) IS NOT NULL
    AND COALESCE(date_key_mov, date_key_reg, date_key_env) >= 20140101
  GROUP BY ide_pro
) mv ON mv.ide_pro = p.ide_pro

WHERE p.est_pro = 'Terminado'
  AND p.val_pro > 0
GROUP BY p.ide_conv, c.nom_conv;


/* Ranking: top convocatorias con brecha CDP sin movimiento (2014+) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_convocatorias_cdp_sin_mov_top_2014plus AS
SELECT
  *
FROM dw_siviis.vw_kpi_terminados_cdp_sin_mov_2014plus
WHERE n_terminados_con_cdp_2014plus >= 5
ORDER BY pct_cdp_sin_mov_2014plus DESC, n_terminados_con_cdp_2014plus DESC;
 
