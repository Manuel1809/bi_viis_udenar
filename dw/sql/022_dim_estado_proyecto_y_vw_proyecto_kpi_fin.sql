/* 022_dim_estado_proyecto_y_vw_proyecto_kpi_fin.sql
   Baseline fuente: siviis_2025_12
*/

CREATE TABLE IF NOT EXISTS dw_siviis.dim_estado_proyecto (
  est_pro VARCHAR(30) NOT NULL PRIMARY KEY,
  categoria VARCHAR(30) NOT NULL,
  es_control_viis TINYINT NOT NULL,
  es_vigente TINYINT NOT NULL,
  observacion VARCHAR(255) NULL
);

TRUNCATE TABLE dw_siviis.dim_estado_proyecto;

INSERT INTO dw_siviis.dim_estado_proyecto (est_pro, categoria, es_control_viis, es_vigente, observacion) VALUES
('Registrado','externo',0,0,'Trámite externo; no control de ejecución'),
('Prerregistrado','externo',0,0,'Trámite externo'),
('Enviado para Registro','externo',0,0,'Trámite externo'),

('Preinscrito','convocatoria',1,0,'Convocatoria'),
('Entregó Correcciones','convocatoria',1,0,'Convocatoria'),
('Aprobado','convocatoria',1,0,'Cumple requisitos; no implica financiación'),

('En Ejecución','ejecucion',1,1,'Vigente'),
('Prorroga','ejecucion',1,1,'Vigente'),
('Prorroga Extraordinaria','ejecucion',1,1,'Vigente'),

('Pendiente Producto Académico','post_ejecucion',1,0,'Pendiente compromisos'),
('Proceso de Cierre','post_ejecucion',1,0,'Cierre administrativo'),
('Vencido','post_ejecucion',1,0,'Vencido por compromisos'),
('Enviado a Control Interno','control',1,0,'Remitido por incumplimiento'),

('Terminado','cerrado',1,0,'Cerrado'),

('Incompleto','descartado',1,0,'Sale por información incompleta'),
('No Aceptado','descartado',1,0,'No pasa selección'),
('No Aprobado','descartado',1,0,'No aprobado'),
('Con Conceptos No Favorables','descartado',1,0,'Evaluación no favorable'),
('No Entregó Correcciones','descartado',1,0,'Descartado por no corregir'),
('No Ejecutado','descartado',1,0,'No ejecutado'),
('Cancelado','descartado',1,0,'Cancelado'),
('Retirado','descartado',1,0,'Retirado');

CREATE OR REPLACE VIEW dw_siviis.vw_proyecto_kpi_fin AS
SELECT
  p.*,
  c.es_financiada,
  e.es_control_viis,
  e.es_vigente,
  e.categoria AS categoria_estado
FROM dw_siviis.dim_proyecto p
JOIN dw_siviis.dim_convocatoria c ON c.ide_conv = p.ide_conv
JOIN dw_siviis.dim_estado_proyecto e ON e.est_pro = p.est_pro
WHERE p.es_inferido = 0
  AND c.es_financiada = 1
  AND e.es_control_viis = 1;
