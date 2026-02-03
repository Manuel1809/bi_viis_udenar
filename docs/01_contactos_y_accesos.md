# 01 - Contactos y accesos (SIVIIS / VIIS)

## 1. Roles clave del proyecto
### Responsable BI (Desarrollo / Integración)
- Nombre: Manuel Esteban Burgos Erazo
- Rol: diseño del DW, ETL, dashboards, QA y documentación.

### Contacto técnico del SIVIIS
- Nombre:
- Dependencia:
- Rol: facilitar inventario de base de datos, diccionario de datos, vistas/consultas, exportaciones y resolución de dudas técnicas.

### Validador funcional (VIIS)
- Nombre:
- Cargo:
- Rol: validar KPIs, definiciones de indicadores, interpretación institucional, y aprobar dashboards para uso directivo.

## 2. Canales de comunicación y rutinas
- Canal principal: (correo / WhatsApp / Teams)
- Reunión de seguimiento: semanal (30–45 min)
- Frecuencia de validación de KPIs/dashboards: quincenal o por iteración

## 3. Accesos requeridos (mínimo viable)
### Acceso a datos del SIVIIS
Opción A (ideal): Acceso de solo lectura a la base de datos del SIVIIS
- Tipo: usuario read-only
- Alcance: esquema/tablas del SIVIIS necesarias para proyectos, ejecución, participantes, estados, convocatorias, etc.
- Requisitos: conexión desde (IP local / VPN / red institucional)

Opción B (plan alterno): exportaciones periódicas desde SIVIIS
- Formato: CSV o Excel
- Periodicidad: semanal o mensual
- Responsable de extracción: contacto técnico SIVIIS
- Carpeta institucional para intercambio: (Drive / OneDrive / carpeta compartida)

### Fuentes complementarias (si existen)
- Archivos Excel/CSV usados hoy para informes (presupuesto, ejecución, listados manuales).
- Catálogos de facultades/dependencias/convocatorias si no están normalizados en SIVIIS.

## 4. Requerimientos técnicos de conexión (para documentar)
- Motor BD SIVIIS: (PostgreSQL / MySQL / SQL Server / otro)
- Host/URL:
- Puerto:
- Base de datos:
- Esquema:
- Usuario read-only:
- Fecha de entrega de credenciales:
- Fecha de primera conexión exitosa:

## 5. Evidencias y trazabilidad
- Registro de solicitudes de acceso (correo/ticket): enlace o referencia
- Fecha de aprobación:
- Restricciones de uso (si aplica): (no extraer datos personales / no copiar fuera / etc.)

## 6. Riesgos y mitigación
- Riesgo: retraso en accesos al SIVIIS.
  - Mitigación: iniciar con exportaciones y construir modelo con muestras.
- Riesgo: datos incompletos o inconsistentes.
  - Mitigación: reglas de calidad, QA, y validación con VIIS.
