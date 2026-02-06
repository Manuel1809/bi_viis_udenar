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
