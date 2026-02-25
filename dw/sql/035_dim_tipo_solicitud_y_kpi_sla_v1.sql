/* 035_dim_tipo_solicitud_y_kpi_sla_v1.sql
   Baseline fuente: siviis_2025_12
   Dimensión: clasificación de tip_sol (gasto vs no gasto, SLA)
   KPIs: gasto por tipo + SLA robusto (p50/p75/p90)
*/

/* 1) Dimensión de tipo de solicitud */
CREATE TABLE IF NOT EXISTS dw_siviis.dim_tipo_solicitud (
  tip_sol VARCHAR(100) NOT NULL PRIMARY KEY,
  es_gasto TINYINT NOT NULL,          -- 1=gasto/trámite de pago, 0=no aplica
  aplica_pago TINYINT NOT NULL,       -- 1=se espera fec_pag, 0=no aplica/no se registra
  sla_env_a_adm_dias INT NULL,        -- SLA de envío->acto (si aplica)
  observacion VARCHAR(255) NULL
);

TRUNCATE TABLE dw_siviis.dim_tipo_solicitud;

INSERT INTO dw_siviis.dim_tipo_solicitud (tip_sol, es_gasto, aplica_pago, sla_env_a_adm_dias, observacion) VALUES
('Orden de Compra', 1, 1, 8, 'Trámite típico 5–8 días a acto (según admin)'),
('Orden de Prestación de Servicios', 1, 1, 8, 'Trámite típico 5–8 días a acto (según admin)'),
('Contratacion Udenar', 1, 1, 8, 'Trámite contractual; tiempos variables'),
('Avance', 1, 1, 2, 'Normativa: 1–2 días a acto (según admin)'),
('Monitorias y pasantias', 1, 1, 8, 'Gasto; validar SLA específico si aplica'),
('Cambio de Rubro', 0, 0, NULL, 'No es gasto: movimiento interno entre rubros'),
('Compra de Tiquetes', 0, 0, NULL, 'No se usa / no se concluye como gasto'),
('Sin clasificar', 0, 0, NULL, 'tip_sol vacío o NULL');

/* 2) KPI de solicitudes de gasto por tipo (promedios + tasa devolución + SLA) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_solicitud_gasto_por_tipo AS
SELECT
  d.tip_sol,
  d.sla_env_a_adm_dias,
  COUNT(*) AS n_solicitudes,
  SUM(s.tiene_acto_adm) AS n_con_acto,
  SUM(s.tiene_pago) AS n_con_pago,
  SUM(s.tiene_devolucion) AS n_con_devolucion,
  ROUND(SUM(s.tiene_devolucion)/NULLIF(COUNT(*),0), 4) AS tasa_devolucion,

  ROUND(AVG(s.dias_env_a_adm_ok), 2) AS prom_dias_env_a_adm,
  ROUND(AVG(s.dias_adm_a_pag_ok), 2) AS prom_dias_adm_a_pag,
  ROUND(AVG(s.dias_env_a_pag_ok), 2) AS prom_dias_env_a_pag,

  /* cumplimiento SLA envío->acto: solo donde existe acto */
  ROUND(
    SUM(CASE WHEN s.dias_env_a_adm_ok IS NOT NULL
              AND d.sla_env_a_adm_dias IS NOT NULL
              AND s.dias_env_a_adm_ok <= d.sla_env_a_adm_dias
             THEN 1 ELSE 0 END)
    / NULLIF(SUM(s.dias_env_a_adm_ok IS NOT NULL),0)
  , 4) AS pct_cumple_sla_env_a_adm

FROM dw_siviis.vw_solicitud_sem s
JOIN dw_siviis.dim_tipo_solicitud d
  ON d.tip_sol = COALESCE(NULLIF(TRIM(s.tip_sol), ''), 'Sin clasificar')
WHERE s.inconsistencia_fechas = 0
  AND d.es_gasto = 1
GROUP BY d.tip_sol, d.sla_env_a_adm_dias;

/* 3) KPI robusto de SLA por tipo (p50/p75/p90 + devoluciones) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_solicitud_sla_resumen_por_tipo AS
WITH ok AS (
  SELECT
    d.tip_sol,
    d.sla_env_a_adm_dias,
    s.dias_env_a_adm_ok,
    s.tiene_devolucion
  FROM dw_siviis.vw_solicitud_sem s
  JOIN dw_siviis.dim_tipo_solicitud d
    ON d.tip_sol = COALESCE(NULLIF(TRIM(s.tip_sol), ''), 'Sin clasificar')
  WHERE s.inconsistencia_fechas = 0
    AND d.es_gasto = 1
    AND s.dias_env_a_adm_ok IS NOT NULL
),
ranked AS (
  SELECT
    tip_sol,
    sla_env_a_adm_dias,
    dias_env_a_adm_ok AS v,
    tiene_devolucion,
    ROW_NUMBER() OVER (PARTITION BY tip_sol ORDER BY dias_env_a_adm_ok) AS rn,
    COUNT(*) OVER (PARTITION BY tip_sol) AS n
  FROM ok
)
SELECT
  tip_sol,
  sla_env_a_adm_dias,
  MAX(n) AS n_con_acto,
  ROUND(AVG(v),2) AS prom_env_a_acto,
  MAX(CASE WHEN rn = CEIL(0.50*n) THEN v END) AS p50_env_a_acto,
  MAX(CASE WHEN rn = CEIL(0.75*n) THEN v END) AS p75_env_a_acto,
  MAX(CASE WHEN rn = CEIL(0.90*n) THEN v END) AS p90_env_a_acto,
  ROUND(SUM(CASE WHEN v <= sla_env_a_adm_dias THEN 1 ELSE 0 END)/MAX(n),4) AS pct_cumple_sla,
  ROUND(SUM(tiene_devolucion)/MAX(n),4) AS tasa_devolucion_sobre_con_acto
FROM ranked
GROUP BY tip_sol, sla_env_a_adm_dias;
