# Sistema de Registro de Raciones de Alimentación

## Descripción General

El sistema de raciones permite llevar un registro histórico completo de la alimentación suministrada a cada siembra. Las raciones se generan automáticamente de forma diaria basándose en:

- **Última biometría**: Determina la cantidad total de alimento diario requerido
- **Tabla de alimentación**: Define el número de raciones diarias y el porcentaje de biomasa

## Componentes del Sistema

### 1. Base de Datos

**Tabla**: `raciones_alimentacion`

Campos principales:

- `id`: UUID generado automáticamente
- `user_id`: Usuario propietario de la ración
- `siembra_id`: Siembra a la que pertenece la ración
- `fecha`: Fecha de la ración (DATE)
- `numero_racion`: Número secuencial de la ración (1, 2, 3...)
- `hora_programada`: Hora programada para suministrar (TIME)
- `cantidad_gramos`: Cantidad en gramos a suministrar (NUMERIC)
- `completada`: Indica si la ración fue suministrada (BOOLEAN)
- `hora_completada`: Timestamp de cuándo se completó
- `observaciones`: Notas opcionales sobre la ración

**Características**:

- Constraint único: `(siembra_id, fecha, numero_racion)` - Evita duplicados
- RLS habilitado para seguridad multi-tenant
- Índices para optimizar consultas por siembra, fecha y estado

### 2. Modelo de Datos

**Archivo**: `lib/models/racion.dart`

**Propiedades principales**:

- Conversión automática de fecha y hora desde/hacia formato Supabase
- Formatters para mostrar valores en la UI:
  - `cantidadFormatted`: "45.00 g"
  - `horaProgramadaFormatted`: "08:00"
  - `horaCompletadaFormatted`: "08:15" o "N/A"
- Método `isPastDue`: Verifica si la hora programada ya pasó

### 3. Servicio de Raciones

**Archivo**: `lib/services/raciones_service.dart`

**Métodos principales**:

#### `getRacionesByFecha(siembraId, fecha)`

Obtiene las raciones de una fecha específica.

#### `generateDailyRaciones(siembraId, fecha, ultimaBiometria, tablaAlimentacion)`

Genera automáticamente las raciones del día:

- Calcula cantidad por ración: `cantidadDiaria / numRaciones`
- Distribuye horarios entre 8:00 AM y 4:00 PM uniformemente
- Caso especial: Si es 1 ración, la programa al mediodía (12:00)
- Valida que no existan raciones previas para esa fecha
- Inserta todas las raciones en la base de datos

**Ejemplo de distribución de horarios**:

- 3 raciones: 08:00, 12:00, 16:00
- 4 raciones: 08:00, 10:40, 13:20, 16:00
- 6 raciones: 08:00, 09:36, 11:12, 12:48, 14:24, 16:00

#### `markAsCompleted(racionId, observaciones?)`

Marca una ración como completada con timestamp actual.

#### `markAsNotCompleted(racionId)`

Desmarca una ración (para correcciones).

#### `getRacionesBySiembra(siembraId)`

Obtiene historial completo de raciones.

#### `getSummary(siembraId)`

Retorna estadísticas:

- Total de raciones programadas
- Raciones completadas y pendientes
- Total de alimento programado vs suministrado
- Porcentaje de cumplimiento

### 4. Interfaz de Usuario

**Archivo**: `lib/widgets/programacion_alimentacion_tab.dart`

**Características**:

#### Selector de Fecha

- Permite ver raciones de fechas anteriores o futuras
- Formato: "Sábado, 16 Noviembre 2025"
- Botón de calendario para cambiar fecha

#### Resumen del Día

- **Total Diario**: Suma de todas las raciones en gramos
- **Completadas**: Contador "X / Y"
- **Horario**: Muestra rango de horarios programados

#### Lista de Raciones

Cada ración muestra:

- **Checkbox**: Para marcar como completada
- **Número**: "Ración 1", "Ración 2", etc.
- **Hora programada**: "08:00"
- **Cantidad**: "45.00 g"
- **Estado visual**:
  - Verde: Completada ✓
  - Rojo: Hora pasada y no completada ⚠️
  - Blanco: Pendiente normal
- **Hora de completado**: "✓ Completada a las 08:15" (si aplica)

#### Pull-to-Refresh

Deslizar hacia abajo para recargar las raciones.

## Flujo de Uso

### Caso 1: Primer Acceso del Día

1. Usuario abre la pestaña "Programación"
2. Sistema verifica si existen raciones para hoy
3. Si no existen:
   - Genera automáticamente basándose en última biometría
   - Distribuye horarios uniformemente
   - Guarda en base de datos
4. Muestra lista de raciones pendientes

### Caso 2: Marcar Ración como Completada

1. Usuario marca checkbox de una ración
2. Sistema actualiza en BD:
   - `completada = true`
   - `hora_completada = NOW()`
3. UI se actualiza mostrando:
   - Fondo verde
   - Hora de completado
   - Checkmark visual

### Caso 3: Ver Historial

1. Usuario toca el botón de calendario
2. Selecciona fecha anterior
3. Sistema carga raciones de esa fecha
4. Muestra estado guardado (completadas/pendientes)

### Caso 3: Corrección de Error

1. Usuario desmarca checkbox de ración completada
2. Sistema actualiza en BD:
   - `completada = false`
   - `hora_completada = NULL`
3. UI vuelve a estado pendiente

## Integración con Sistema Existente

### Dependencias

El sistema de raciones depende de:

- **Biometría**: Para calcular cantidad diaria de alimento
- **Tabla de Alimentación**: Para número de raciones y porcentaje

### Actualización Automática

Cuando se registra una nueva biometría:

- Las raciones **futuras** se regeneran automáticamente
- Las raciones **pasadas** se mantienen como historial

## Beneficios del Sistema

1. **Trazabilidad Completa**: Registro histórico de toda alimentación suministrada
2. **Control de Cumplimiento**: Visualización inmediata de raciones pendientes
3. **Análisis de Datos**: Información para calcular FCA real y optimizar alimentación
4. **Alertas Visuales**: Identificación rápida de raciones atrasadas
5. **Flexibilidad**: Posibilidad de ver y modificar historial

## Datos para Análisis

Con este sistema es posible:

- Calcular **alimento acumulado real** (solo raciones completadas)
- Comparar **alimento programado vs suministrado**
- Identificar **patrones de alimentación** (horas preferidas)
- Medir **cumplimiento** de protocolos
- Ajustar **programación** basándose en cumplimiento histórico

## Consideraciones de Rendimiento

- **Índices optimizados** para consultas frecuentes
- **Constraint único** evita duplicados accidentales
- **RLS policies** aseguran aislamiento de datos entre usuarios
- **Generación lazy**: Raciones se crean solo cuando se necesitan

## Migración

**Archivo**: `supabase/migrations/20251117_create_raciones_alimentacion_table.sql`

Para aplicar en Supabase:

```bash
# Copiar contenido de la migración y ejecutar en SQL Editor de Supabase
```

O usando CLI de Supabase:

```bash
supabase db push
```

## Próximas Mejoras Sugeridas

1. **Notificaciones Push**: Recordar al usuario cuando es hora de alimentar
2. **Gráficos de Cumplimiento**: Visualizar tendencias semanales/mensuales
3. **Exportación de Reportes**: PDF con historial de alimentación
4. **Integración con FCA**: Calcular FCA automáticamente usando raciones completadas
5. **Modo Offline**: Guardar cambios localmente y sincronizar después
