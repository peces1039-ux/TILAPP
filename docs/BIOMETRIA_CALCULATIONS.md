# Cálculos Automáticos en Biometrías

## Resumen

Se ha implementado un sistema de cálculos automáticos que se ejecutan al crear o actualizar una biometría. Los valores calculados se guardan en la base de datos y se muestran en la interfaz de usuario.

## Cálculos Implementados

### 1. Biomasa Total (g)

**Fórmula**: `Biomasa Total = Peso Promedio en gramos × Cantidad Actual de Peces`

**Descripción**: Representa el peso total de todos los peces vivos en la siembra.

**Ejemplo**:

- Peso promedio: 1.5 g
- Cantidad actual: 200 peces
- Biomasa total: 1.5 × 200 = 300 g

### 2. Cantidad de Alimento Diario (g/día)

**Fórmula**: `Alimento Diario = Biomasa Total × Porcentaje Biomasa`

**Descripción**: Cantidad de alimento que se debe suministrar diariamente.

**Porcentaje de Biomasa**: Se obtiene dinámicamente de la tabla de alimentación (`tabla_alimentacion`) que corresponda al rango de peso promedio:

- Busca el registro donde: `peso_promedio >= peso_min_gramos` AND `peso_promedio < peso_max_gramos`
- Si se encuentra, usa el `porcentaje_biomasa` de ese registro
- Si no se encuentra ninguna tabla aplicable, usa 3% como valor por defecto

**Ejemplo**:

- Peso promedio: 1.5 g
- Cantidad actual: 200 peces
- Biomasa total: 1.5 × 200 = 300 g
- Tabla encontrada: 1g-2g con 15% de biomasa (porcentaje_biomasa = 0.15)
- Alimento diario: 300 g × 0.15 = 45 g/día

**Nota**: El sistema busca automáticamente la tabla de alimentación apropiada basándose en el peso promedio de los peces.

### 3. Factor de Conversión Alimenticia (FCA)

**Fórmula**: `FCA = Alimento Suministrado (kg) / Aumento de Biomasa (kg)`

**Descripción**: Indica cuántos kilogramos de alimento se necesitaron para producir 1 kg de incremento de biomasa.

**Condiciones**:

- Solo se calcula si existe una biometría anterior
- No se calcula para la primera biometría (se muestra "N/A (Primera biometría)")

**Cálculo del Alimento Acumulado**:

```
Días transcurridos = Fecha actual - Fecha biometría anterior
Alimento diario promedio = (Alimento diario actual + Alimento diario anterior) / 2
Alimento acumulado = Alimento diario promedio × Días transcurridos
```

**Cálculo del Aumento de Biomasa**:

```
Aumento de biomasa = Biomasa total actual - Biomasa total anterior
```

**Ejemplo**:

- Biomasa anterior: 60 kg
- Biomasa actual: 75 kg
- Aumento de biomasa: 15 kg
- Alimento acumulado: 30 kg
- FCA: 30 / 15 = 2.0

**Interpretación del FCA**:

- **FCA < 2.0**: Buena conversión (eficiente) - Se muestra en verde
- **FCA ≥ 2.0**: Conversión mejorable - Se muestra en rojo
- Un FCA bajo indica mejor eficiencia alimenticia y condiciones óptimas

## Implementación Técnica

### Base de Datos

Se agregaron las siguientes columnas a la tabla `biometrias`:

```sql
-- Biomasa total en kg
biomasa_total NUMERIC

-- Cantidad de alimento diario en kg
cantidad_alimento_diario NUMERIC

-- Factor de conversión alimenticia (nullable para primera biometría)
fca NUMERIC

-- Alimento acumulado desde la biometría anterior en kg
alimento_acumulado NUMERIC DEFAULT 0
```

**Constraints**:

- Todos los valores deben ser >= 0
- `fca` puede ser NULL (primera biometría)

**Migración**: `20251116_add_biometria_calculations.sql`

### Modelo de Datos

**Archivo**: `lib/models/biometria.dart`

Campos agregados:

```dart
final double? biomasaTotal;           // kg
final double? cantidadAlimentoDiario; // kg/día
final double? fca;                    // Factor conversión
final double? alimentoAcumulado;      // kg
```

Métodos de formato:

```dart
String get biomasaTotalFormatted         // "75.00 kg"
String get cantidadAlimentoFormatted     // "2.250 kg/día"
String get fcaFormatted                  // "2.00" o "N/A (Primera biometría)"
String get alimentoAcumuladoFormatted    // "30.00 kg"
```

### Servicio

**Archivo**: `lib/services/biometria_service.dart`

#### Método Privado `_calculateBiometrics`

Realiza todos los cálculos necesarios:

1. Obtiene los datos de la siembra (cantidad actual de peces)
2. Calcula la biomasa total
3. **Busca la tabla de alimentación aplicable** según el peso promedio:
   - Llama a `TablasAlimentacionService.findApplicableTable(pesoPromedioGramos)`
   - Si encuentra tabla, usa su `porcentaje_biomasa`
   - Si no encuentra, usa 3% por defecto
4. Calcula la cantidad de alimento diario usando el porcentaje encontrado
5. Si existe biometría anterior:
   - Calcula el aumento de biomasa
   - Estima el alimento acumulado
   - Calcula el FCA

```dart
Future<Map<String, double?>> _calculateBiometrics({
  required String siembraId,
  required double pesoPromedioGramos,
  required DateTime fecha,
}) async {
  // ... fetch siembra data

  // Get applicable feeding table
  double porcentajeBiomasa = 0.03; // Default 3%
  final tablaAplicable = await _tablasAlimentacionService
      .findApplicableTable(pesoPromedioGramos);

  if (tablaAplicable != null) {
    porcentajeBiomasa = tablaAplicable.porcentajeBiomasa / 100;
    debugPrint('Using tabla: ${tablaAplicable.edadLabel}');
  }

  // ... continue with calculations
}
```

#### Métodos Públicos Actualizados

**`create(Biometria biometria)`**:

- Ejecuta `_calculateBiometrics()`
- Crea una nueva biometría con los valores calculados
- Guarda en la base de datos

**`update(Biometria biometria)`**:

- Recalcula todos los valores con `_calculateBiometrics()`
- Actualiza la biometría con los nuevos valores calculados
- Guarda en la base de datos

### Interfaz de Usuario

**Archivo**: `lib/screens/siembra_detalle_screen.dart`

La información calculada se muestra en una tarjeta destacada en la parte superior de la pantalla de detalle de la siembra, justo debajo de la información principal:

**Tarjeta de Última Biometría** (fondo azul claro):

- **Biomasa Total**: Peso total de todos los peces (verde)
- **Alimento Diario**: Cantidad recomendada para el día (naranja)
- **FCA**: Factor de conversión alimenticia con código de colores:
  - Verde si < 2.0 (buena conversión)
  - Rojo si ≥ 2.0 (mejorable)
  - "N/A (Primera biometría)" si no hay biometría anterior
- **Referencia de Alimento**: Tipo de alimento de la tabla aplicable (azul)
- **Raciones Diarias**: Número de raciones por día de la tabla (azul)

**Archivo**: `lib/widgets/biometrias_tab.dart`

El listado de biometrías muestra solo la información básica en cada tarjeta:

- Fecha de la medición
- Peso promedio en gramos
- Tamaño promedio en cm
- Botón para eliminar

```dart
// La información calculada solo se muestra en el detalle de la siembra
Card(
  color: Colors.blue[50],
  child: Column(
    children: [
      Text('Última Biometría'),
      _buildBiometriaInfo('Biomasa Total', ...),
      _buildBiometriaInfo('Alimento Diario', ...),
      _buildBiometriaInfo('FCA', ...),
      _buildBiometriaInfo('Referencia Alimento', ...),
      _buildBiometriaInfo('Raciones Diarias', ...),
    ],
  ),
)
```

## Flujo de Trabajo

1. **Usuario ingresa datos básicos**:

   - Fecha
   - Peso promedio (gramos)
   - Tamaño promedio (cm)

2. **Sistema calcula automáticamente**:

   - Obtiene cantidad actual de peces de la siembra
   - Calcula biomasa total
   - Calcula alimento diario recomendado
   - Si hay biometría anterior, calcula FCA

3. **Sistema guarda todo en BD**:

   - Datos ingresados por el usuario
   - Valores calculados automáticamente

4. **Usuario visualiza resultados**:
   - Datos básicos ingresados
   - Biomasa total calculada
   - Alimento diario recomendado
   - FCA (si aplica) con código de colores

## Validaciones

- Peso promedio debe ser > 0
- Tamaño promedio debe ser > 0
- Siembra debe existir
- Cantidad actual de peces debe ser > 0

## Mejoras Futuras

1. ~~**Porcentaje de biomasa dinámico**: Obtener de `tablas_alimentacion` según rango de peso~~ ✅ **IMPLEMENTADO**
2. **Historial de FCA**: Gráfico mostrando evolución del FCA a lo largo del tiempo
3. **Alertas**: Notificar cuando FCA supere umbrales críticos (> 2.5)
4. **Proyecciones**: Estimar fecha de cosecha basándose en tasa de crecimiento
5. **Optimización**: Sugerencias para mejorar FCA basadas en datos históricos

## Pruebas Recomendadas

1. **Primera biometría**:

   - Crear siembra nueva
   - Registrar primera biometría
   - Verificar que biomasa y alimento se calculen
   - Verificar que FCA sea "N/A (Primera biometría)"

2. **Biometrías posteriores**:

   - Registrar segunda biometría después de varios días
   - Verificar que FCA se calcule correctamente
   - Verificar colores (verde < 2.0, rojo >= 2.0)

3. **Tabla de alimentación**:

   - Registrar biometría con peso 1.5g (verificar que use tabla 1g-2g con 15% biomasa)
   - Registrar biometría con peso 150g (verificar que use tabla correcta)
   - Registrar biometría con peso 50g (verificar que use tabla 0g-100g o default 3%)
   - Verificar en logs qué tabla se está usando

   **Caso de prueba específico**:

   - Siembra: 200,000 peces
   - Peso promedio: 1.5 g
   - Tabla aplicable: peso_min_gramos=1, peso_max_gramos=2, porcentaje_biomasa=15
   - **Resultado esperado**:
     - Biomasa total: (1.5 × 200,000) / 1000 = 300 kg
     - Alimento diario: 300 kg × 0.15 = 45 kg/día

4. **Actualización de biometría**:

   - Editar biometría existente
   - Verificar que valores se recalculen automáticamente

5. **Muertes en la siembra**:
   - Registrar muertes
   - Verificar que cantidad actual disminuya
   - Registrar nueva biometría
   - Verificar que biomasa refleje la nueva cantidad

## Referencias

- Migration: `supabase/migrations/20251116_add_biometria_calculations.sql`
- Modelo: `lib/models/biometria.dart`
- Servicio: `lib/services/biometria_service.dart`
- UI: `lib/widgets/biometrias_tab.dart`
