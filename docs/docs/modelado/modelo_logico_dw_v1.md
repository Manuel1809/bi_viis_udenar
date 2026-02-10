# Modelo lógico DW v1 (Evidencia-driven) — SIVIIS/VIIS

## Enfoque
Se adopta arquitectura tipo Bus (Kimball): procesos (hechos) integrados por dimensiones conformadas y no se mezclan granos.

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


