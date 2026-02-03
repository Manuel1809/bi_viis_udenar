# 00 - Plan de trabajo (BI para SIVIIS – Universidad de Nariño)

## 1. Contexto del proyecto
La Universidad de Nariño cuenta con el SIVIIS (Sistema de Información de la Vicerrectoría de Investigación e Interacción Social), utilizado para la gestión de proyectos de investigación financiados internamente. Sin embargo, al ser un sistema transaccional, presenta limitaciones para generar reportes históricos, analizar tendencias y construir indicadores estratégicos, lo que dificulta la toma de decisiones basada en evidencia por parte de la VIIS.

Este trabajo de grado propone implementar un sistema de Inteligencia de Negocios (BI) que centralice la información mediante una bodega de datos (Data Warehouse), integre y estandarice los datos con procesos ETL y presente indicadores clave a través de tableros dinámicos.

## 2. Objetivo general
Desarrollar un sistema de inteligencia de negocios que optimice la gestión y el análisis de datos de proyectos de investigación internos almacenados en el SIVIIS, para apoyar la toma de decisiones estratégicas en la VIIS de la Universidad de Nariño.

## 3. Objetivos específicos (según propuesta)
1) Analizar literatura sobre BI aplicada a la gestión de investigación y diagnosticar la situación actual del SIVIIS, identificando dificultades que afectan la gestión de información en la VIIS.
2) Diseñar un Data Warehouse alineado con las necesidades de la VIIS, estableciendo su estructura de datos y modelo lógico.
3) Implementar el Data Warehouse integrando fuentes de datos del SIVIIS mediante procesos ETL.
4) Desplegar una herramienta de visualización que facilite el análisis y la generación de reportes estratégicos.

## 4. Metodología de trabajo
- Enfoque: cuantitativo.
- Método: empírico-analítico.
- Metodología BI/DW: HEFESTO.
- Etapas principales:
  A) Diagnóstico
  B) Diseño y desarrollo (requerimientos, fuentes, modelo DW, integración ETL)
  C) Visualización y análisis de datos

## 5. Alcance (versión 1 del sistema BI)
Incluye:
- Diseño e implementación de una bodega de datos (DW) con estructuras optimizadas para consulta.
- Procesos ETL para extracción, limpieza, estandarización y carga desde SIVIIS y fuentes complementarias.
- Herramienta de visualización de uso libre conectada al DW, con dashboards y KPIs prioritarios.
- Validación de calidad e integridad de datos (QA) y validación de utilidad de dashboards con usuarios VIIS.

No incluye (en v1):
- Cambios al sistema transaccional SIVIIS.
- Automatización avanzada en tiempo real (se privilegia carga por lotes).
- Modelos predictivos complejos (se consideran como mejora futura si los datos lo permiten).

## 6. Entregables por etapa (alineados a Tabla 1)
### A) Diagnóstico
- Revisión de literatura (resumen y matriz de artículos).
- Diagnóstico de limitaciones tecnológicas/administrativas del SIVIIS.
- Levantamiento de necesidades de usuarios VIIS.
- Lista preliminar de KPIs y preguntas de negocio.

### B) Diseño y desarrollo (HEFESTO)
- Documento de requerimientos BI (preguntas de negocio, usuarios, KPIs, filtros).
- Inventario y análisis de fuentes de datos (tablas, campos, llaves, calidad).
- Modelo conceptual ampliado (hechos/dimensiones).
- Modelo lógico del DW (esquema estrella/copo/constelación).
- Scripts SQL DDL para creación de dimensiones y hechos.
- ETL: extracción → transformación → carga (carga inicial y/o incremental).
- Evidencia de pruebas de integridad y consistencia (QA).

### C) Visualización y análisis
- Selección e instalación/configuración de herramienta libre (Metabase/Superset u otra).
- Dashboards con KPIs estratégicos.
- Filtros y segmentaciones (por año, facultad, convocatoria, estado, etc.).
- Validación de usabilidad/utilidad con usuarios VIIS.
- Ajustes finales y manual de usuario básico.

## 7. Cronograma operativo (organizado por semanas)
Nota: este cronograma se ajusta según disponibilidad de accesos al SIVIIS.

- Semanas 1–4: Diagnóstico y análisis de requerimientos (entrevistas, KPIs, literatura).
- Semanas 5–10: Diseño DW (modelo conceptual + lógico) y análisis de fuentes.
- Semanas 11–18: Implementación DW + ETL + validación de calidad.
- Semanas 19–24: Visualización (dashboards), validación con usuarios y ajustes.

## 8. Criterios de éxito (mínimos)
- DW implementado y consultable con datos históricos del SIVIIS (y fuentes complementarias si aplica).
- Proceso ETL repetible y documentado, con control de calidad.
- Dashboards accesibles para usuarios VIIS, con KPIs validados.
- Trazabilidad: requerimientos → modelo → ETL → dashboard → QA.
