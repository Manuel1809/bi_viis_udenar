# Modelo lógico DW v1 (Evidencia-driven) — SIVIIS/VIIS

## Enfoque
Se adopta arquitectura tipo Bus (Kimball): procesos (hechos) 

## Hechos núcleo (v1)

### Fact_Proyecto (fuente: proyecto)
- Grano: 1 fila por ide_pro
- Llaves (ide_*): ide_pro, ide_conv, ide_dep, ide_per
- Fechas (role-playing): fec_act_cum, fec_apr, fec_ins_pro, fec_rev_pro, fec_sus_con, fec_ter_pro, fec_ter_pry
- Medidas numéricas: (todas las numéricas NO ide_*) + value_measures (val_con, val_pro, val_sol, val_uefe, val_uesp)

### Fact_Movimiento (fuente: movimiento)
- Grano: 1 fila por ide_mov
- Llaves (ide_*): ide_mov, ide_pro, ide_provN, ide_provS
- Fechas (role-playing): fec_acto, fec_adm, fec_dev, fec_env, fec_ini, fec_mov, fec_reg, fec_ter
- Medidas: val_mov, val_movN (+ otras numéricas no ide_* si aplican)

### Fact_Solicitud (fuente: solicitud + solicitudc)
- Grano: 1 fila por ide_sol
- Llaves (ide_*): ide_sol, ide_pro
- Fechas (role-playing): fec_adm, fec_dev, fec_env, fec_ini, fec_pag, fec_ter
- Medidas: val_tot (+ otras numéricas no ide_* si aplican)
- Nota: se unifican solicitud y solicitudc con un atributo DW `source_table` para trazabilidad.

### Fact_Cofinanciacion (fuente: cofinanciacion)
- Grano: 1 fila por ide_cof
- Llaves (ide_*): ide_cof, ide_ent, ide_pro
- Fechas: (no evidenciadas en baseline)
- Medidas: val_efe, val_esp, val_tot

## Dimensiones conformadas (v1 — solo llaves)
- Dim_Proyecto (NK: ide_pro)
- Dim_Persona (NK: ide_per) — aparece por proyecto
- Dim_Dependencia (NK: ide_dep)
- Dim_Convocatoria (NK: ide_conv)
- Dim_Entidad (NK: ide_ent)
- Dim_Tiempo (role-playing: una FK por cada fec_*)
- Dim_Proveedor_N (NK: ide_provN) y Dim_Proveedor_S (NK: ide_provS) [provisional hasta hallar tabla maestra]

 ## Hechos añadidos (v1.2) — evidencia baseline 2025-12

### Fact_CDP (fuente: cdp)
- Grano: 1 fila por ide_cdp
- Dimensiones: Tiempo (rol: fec_cdp), Proyecto (ide_pro)
- Medida: val_cdp

### Fact_Compromiso (fuente: compromiso)
- Grano: 1 fila por ide_com
- Dimensiones: Tiempo (rol: fec_cum), Proyecto (ide_pro)
- Medida numérica detectada: pun_act (pendiente confirmar semántica)

### Fact_ImputacionCDP (fuente: imputacioncdp)
- Grano: por confirmar con auditoría (ide_reg vs (ide_cdp, ide_acto))
- Dimensiones: CDP (ide_cdp), Acto/Documento (ide_acto), Proyecto (vía cdp→ide_pro)
- Medida: val_imp
- Nota: si es “detalle” de CDP, puede actuar como hecho de distribución (line-item).

### Fact_Presupuesto (fuente: presupuestos / temporalpresupuestos)
- Grano: 1 fila por ide_pro
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
- Grano confirmado en baseline: 1 fila por ide_reg (total=1, distinct ide_reg=1)
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
