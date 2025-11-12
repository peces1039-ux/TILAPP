
# 🧭 Plan de Implementación del Dashboard – Aplicación de Acuicultura

## 1. Objetivo del Dashboard
El objetivo del dashboard es ofrecer una vista general y centralizada de toda la información clave del sistema: siembras, estanques, biometrías y alimentación. Debe permitir una visualización rápida, interactiva y actualizada en tiempo real de los datos almacenados en Supabase.

---

## 2. Fases de Implementación

### Fase 1: Diseño lógico y estructura de datos
- Revisión del modelo de datos en Supabase.
  - Tablas principales: `siembra`, `estanques`, `biometria`, `alimentacion`.
  - Crear *views* o *joins* si se requiere mostrar datos combinados (por ejemplo, producción total por estanque).
- Identificar métricas clave:
  - Total de peces sembrados.
  - Promedio de peso por estanque.
  - Consumo de alimento semanal/mensual.
  - Porcentaje de crecimiento promedio.

---

### Fase 2: Configuración del entorno
- Integrar Supabase con Flutter usando el SDK oficial (`supabase_flutter`).
- Crear un *service* de Supabase para manejar la lectura de datos y su actualización en tiempo real con `StreamBuilder`.
- Configurar autenticación persistente (para que solo usuarios logueados accedan al Dashboard).

---

### Fase 3: Implementación del Frontend (Flutter)
**Estructura sugerida del Dashboard:**
- **Barra superior (AppBar):**
  - Logo o nombre de la app.
  - Menú de usuario (perfil, cerrar sesión).
- **Sección principal (Body):**
  - **Tarjetas resumen (Cards):**
    - Total de siembras activas.
    - Promedio de peso actual.
    - Nivel de alimento usado.
    - Porcentaje de crecimiento.
  - **Gráficas interactivas:**
    - Gráfica de línea: evolución del peso promedio.
    - Gráfica de barras: consumo de alimento por semana.
    - Gráfica circular: porcentaje de estanques activos.
- **Pie de página (Footer):**
  - Fecha de última actualización y versión de la app.

**Librerías recomendadas:**
- `fl_chart` → Para visualizaciones.
- `supabase_flutter` → Para conexión a la base de datos.
- `get` o `provider` → Para gestión de estado.

---

### Fase 4: Integración con Supabase
- Crear funciones de consulta:
  ```dart
  final response = await supabase.from('biometria').select();
  ```
- Implementar actualización automática con `realtime`:
  ```dart
  supabase.channel('biometria').on(
    RealtimeListenTypes.postgresChanges,
    ChannelFilter(event: 'INSERT', schema: 'public', table: 'biometria'),
    (payload, [ref]) {
      actualizarDashboard();
    },
  ).subscribe();
  ```

---

### Fase 5: Pruebas y Optimización
- **Pruebas funcionales:**
  Validar que los datos se actualicen en tiempo real y que las métricas sean correctas.
- **Optimización visual:**
  - Asegurar que el dashboard sea *responsive*.
  - Usar `GridView` o `Flex` para adaptar a pantallas pequeñas.
- **Pruebas de seguridad:**
  Validar que solo usuarios autenticados accedan al dashboard.

---

### Fase 6: Despliegue
- Configurar la aplicación para producción (minificación y optimización).
- Asegurar que las reglas de Supabase (RLS) estén activas para proteger datos.
- Publicar versión en canal interno de pruebas (ej. Firebase App Distribution o APK local).

---

✅ **Resultado esperado:** Dashboard funcional, seguro y sincronizado en tiempo real con Supabase, mostrando indicadores clave de la aplicación acuícola.
