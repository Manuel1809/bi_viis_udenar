CREATE TABLE IF NOT EXISTS dw_siviis.dim_convocatoria (
  ide_conv INT NOT NULL PRIMARY KEY,
  nom_conv TEXT NOT NULL,
  tip_conv CHAR(11) NOT NULL,
  fec_ape DATE NULL,
  fec_cie DATE NULL,
  num_acu VARCHAR(4) NOT NULL,
  fec_acu DATE NULL,
  est_conv CHAR(8) NOT NULL,
  bolsa_conv INT NULL,
  es_financiada TINYINT NOT NULL DEFAULT 1
);

TRUNCATE TABLE dw_siviis.dim_convocatoria;

INSERT INTO dw_siviis.dim_convocatoria
(ide_conv, nom_conv, tip_conv, fec_ape, fec_cie, num_acu, fec_acu, est_conv, bolsa_conv)
SELECT
  ide_conv, nom_conv, tip_conv, fec_ape, fec_cie, num_acu, fec_acu, est_conv, bolsa_conv
FROM siviis_2025_12.convocatoria;

UPDATE dw_siviis.dim_convocatoria
SET es_financiada = 0
WHERE ide_conv IN (5,10,11);
