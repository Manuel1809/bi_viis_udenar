# 02 - Política de seguridad y tratamiento de datos (BI – SIVIIS/VIIS)

## 1. Propósito
Definir medidas para asegurar confidencialidad, integridad y uso responsable de la información proveniente del SIVIIS y fuentes complementarias durante el desarrollo del sistema BI. Esta política aplica al Data Warehouse, procesos ETL y dashboards.

## 2. Principios
- Minimización: solo usar los datos necesarios para KPIs y análisis institucional.
- Agregación: priorizar indicadores agregados (por facultad, convocatoria, año, estado) sobre datos individuales.
- Separación: el DW y ETL NO deben alterar el sistema transaccional SIVIIS.
- Trazabilidad: documentar transformaciones, reglas y accesos.

## 3. Clasificación de datos (guía práctica)
### Datos sensibles / personales (no deben exponerse en dashboards)
- Nombres y apellidos de estudiantes o investigadores (si no es estrictamente necesario).
- Identificación personal (cédula, código estudiantil), correos, teléfonos.
- Direcciones y cualquier dato que permita identificación directa.

### Datos institucionales no sensibles (sí pueden exponerse)
- Identificadores internos de proyectos (código de proyecto).
- Fechas de convocatoria, inicio/fin, estados del proyecto.
- Montos financieros aprobados/ejecutados (según autorización VIIS).
- Conteos agregados (número de proyectos, número de participantes, ejecución por periodo).

## 4. Reglas de anonimización (definiciones)
Se recomienda aplicar al menos una de estas estrategias:

### Estrategia A (recomendada para versión 1)
- Dashboards solo con datos agregados.
- No mostrar listas de estudiantes ni investigadores.
- Participación estudiantil se presenta como conteo por proyecto/facultad/periodo.

### Estrategia B (si VIIS requiere detalle de responsables)
- Mostrar investigador/director solo si existe aprobación explícita.
- No mostrar datos de estudiantes (solo conteos).

### Estrategia C (máxima restricción)
- Eliminar cualquier dato individual y dejar únicamente agregados por unidad académica y periodo.

Decisión adoptada (marcar una):
- [ ] A
- [ ] B
- [ ] C

## 5. Accesos y roles (principio de mínimo privilegio)
- Base SIVIIS: solo lectura.
- Data Warehouse:
  - Rol Admin: configuración de DW y ETL.
  - Rol Analista: consultas y creación de vistas.
  - Rol Usuario VIIS: acceso a dashboards, sin acceso a tablas crudas.
- Herramienta de visualización: usuarios por perfil, con permisos por tablero.

## 6. Manejo de credenciales
- Prohibido subir contraseñas al repositorio.
- Usar variables de entorno o archivos `.env` (excluidos por `.gitignore`).
- Rotación de credenciales si se detecta exposición accidental.

## 7. Retención y almacenamiento
- Evitar copias no controladas de datos.
- Almacenar extracciones en carpeta institucional autorizada.
- Si se usan muestras para desarrollo, preferir datos anonimizados.

## 8. Auditoría y evidencia
- Registrar:
  - fecha de extracción/carga
  - fuente
  - número de registros
  - errores/rechazos
- Mantener evidencia QA de consistencia e integridad.

## 9. Aprobación
Esta política debe ser revisada y aprobada por el validador funcional de la VIIS o su delegado.

- Nombre:
- Cargo:
- Fecha:
- Firma/confirmación:
