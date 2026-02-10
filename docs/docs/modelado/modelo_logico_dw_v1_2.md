# Modelo lógico DW v1.2 (Evidencia-driven) — SIVIIS/VIIS

## Enfoque de arquitectura
- Arquitectura tipo Bus (Kimball): múltiples procesos (hechos) integrados mediante dimensiones conformadas.
- Esquema: constelación de hechos (varios fact) + dimensiones compartidas.
- Regla: no se mezclan granos dentro de un mismo hecho (grano = contrato de diseño). 

## Dimensiones conformadas mínimas (v1.2)
- Dim_Proyecto (NK: ide_pro)
- Dim_Fecha (date_key = YYYYMMDD; role-playing para fec_cdp y fec_cum)

## Hechos v1.2 (cerrados con auditoría baseline 2025-12)

### Fact_CDP (fuente: cdp)
- Grano confirmado: 1 fila por ide_cdp  (1721 = 1721)
- Llaves: ide_cdp (PK del hecho), ide_pro (FK a Dim_Proyecto)
- Fecha evento: fec_cdp (FK role-playing a Dim_Fecha)
- Medida: val_cdp

### Fact_Compromiso (fuente: compromiso)
- Grano confirmado: 1 fila por ide_com (2800 = 2800)
- Llaves: ide_com (PK del hecho), ide_pro (FK a Dim_Proyecto)
- Fecha evento: fec_cum (FK role-playing a Dim_Fecha)
- Medida numérica detectada: pun_act (pendiente confirmar semántica funcional)

### Fact_ImputacionCDP (fuente: imputacioncdp)
- Grano confirmado (solo baseline): 1 fila por ide_reg (total=1, distinct ide_reg=1)
- Llaves: ide_reg (PK del hecho), ide_cdp, ide_acto
- Medida: val_imp
- Nota de modelado: hecho de detalle/distribución asociado a CDP (se “drill-down” desde CDP vía ide_cdp). Revalidar grano con más años.

### Fact_Presupuesto_Proyecto (fuente: presupuestos / temporalpresupuestos)
- Grano: 1 fila por ide_pro
- Llave: ide_pro (FK a Dim_Proyecto)
- Medidas: bib, cap, eqlab, matpri, monit, mov, ops, pap, pub, respel, salcam, servlab, servnocal, sweq
- Nota: sin fecha en baseline → si se requiere análisis temporal: snapshot por fecha de carga (ETL) o buscar fecha real en otras tablas.

## Relaciones (vista rápida)
- Fact_CDP           -> Dim_Proyecto (ide_pro)
- Fact_CDP           -> Dim_Fecha (fec_cdp)
- Fact_Compromiso    -> Dim_Proyecto (ide_pro)
- Fact_Compromiso    -> Dim_Fecha (fec_cum)
- Fact_ImputacionCDP -> Fact_CDP (ide_cdp) [relación lógica para drill-down, no necesariamente FK física]
- Fact_Presupuesto_Proyecto -> Dim_Proyecto (ide_pro)

