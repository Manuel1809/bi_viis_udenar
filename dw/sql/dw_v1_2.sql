-- DW v1.2 (mínimo) - basado en evidencia de schema + auditoría de grano
CREATE DATABASE IF NOT EXISTS dw_siviis;
USE dw_siviis;

-- Dimensión mínima de Proyecto (solo NK por ahora; atributos vendrán cuando los validemos en columns.csv)
CREATE TABLE IF NOT EXISTS dim_proyecto (
  ide_pro BIGINT NOT NULL,
  PRIMARY KEY (ide_pro)
);

-- Dimensión de fecha mínima (se llena luego con calendario/ETL)
CREATE TABLE IF NOT EXISTS dim_fecha (
  date_key INT NOT NULL,          -- formato YYYYMMDD
  full_date DATE NOT NULL,
  PRIMARY KEY (date_key),
  UNIQUE KEY uq_dim_fecha_full_date (full_date)
);

-- Hecho: CDP (1 fila por ide_cdp)
CREATE TABLE IF NOT EXISTS fact_cdp (
  ide_cdp BIGINT NOT NULL,
  ide_pro BIGINT NOT NULL,
  date_key_cdp INT NULL,
  val_cdp DOUBLE NULL,
  PRIMARY KEY (ide_cdp),
  KEY ix_fact_cdp_ide_pro (ide_pro),
  KEY ix_fact_cdp_date (date_key_cdp),
  CONSTRAINT fk_fact_cdp_proyecto FOREIGN KEY (ide_pro) REFERENCES dim_proyecto(ide_pro),
  CONSTRAINT fk_fact_cdp_fecha FOREIGN KEY (date_key_cdp) REFERENCES dim_fecha(date_key)
);

-- Hecho: Compromiso (1 fila por ide_com)
CREATE TABLE IF NOT EXISTS fact_compromiso (
  ide_com BIGINT NOT NULL,
  ide_pro BIGINT NOT NULL,
  date_key_cum INT NULL,
  pun_act DOUBLE NULL,
  PRIMARY KEY (ide_com),
  KEY ix_fact_com_ide_pro (ide_pro),
  KEY ix_fact_com_date (date_key_cum),
  CONSTRAINT fk_fact_com_proyecto FOREIGN KEY (ide_pro) REFERENCES dim_proyecto(ide_pro),
  CONSTRAINT fk_fact_com_fecha FOREIGN KEY (date_key_cum) REFERENCES dim_fecha(date_key)
);

-- Hecho detalle: Imputación CDP (baseline: 1 fila por ide_reg)
CREATE TABLE IF NOT EXISTS fact_imputacioncdp (
  ide_reg BIGINT NOT NULL,
  ide_cdp BIGINT NOT NULL,
  ide_acto BIGINT NOT NULL,
  val_imp DOUBLE NULL,
  PRIMARY KEY (ide_reg),
  KEY ix_fact_imp_cdp (ide_cdp),
  KEY ix_fact_imp_acto (ide_acto)
  -- Nota: ide_cdp se podrá usar para unir lógicamente con fact_cdp (sin FK entre hechos).
);

-- Hecho tipo “estado/snapshot” por proyecto (sin fecha en fuente; se puede manejar con fecha de carga en ETL)
CREATE TABLE IF NOT EXISTS fact_presupuesto_proyecto (
  ide_pro BIGINT NOT NULL,
  bib DOUBLE NULL, cap DOUBLE NULL, eqlab DOUBLE NULL, matpri DOUBLE NULL, monit DOUBLE NULL,
  mov DOUBLE NULL, ops DOUBLE NULL, pap DOUBLE NULL, pub DOUBLE NULL, respel DOUBLE NULL,
  salcam DOUBLE NULL, servlab DOUBLE NULL, servnocal DOUBLE NULL, sweq DOUBLE NULL,
  PRIMARY KEY (ide_pro),
  CONSTRAINT fk_fact_pre_proyecto FOREIGN KEY (ide_pro) REFERENCES dim_proyecto(ide_pro)
);
