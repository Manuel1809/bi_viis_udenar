/* 031_vistas_kpi_prorrogas_v1.sql
   Vistas KPI Prórrogas v1 (baseline fuente: siviis_2025_12)
   Filtros: est_prr='1' y nue_fec_ter IS NOT NULL
*/

/* 1) KPI: tasas de prórroga (i, a, extraordinaria) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_prorroga_tasas AS
SELECT
  base.total_financiados,
  pr_i.proy_con_prorroga_i,
  pr_a.proy_con_prorroga_a,
  pre_i.proy_con_prorrogae_i,
  ROUND(pr_i.proy_con_prorroga_i / base.total_financiados, 4) AS pct_prorroga_i,
  ROUND(pr_a.proy_con_prorroga_a / base.total_financiados, 4) AS pct_prorroga_a,
  ROUND(pre_i.proy_con_prorrogae_i / base.total_financiados, 4) AS pct_prorrogae_i
FROM
  (SELECT COUNT(*) AS total_financiados FROM dw_siviis.vw_proyecto_kpi_fin) base
CROSS JOIN
  (SELECT COUNT(DISTINCT ide_pro) AS proy_con_prorroga_i
   FROM siviis_2025_12.prorroga
   WHERE tip_prr='i' AND est_prr='1' AND nue_fec_ter IS NOT NULL
     AND ide_pro IN (SELECT ide_pro FROM dw_siviis.vw_proyecto_kpi_fin)
  ) pr_i
CROSS JOIN
  (SELECT COUNT(DISTINCT ide_pro) AS proy_con_prorroga_a
   FROM siviis_2025_12.prorroga
   WHERE tip_prr='a' AND est_prr='1' AND nue_fec_ter IS NOT NULL
     AND ide_pro IN (SELECT ide_pro FROM dw_siviis.vw_proyecto_kpi_fin)
  ) pr_a
CROSS JOIN
  (SELECT COUNT(DISTINCT ide_pro) AS proy_con_prorrogae_i
   FROM siviis_2025_12.prorrogae
   WHERE tip_prr='i' AND est_prr='1' AND nue_fec_ter IS NOT NULL
     AND ide_pro IN (SELECT ide_pro FROM dw_siviis.vw_proyecto_kpi_fin)
  ) pre_i;


/* 2) KPI: solapamientos de prórrogas (combinaciones) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_prorroga_solapamientos AS
SELECT
  CASE
    WHEN pri.ide_pro IS NOT NULL AND pra.ide_pro IS NULL AND pre.ide_pro IS NULL THEN 'Solo prorroga_i'
    WHEN pri.ide_pro IS NULL AND pra.ide_pro IS NOT NULL AND pre.ide_pro IS NULL THEN 'Solo prorroga_a'
    WHEN pri.ide_pro IS NULL AND pra.ide_pro IS NULL AND pre.ide_pro IS NOT NULL THEN 'Solo prorrogae'
    WHEN pri.ide_pro IS NOT NULL AND pra.ide_pro IS NOT NULL AND pre.ide_pro IS NULL THEN 'prorroga_i + prorroga_a'
    WHEN pri.ide_pro IS NOT NULL AND pra.ide_pro IS NULL AND pre.ide_pro IS NOT NULL THEN 'prorroga_i + prorrogae'
    WHEN pri.ide_pro IS NULL AND pra.ide_pro IS NOT NULL AND pre.ide_pro IS NOT NULL THEN 'prorroga_a + prorrogae'
    WHEN pri.ide_pro IS NOT NULL AND pra.ide_pro IS NOT NULL AND pre.ide_pro IS NOT NULL THEN 'i + a + prorrogae'
    ELSE 'Sin prorrogas'
  END AS grupo,
  COUNT(*) AS n_proyectos,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM dw_siviis.vw_proyecto_kpi_fin), 4) AS pct_proyectos
FROM (SELECT ide_pro FROM dw_siviis.vw_proyecto_kpi_fin) b
LEFT JOIN (
  SELECT DISTINCT ide_pro
  FROM siviis_2025_12.prorroga
  WHERE tip_prr='i' AND est_prr='1' AND nue_fec_ter IS NOT NULL
) pri ON pri.ide_pro = b.ide_pro
LEFT JOIN (
  SELECT DISTINCT ide_pro
  FROM siviis_2025_12.prorroga
  WHERE tip_prr='a' AND est_prr='1' AND nue_fec_ter IS NOT NULL
) pra ON pra.ide_pro = b.ide_pro
LEFT JOIN (
  SELECT DISTINCT ide_pro
  FROM siviis_2025_12.prorrogae
  WHERE est_prr='1' AND nue_fec_ter IS NOT NULL
) pre ON pre.ide_pro = b.ide_pro
GROUP BY grupo;
/* 3) KPI:extension_prorrogas  */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_extension_prorrogas AS
SELECT
  COUNT(*) AS proyectos_base_fin,
  SUM(fec_fin_inicial IS NULL OR fec_fin_inicial < '2000-01-01') AS sin_fin_inicial_valida,
  SUM(fec_fin_inicial >= '2000-01-01') AS con_fin_inicial_valida,
  SUM(fec_fin_inicial >= '2000-01-01' AND fec_fin_ajustada > fec_fin_inicial) AS con_extension,
  ROUND(
    SUM(fec_fin_inicial >= '2000-01-01' AND fec_fin_ajustada > fec_fin_inicial)
    / NULLIF(SUM(fec_fin_inicial >= '2000-01-01'),0)
  , 4) AS pct_con_extension_sobre_validos,
  ROUND(AVG(CASE WHEN fec_fin_inicial >= '2000-01-01' AND fec_fin_ajustada > fec_fin_inicial
                 THEN DATEDIFF(fec_fin_ajustada, fec_fin_inicial) END), 2) AS prom_extension_dias,
  MAX(CASE WHEN fec_fin_inicial >= '2000-01-01' AND fec_fin_ajustada > fec_fin_inicial
           THEN DATEDIFF(fec_fin_ajustada, fec_fin_inicial) END) AS max_extension_dias
FROM dw_siviis.vw_proyecto_fin_ajustada;
