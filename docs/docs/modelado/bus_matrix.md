# Bus Matrix (Arquitectura Kimball) - VIIS/SIVIIS

Este documento define los procesos analíticos (hechos), su grano y las dimensiones conformadas
a partir de requerimientos BI y evidencia estructural del sistema fuente (MySQL dumps).

## Versión de referencia (baseline)
- Baseline esquema: 2025-12 (dump 31-12-2025)
- Evidencia de drift operativo (2025-11 vs 2025-12): cambios mínimos (0 tablas, +3/-1 columnas).
- Evidencia de evolución histórica (2019-01 vs 2025-12): crecimiento estructural (+54/-6 tablas; +503/-160 columnas).

## Dimensiones conformadas (propuestas)
- Dim_Tiempo (role-playing según evento)
- Dim_Proyecto (NK: ide_pro)
- Dim_Persona (NK: ide_per)
- Dim_Departamento (NK: ide_dep)
- Dim_Facultad (NK: ide_fac)
- Dim_Convocatoria (NK: ide_conv)
- Dim_Grupo (NK: ide_gru) [si aplica]
- Dim_Programa (NK: ide_prg) [si aplica]
- Dim_Entidad (NK: ide_ent) [si aplica]
- Dim_Proveedor (NK: ide_prov) [si aplica]

> Nota: La confirmación final de dimensiones depende de validar columnas descriptivas y llaves
en `columns.csv` y relaciones via `ide_key_tables_top12.csv`.

## Procesos (hechos) y grano
| Proceso (Hecho) | Grano (1 fila por...) | Tabla(s) fuente candidata(s) | Dimensiones principales |
|---|---|---|---|
| Gestión de proyectos | Proyecto (ide_pro) | proyecto | Tiempo, Proyecto, Persona, Dep/Fac, Convocatoria |
| Movimientos/ejecución | Movimiento (ide_mov) | movimiento | Tiempo, Proyecto, Proveedor, Dep/Fac |
| Solicitudes | Solicitud (ide_sol) | solicitud / solicitudc | Tiempo, Proyecto, Persona, Dep/Fac |
| Cofinanciación | Registro cofinanciación (ide_cof) | cofinanciacion | Tiempo, Proyecto, Entidad |
| CDP | Registro CDP (ide_cdp) | cdp / imputacioncdp | Tiempo, Proyecto, Dep/Fac |
| Compromisos | Registro compromiso (ide_com) | compromiso | Tiempo, Proyecto, Dep/Fac |

## Decisiones pendientes / Validaciones
1. Confirmar si `solicitud` y `solicitudc` representan el mismo proceso o variantes.
2. Determinar si `proyecto` se modela como Dim_Proyecto o como Hecho tipo snapshot (o ambos).
3. Identificar campos de medida (montos/valores) y eventos de tiempo (fechas) para cada hecho.
4. Revisar tablas del `review_queue.csv` para descartar/confirmar relevancia analítica.
5. Mapear KPIs a campos fuente (KPI -> tabla -> columna -> transformación -> DW).

## Evidencia estructural (columns.csv → fact_signals_summary.csv) — Baseline 2025-12

### proyecto
- Grano candidato: 1 fila por `ide_pro`
- ide_cols: `ide_pro`, `ide_conv`, `ide_dep`, `ide_per`
- date_cols: `fec_act_cum`, `fec_apr`, `fec_ins_pro`, `fec_rev_pro`, `fec_sus_con`, `fec_ter_pro`, `fec_ter_pry`
- medidas numéricas (excl. ide_*): `act_cum_pro`, `acu_apr_pro`, `acu_ter_pro`, `dur_pro`, `edi_por`, `pun_ant`, `reg_por`, `rev_por`, `sal_pro`, `val_con`, `val_pro`, `val_sol`, `val_uefe`, `val_uesp`

### movimiento
- Grano candidato: 1 fila por `ide_mov`
- ide_cols: `ide_mov`, `ide_pro`, `ide_provN`, `ide_provS`
- date_cols: `fec_acto`, `fec_adm`, `fec_dev`, `fec_env`, `fec_ini`, `fec_mov`, `fec_reg`, `fec_ter`
- medidas numéricas (excl. ide_*): `num_mov`, `plazo`, `res_mov`, `vb_por`, `val_mov`, `val_movN`
- Nota: `ide_provN` y `ide_provS` implican role-playing en Dim_Proveedor.

### solicitud / solicitudc
- Evidencia: misma señal estructural en ambas tablas (mismas llaves, fechas y medidas)
- Grano candidato: 1 fila por `ide_sol`
- ide_cols: `ide_sol`, `ide_pro`
- date_cols: `fec_adm`, `fec_dev`, `fec_env`, `fec_ini`, `fec_pag`, `fec_ter`
- medidas numéricas (excl. ide_*): `res_sol`, `vb_por`, `val_tot`
- Decisión v1: unificar en DW con un campo `source_table` (solicitud/solicitudc).

### cofinanciacion
- Grano candidato: 1 fila por `ide_cof`
- ide_cols: `ide_cof`, `ide_ent`, `ide_pro`
- date_cols: (no detectadas)
- medidas: `val_efe`, `val_esp`, `val_tot`
- Nota: modelar como hecho atemporal o snapshot por fecha de carga (ETL) hasta hallar fecha real.

### plancompras (opcional v2)
- ide_cols: `ide_plan`, `ide_pro`
- medidas: `mes1..mes24` (requiere unpivot a filas en DW)

### cdp  (evidencia desde fact_signals_summary.csv)
- Grano candidato: 1 fila por `ide_cdp` (validado con auditoría baseline)
- ide_cols: `ide_cdp`, `ide_pro`
- date_cols: `fec_cdp`
- medidas: `val_cdp`

### compromiso  (evidencia desde fact_signals_summary.csv)
- Grano candidato: 1 fila por `ide_com` (validado con auditoría baseline)
- ide_cols: `ide_com`, `ide_pro`
- date_cols: `fec_cum`
- medidas numéricas detectadas: `pun_act` (confirmar significado con diccionario/atributos)

### imputacioncdp  (evidencia desde fact_signals_summary.csv)
- Grano candidato: 1 fila por `ide_reg` (validado SOLO en baseline; revalidar con más años)
- ide_cols: `ide_acto`, `ide_cdp`, `ide_reg`
- date_cols: (no detectadas)
- medidas: `val_imp`
- Nota: revalidar con años 2019–2025 para confirmar estabilidad del grano (baseline tiene 1 fila).


### presupuestos  (evidencia desde fact_signals_summary.csv)
- Grano candidato: 1 fila por `ide_pro`
- ide_cols: `ide_pro`
- date_cols: (no detectadas)
- medidas numéricas (líneas presupuestales): `bib`, `cap`, `eqlab`, `matpri`, `monit`, `mov`, `ops`, `pap`, `pub`, `respel`, `salcam`, `servlab`, `servnocal`, `sweq`

### temporalpresupuestos  (evidencia desde fact_signals_summary.csv)
- Grano candidato: 1 fila por `ide_pro`
- ide_cols: `ide_pro`
- date_cols: (no detectadas)
- medidas numéricas: mismas de `presupuestos`
- Nota: aparente tabla temporal; se define en ETL si se usa como staging o si contiene histórico.

## Validación de grano (auditoría en MySQL 8 — baseline 2025-12, schema: siviis_2025_12)

Resultados de auditoría (COUNT(*) vs COUNT(DISTINCT ...)):

- cdp:
  - COUNT(*) = 1721
  - COUNT(DISTINCT ide_cdp) = 1721
  - Grano confirmado: 1 fila por ide_cdp

- compromiso:
  - COUNT(*) = 2800
  - COUNT(DISTINCT ide_com) = 2800
  - Grano confirmado: 1 fila por ide_com

- imputacioncdp:
  - COUNT(*) = 1
  - COUNT(DISTINCT ide_reg) = 1
  - COUNT(DISTINCT CONCAT(ide_cdp,'|',ide_acto)) = 1
  - Grano confirmado (solo baseline): 1 fila por ide_reg
  - Nota: revalidar con más años (2019–2025) para confirmar estabilidad del grano.

