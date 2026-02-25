/* 034_kpi_solicitudes_v1.sql
   Baseline fuente: siviis_2025_12
   Vistas: semántica de solicitud + KPI tiempos/reproceso
*/

/* 1) Vista semántica (duraciones + banderas de calidad) */
CREATE OR REPLACE VIEW dw_siviis.vw_solicitud_sem AS
SELECT
  s.ide_sol,
  s.ide_pro,
  s.tip_sol,
  s.est_sol,
  s.val_tot,
  s.fec_env,
  s.fec_adm,
  s.fec_pag,
  s.fec_dev,

  /* Duraciones crudas */
  CASE WHEN s.fec_env IS NOT NULL AND s.fec_adm IS NOT NULL
       THEN DATEDIFF(s.fec_adm, s.fec_env) END AS dias_env_a_adm,

  CASE WHEN s.fec_adm IS NOT NULL AND s.fec_pag IS NOT NULL
       THEN DATEDIFF(s.fec_pag, s.fec_adm) END AS dias_adm_a_pag,

  CASE WHEN s.fec_env IS NOT NULL AND s.fec_pag IS NOT NULL
       THEN DATEDIFF(s.fec_pag, s.fec_env) END AS dias_env_a_pag,

  /* Bandera de calidad (cualquier negativo) */
  CASE
    WHEN (s.fec_env IS NOT NULL AND s.fec_adm IS NOT NULL AND DATEDIFF(s.fec_adm, s.fec_env) < 0)
      OR (s.fec_adm IS NOT NULL AND s.fec_pag IS NOT NULL AND DATEDIFF(s.fec_pag, s.fec_adm) < 0)
      OR (s.fec_env IS NOT NULL AND s.fec_pag IS NOT NULL AND DATEDIFF(s.fec_pag, s.fec_env) < 0)
    THEN 1 ELSE 0
  END AS inconsistencia_fechas,

  /* Versiones saneadas: negativos -> NULL */
  CASE WHEN s.fec_env IS NOT NULL AND s.fec_adm IS NOT NULL AND DATEDIFF(s.fec_adm, s.fec_env) < 0
       THEN NULL
       ELSE CASE WHEN s.fec_env IS NOT NULL AND s.fec_adm IS NOT NULL
                 THEN DATEDIFF(s.fec_adm, s.fec_env) END
  END AS dias_env_a_adm_ok,

  CASE WHEN s.fec_adm IS NOT NULL AND s.fec_pag IS NOT NULL AND DATEDIFF(s.fec_pag, s.fec_adm) < 0
       THEN NULL
       ELSE CASE WHEN s.fec_adm IS NOT NULL AND s.fec_pag IS NOT NULL
                 THEN DATEDIFF(s.fec_pag, s.fec_adm) END
  END AS dias_adm_a_pag_ok,

  CASE WHEN s.fec_env IS NOT NULL AND s.fec_pag IS NOT NULL AND DATEDIFF(s.fec_pag, s.fec_env) < 0
       THEN NULL
       ELSE CASE WHEN s.fec_env IS NOT NULL AND s.fec_pag IS NOT NULL
                 THEN DATEDIFF(s.fec_pag, s.fec_env) END
  END AS dias_env_a_pag_ok,

  /* Indicadores de proceso por eventos (fechas) */
  CASE WHEN s.fec_adm IS NOT NULL THEN 1 ELSE 0 END AS tiene_acto_adm,
  CASE WHEN s.fec_pag IS NOT NULL THEN 1 ELSE 0 END AS tiene_pago,
  CASE WHEN s.fec_dev IS NOT NULL THEN 1 ELSE 0 END AS tiene_devolucion

FROM siviis_2025_12.solicitud s;


/* 2) KPI tiempos y reproceso (con totales + medianas) */
CREATE OR REPLACE VIEW dw_siviis.vw_kpi_solicitud_tiempos AS
WITH base AS (
  SELECT * FROM dw_siviis.vw_solicitud_sem
),
ok AS (
  SELECT * FROM base WHERE inconsistencia_fechas = 0
),
summary AS (
  SELECT
    (SELECT COUNT(*) FROM base) AS total_solicitudes_all,
    COUNT(*) AS total_solicitudes_ok,
    (SELECT SUM(inconsistencia_fechas) FROM base) AS n_inconsistentes,

    SUM(tiene_acto_adm) AS n_con_acto_adm,
    SUM(tiene_pago) AS n_con_pago,
    SUM(tiene_devolucion) AS n_con_devolucion,

    ROUND(SUM(tiene_devolucion) / NULLIF(COUNT(*),0), 4) AS tasa_devolucion,

    ROUND(AVG(dias_env_a_adm_ok), 2) AS prom_dias_env_a_adm,
    ROUND(AVG(dias_adm_a_pag_ok), 2) AS prom_dias_adm_a_pag,
    ROUND(AVG(dias_env_a_pag_ok), 2) AS prom_dias_env_a_pag
  FROM ok
),
env_adm_rank AS (
  SELECT
    dias_env_a_adm_ok AS v,
    ROW_NUMBER() OVER (ORDER BY dias_env_a_adm_ok) AS rn,
    COUNT(*) OVER () AS n
  FROM ok
  WHERE dias_env_a_adm_ok IS NOT NULL
),
env_adm_med AS (
  SELECT MAX(CASE WHEN rn = CEIL(0.50*n) THEN v END) AS p50_env_a_adm
  FROM env_adm_rank
),
env_pag_rank AS (
  SELECT
    dias_env_a_pag_ok AS v,
    ROW_NUMBER() OVER (ORDER BY dias_env_a_pag_ok) AS rn,
    COUNT(*) OVER () AS n
  FROM ok
  WHERE dias_env_a_pag_ok IS NOT NULL
),
env_pag_med AS (
  SELECT MAX(CASE WHEN rn = CEIL(0.50*n) THEN v END) AS p50_env_a_pag
  FROM env_pag_rank
)
SELECT
  s.total_solicitudes_all,
  s.total_solicitudes_ok,
  s.n_inconsistentes,
  s.n_con_acto_adm,
  s.n_con_pago,
  s.n_con_devolucion,
  s.tasa_devolucion,
  s.prom_dias_env_a_adm,
  s.prom_dias_adm_a_pag,
  s.prom_dias_env_a_pag,
  m1.p50_env_a_adm,
  m2.p50_env_a_pag
FROM summary s
CROSS JOIN env_adm_med m1
CROSS JOIN env_pag_med m2;
