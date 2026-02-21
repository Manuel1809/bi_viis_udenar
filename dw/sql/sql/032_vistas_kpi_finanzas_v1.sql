CREATE OR REPLACE VIEW dw_siviis.vw_kpi_ejecucion_real_corte AS
SELECT
  COUNT(*) AS proyectos_financiados,
  SUM(val_pro > 0) AS con_val_pro_pos,
  SUM(val_pro <= 0 OR val_pro IS NULL) AS excluidos_val_pro_no_pos,

  ROUND(SUM(CASE WHEN val_pro > 0 THEN sal_pro END), 2) AS saldo_total_valpos,
  SUM(CASE WHEN val_pro > 0 THEN val_pro END) AS presupuesto_total_valpos,
  ROUND(SUM(CASE WHEN val_pro > 0 THEN (val_pro - sal_pro) END), 2) AS monto_ejecutado_total_valpos,

  /* Portafolio (ponderado): ratio de sumas */
  ROUND(
    SUM(CASE WHEN val_pro > 0 THEN sal_pro END) /
    NULLIF(SUM(CASE WHEN val_pro > 0 THEN val_pro END), 0)
  , 4) AS pct_disponible_portafolio,

  ROUND(
    1 - (
      SUM(CASE WHEN val_pro > 0 THEN sal_pro END) /
      NULLIF(SUM(CASE WHEN val_pro > 0 THEN val_pro END), 0)
    )
  , 4) AS pct_ejecutado_portafolio,

  /* Promedio por proyecto (no ponderado) */
  ROUND(AVG(CASE WHEN val_pro > 0 THEN sal_pro / val_pro END), 4) AS prom_pct_disponible_proyecto,
  ROUND(AVG(CASE WHEN val_pro > 0 THEN 1 - (sal_pro / val_pro) END), 4) AS prom_pct_ejecutado_proyecto

FROM dw_siviis.vw_proyecto_kpi_fin;

SELECT * FROM dw_siviis.vw_kpi_ejecucion_real_corte;
