/* 
/* dw_siviis_kpi_proyecto_v1.sql
   Baseline fuente: siviis_2025_12
*/

SET @OLD_SQL_SAFE_UPDATES = @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

/* 1) Bandera de miembros inferidos */
ALTER TABLE dw_siviis.dim_proyecto
  ADD COLUMN es_inferido TINYINT NOT NULL DEFAULT 0;

/* 2) Columnas mínimas para KPIs v1 */
ALTER TABLE dw_siviis.dim_proyecto
  ADD COLUMN est_pro VARCHAR(30) NULL,
  ADD COLUMN fec_ins_pro DATETIME NULL,
  ADD COLUMN fec_apr DATE NULL,
  ADD COLUMN fec_ter_pry DATE NULL,
  ADD COLUMN fec_ter_pro DATE NULL,
  ADD COLUMN val_pro BIGINT NULL,
  ADD COLUMN sal_pro DECIMAL(11,2) NULL;

/* 3) Marcar inferidos: no existen en siviis_2025_12.proyecto */
UPDATE dw_siviis.dim_proyecto dp
LEFT JOIN siviis_2025_12.proyecto p ON p.ide_pro = dp.ide_pro
SET dp.es_inferido = IF(p.ide_pro IS NULL, 1, 0);

/* 4) Cargar atributos SOLO para no inferidos */
UPDATE dw_siviis.dim_proyecto dp
JOIN siviis_2025_12.proyecto p ON p.ide_pro = dp.ide_pro
SET
  dp.ide_conv    = p.ide_conv,
  dp.est_pro     = p.est_pro,
  dp.fec_ins_pro = p.fec_ins_pro,
  dp.fec_apr     = p.fec_apr,
  dp.fec_ter_pry = p.fec_ter_pry,
  dp.fec_ter_pro = p.fec_ter_pro,
  dp.val_pro     = p.val_pro,
  dp.sal_pro     = p.sal_pro
WHERE dp.es_inferido = 0;

/* 5) Vista base para KPIs financieros (excluye inferidos + conv no financiadas) */
CREATE OR REPLACE VIEW dw_siviis.vw_proyecto_kpi_fin AS
SELECT
  p.*,
  c.es_financiada
FROM dw_siviis.dim_proyecto p
JOIN dw_siviis.dim_convocatoria c ON c.ide_conv = p.ide_conv
WHERE p.es_inferido = 0
  AND c.es_financiada = 1;

/* 6) Vista de fecha fin ajustada (plan inicial vs prórrogas aprobadas) */
CREATE OR REPLACE VIEW dw_siviis.vw_proyecto_fin_ajustada AS
SELECT
  p.ide_pro,
  p.ide_conv,
  p.est_pro,
  p.fec_ter_pry AS fec_fin_inicial,
  p.fec_ter_pro,
  GREATEST(
    COALESCE(p.fec_ter_pry, '1900-01-01'),
    COALESCE(pr.max_fec_prorroga, '1900-01-01'),
    COALESCE(pre.max_fec_prorrogae, '1900-01-01')
  ) AS fec_fin_ajustada,
  pr.n_prorrogas,
  pre.n_prorrogas_e
FROM dw_siviis.vw_proyecto_kpi_fin p
LEFT JOIN (
  SELECT ide_pro, MAX(nue_fec_ter) AS max_fec_prorroga, COUNT(*) AS n_prorrogas
  FROM siviis_2025_12.prorroga
  WHERE est_prr = '1' AND nue_fec_ter IS NOT NULL
  GROUP BY ide_pro
) pr ON pr.ide_pro = p.ide_pro
LEFT JOIN (
  SELECT ide_pro, MAX(nue_fec_ter) AS max_fec_prorrogae, COUNT(*) AS n_prorrogas_e
  FROM siviis_2025_12.prorrogae
  WHERE est_prr = '1' AND nue_fec_ter IS NOT NULL
  GROUP BY ide_pro
) pre ON pre.ide_pro = p.ide_pro;

SET SQL_SAFE_UPDATES = @OLD_SQL_SAFE_UPDATES;
