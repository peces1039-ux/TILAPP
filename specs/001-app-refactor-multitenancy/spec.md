# Feature Specification: App Refactor - Multi-tenancy & UI/UX Redesign

**Feature Branch**: `001-app-refactor-multitenancy`
**Created**: 2025-11-16
**Status**: Draft
**Input**: User description: "Refactorizar aplicación con bottomsheet modals, 3 pantallas principales, multi-tenancy, y gestión de usuarios admin"

## Clarifications

### Session 2025-11-16

- Q: ¿Cómo se asignan los datos existentes sin user_id durante la migración a multi-tenancy? → A: Asumir que solo hay un usuario actual y asignarle todos los datos a ese único usuario existente
- Q: ¿Qué altura debe tener el bottom sheet cuando hay errores de validación que aumentan el contenido? → A: Bottom sheet crece dinámicamente según contenido hasta máximo 80% de pantalla, luego activa scroll interno
- Q: ¿Quién debe tener el rol de admin inicialmente cuando se migra la base de datos o en instalación nueva? → A: Rol admin debe ser asignado manualmente en la base de datos por el equipo de desarrollo/DevOps
- Q: ¿La validación de contraseña requiere caracteres especiales además de 8+ caracteres, 1 número, 1 mayúscula? → A: Solo validar 8+ caracteres, 1 número, 1 mayúscula (sin caracteres especiales obligatorios)
- Q: ¿Qué sucede con los datos del usuario durante los 30 días de soft-delete? ¿Puede recuperar su cuenta? → A: Usuario puede solicitar reactivación dentro de 30 días mediante email especial, restaurando acceso completo
- Q: ¿Cómo se gestionan los usuarios? ¿Admin los crea o hay auto-registro? → A: Los usuarios se auto-registran mediante formulario en la app con rol "user" por defecto. Admin solo puede consultar y eliminar usuarios (soft-delete), NO puede crearlos. Usuarios pueden actualizar su propio perfil y eliminar su cuenta (excepto admins).
- Q: ¿Dónde está ubicado el acceso al perfil de usuario en la interfaz? → A: Agregar icono de perfil en AppBar superior de todas las pantallas
- Q: ¿Qué contenido muestra el Dashboard? → A: Dashboard muestra cards informativos con resumen: total estanques, total siembras activas, navegación rápida a funciones principales

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Navegación Simplificada con 3 Pantallas Principales (Priority: P1)

Como usuario de la aplicación, quiero navegar entre las tres pantallas principales (Dashboard, Estanques, Siembras) usando un menú inferior, para acceder rápidamente a la información más importante sin complejidad innecesaria.

**Why this priority**: Esta es la base de la nueva arquitectura. Sin una navegación clara, ninguna otra funcionalidad es accesible. Es el MVP mínimo para que la app sea usable.

**Independent Test**: Puede ser completamente probado lanzando la app, verificando que aparecen 3 tabs en el bottom navigation, y que al tocar cada uno muestra la pantalla correcta. Entrega valor inmediato de navegación simplificada.

**Acceptance Scenarios**:

1. **Given** usuario autenticado en la app, **When** abre la aplicación, **Then** ve un bottom navigation bar con 3 opciones: Dashboard, Estanques, Siembras
2. **Given** usuario en cualquier pantalla, **When** toca un tab del menú inferior, **Then** navega a esa pantalla sin perder el estado de navegación
3. **Given** usuario en Dashboard, **When** toca tab de Estanques, **Then** ve el listado de estanques con scroll vertical
4. **Given** usuario en Estanques, **When** toca tab de Siembras, **Then** ve el listado de siembras asociadas a sus estanques

---

### User Story 2 - Formularios en Bottom Sheet Modal (Priority: P1)

Como usuario, quiero crear y editar registros (estanques, siembras, biometrías, muertes) a través de bottom sheets modales, para mantener el contexto visual de donde estoy y tener una experiencia más fluida en mobile.

**Why this priority**: Reemplaza los formularios full-screen actuales por una experiencia mobile-first más intuitiva. Es crítico porque afecta todas las operaciones CRUD.

**Independent Test**: Puede ser probado tocando el FAB en cualquier listado, verificando que aparece un bottom sheet desde abajo, llenando el formulario y verificando que se cierra y refresca la lista. Entrega valor inmediato de UX mejorada.

**Acceptance Scenarios**:

1. **Given** usuario en pantalla de Estanques, **When** presiona FAB (+), **Then** aparece bottom sheet modal con formulario de creación de estanque
2. **Given** bottom sheet modal abierto, **When** llena campos y presiona "Guardar", **Then** se cierra el modal, se crea el registro, y se actualiza el listado
3. **Given** usuario viendo detalle de estanque, **When** presiona botón "Editar", **Then** aparece bottom sheet modal con datos pre-cargados del estanque
4. **Given** bottom sheet modal abierto, **When** presiona fuera del modal o botón "Cancelar", **Then** se cierra sin guardar cambios
5. **Given** formulario con errores de validación, **When** intenta guardar, **Then** muestra errores en el mismo modal sin cerrarse

---

### User Story 3 - Listados con Navegación a Detalle (Priority: P1)

Como usuario, quiero ver listados de estanques y siembras en cards, y al tocar una card ver el detalle completo con opciones de editar y eliminar, para gestionar mis datos de forma visual e intuitiva.

**Why this priority**: Permite la visualización y gestión básica de datos. Sin esto, no hay forma de ver o modificar registros existentes.

**Independent Test**: Puede ser probado navegando a Estanques, tocando una card, viendo el detalle, y verificando botones de editar/eliminar. Entrega valor de consulta y gestión de datos.

**Acceptance Scenarios**:

1. **Given** usuario tiene estanques registrados, **When** navega a pantalla Estanques, **Then** ve listado de cards con información resumida (número, capacidad)
2. **Given** usuario en listado de estanques, **When** toca una card, **Then** navega a pantalla de detalle del estanque
3. **Given** usuario en detalle de estanque, **When** ve la pantalla, **Then** muestra información completa: número, capacidad, fecha creación, siembras asociadas
4. **Given** usuario en detalle de estanque, **When** presiona botón "Editar", **Then** abre bottom sheet modal con formulario de edición
5. **Given** usuario en detalle de estanque, **When** presiona botón "Eliminar", **Then** muestra diálogo de confirmación
6. **Given** diálogo de confirmación abierto, **When** confirma eliminación, **Then** elimina el registro, navega de vuelta al listado, y muestra mensaje de éxito

---

### User Story 4 - Registro y Visualización de Biometrías y Muertes (Priority: P2)

Como usuario, quiero registrar biometrías (peso, tamaño) y muertes en cada siembra, y ver el historial en pestañas separadas, para hacer seguimiento del crecimiento y mortalidad de mis peces.

**Why this priority**: Es funcionalidad core del negocio pero depende de tener siembras funcionando (P1). Puede desarrollarse después de US1-3.

**Independent Test**: Puede ser probado navegando a detalle de siembra, registrando una biometría en bottom sheet, verificando que aparece en pestaña de biometrías, y haciendo lo mismo con muertes. Entrega valor de tracking científico.

**Acceptance Scenarios**:

1. **Given** usuario en detalle de siembra, **When** ve la pantalla, **Then** muestra dos pestañas: "Biometrías" y "Historial de Muertes"
2. **Given** usuario en pestaña Biometrías, **When** presiona FAB (+), **Then** abre bottom sheet para registrar nueva biometría (fecha, peso promedio, tamaño promedio)
3. **Given** usuario registra biometría, **When** guarda, **Then** aparece en el historial ordenado por fecha descendente
4. **Given** usuario en pestaña Historial de Muertes, **When** presiona botón "Registrar muerte", **Then** abre bottom sheet para registrar número de muertes y fecha
5. **Given** usuario registra muerte, **When** guarda, **Then** actualiza contador total de muertes y aparece en historial
6. **Given** usuario en historial de biometrías, **When** toca un registro, **Then** puede ver detalles completos y opción de editar/eliminar

---

### User Story 5 - Multi-tenancy: Aislamiento de Datos por Usuario (Priority: P2)

Como usuario de la aplicación, quiero que mis datos estén completamente aislados de otros usuarios, para garantizar privacidad y seguridad de mi información de producción.

**Why this priority**: Seguridad crítica pero puede implementarse después de la navegación básica. Requiere cambios en DB y queries pero no afecta UI directamente.

**Independent Test**: Puede ser probado creando 2 usuarios, logeando con cada uno, creando datos, y verificando que Usuario A no ve datos de Usuario B. Entrega valor de seguridad empresarial.

**Acceptance Scenarios**:

1. **Given** dos usuarios diferentes (user1@example.com, user2@example.com), **When** cada uno crea estanques, **Then** solo ven sus propios estanques
2. **Given** usuario autenticado, **When** realiza cualquier query de listado, **Then** sistema filtra automáticamente por user_id del usuario actual
3. **Given** usuario intenta acceder a URL con ID de recurso de otro usuario, **When** hace la petición, **Then** recibe error 403 o no encuentra el recurso
4. **Given** usuario crea nuevo registro, **When** se guarda en DB, **Then** automáticamente se asocia con user_id del usuario actual
5. **Given** cambio de usuario (logout/login), **When** navega por la app, **Then** ve solo los datos del nuevo usuario sin residuos del anterior

---

### User Story 6 - Consulta y Eliminación de Usuarios (Administrador) (Priority: P3)

Como usuario administrador, quiero acceder a una pantalla de consulta de usuarios desde el menú inferior, para ver el listado de usuarios registrados y poder eliminar cuentas cuando sea necesario.

**Why this priority**: Funcionalidad administrativa que solo afecta a admins. Puede implementarse al final sin bloquear usuarios regulares. Los usuarios se auto-registran, así que admin solo necesita consultar y moderar.

**Independent Test**: Puede ser probado logeando como admin, accediendo al tab de Admin, consultando listado de usuarios, e intentando eliminar usuarios con/sin datos. Entrega valor de administración y moderación.

**Acceptance Scenarios**:

1. **Given** usuario con rol "admin", **When** abre la app, **Then** ve 4 tabs en menú inferior: Dashboard, Estanques, Siembras, Admin
2. **Given** usuario con rol "user", **When** abre la app, **Then** ve solo 3 tabs: Dashboard, Estanques, Siembras (sin Admin)
3. **Given** admin en pantalla Admin, **When** ve la pantalla, **Then** muestra listado de usuarios con: email, rol, fecha creación, estado
4. **Given** admin selecciona un usuario con rol "user", **When** presiona "Eliminar", **Then** verifica que no tenga estanques asociados antes de eliminar
5. **Given** usuario tiene estanques asociados, **When** admin intenta eliminar, **Then** muestra mensaje de error indicando que debe eliminar estanques primero
6. **Given** admin intenta eliminar un usuario con rol "admin", **When** presiona "Eliminar", **Then** sistema previene la acción mostrando "No se pueden eliminar usuarios administradores"

---

### User Story 7 - Auto-registro y Gestión de Perfil de Usuario (Priority: P1)

Como usuario nuevo, quiero registrarme en la aplicación mediante un formulario de registro, y como usuario existente, quiero poder actualizar mi información de perfil y eliminar mi cuenta si lo deseo.

**Why this priority**: Es la puerta de entrada para nuevos usuarios. Sin auto-registro, solo admins podrían usar la app. Es P1 porque habilita el crecimiento orgánico de usuarios.

**Independent Test**: Puede ser probado abriendo la app sin login, completando formulario de registro, logeando con las credenciales nuevas, actualizando perfil, y eliminando cuenta. Entrega valor de onboarding autónomo.

**Acceptance Scenarios**:

1. **Given** usuario no autenticado, **When** abre la aplicación, **Then** ve pantalla de login con botón "Registrarse"
2. **Given** usuario en pantalla de login, **When** toca "Registrarse", **Then** abre pantalla de registro con campos: email, contraseña, confirmar contraseña, nombre
3. **Given** usuario completa formulario de registro con datos válidos, **When** presiona "Crear cuenta", **Then** sistema crea usuario con rol "user" por defecto y lo redirige a la app autenticado
4. **Given** usuario intenta registrarse con email ya existente, **When** presiona "Crear cuenta", **Then** muestra error "Este email ya está registrado"
5. **Given** usuario autenticado en cualquier pantalla, **When** toca icono de perfil en AppBar superior, **Then** navega a pantalla de perfil donde puede ver y editar: nombre, email (solo lectura), cambiar contraseña
6. **Given** usuario con rol "user" en su perfil, **When** presiona "Eliminar mi cuenta", **Then** solicita confirmación y ejecuta soft-delete de su cuenta
7. **Given** usuario con rol "admin" en su perfil, **When** intenta eliminar su cuenta, **Then** sistema previene la acción mostrando "Los administradores no pueden eliminar sus propias cuentas"
8. **Given** usuario con estanques asociados, **When** intenta eliminar su cuenta, **Then** muestra advertencia "Tienes datos asociados" y requiere confirmación explícita antes de proceder

---

### User Story 8 - Gestión de Tablas de Alimentación (Administrador) (Priority: P3)

Como usuario administrador, quiero gestionar tablas de alimentación desde la pantalla Admin, para configurar parámetros de alimentación que se aplicarán automáticamente en los cálculos.

**Why this priority**: Feature avanzada que depende de tener el módulo de alimentación. Puede ser lo último en implementarse.

**Independent Test**: Puede ser probado navegando como admin a sección de Tablas de Alimentación, creando/editando tablas, y verificando que afectan cálculos en siembras. Entrega valor de configuración centralizada.

**Acceptance Scenarios**:

1. **Given** admin en pantalla Admin, **When** navega a sección "Tablas de Alimentación", **Then** ve listado de tablas configuradas
2. **Given** admin presiona "Nueva tabla", **When** abre bottom sheet, **Then** puede configurar parámetros: rango de peso, % alimentación, frecuencia
3. **Given** admin edita tabla existente, **When** guarda cambios, **Then** se aplican automáticamente a cálculos futuros de alimentación
4. **Given** tabla está en uso por siembras activas, **When** admin intenta eliminar, **Then** muestra advertencia y requiere confirmación explícita

---

### Edge Cases

- **¿Qué pasa cuando un usuario intenta crear más de 100 estanques?** Sistema debe permitirlo pero paginar los listados para mantener rendimiento
- **¿Cómo maneja el sistema la pérdida de conexión durante creación de registro?** Bottom sheet debe guardar borrador local y reintentar cuando recupere conexión
- **¿Qué sucede si dos admins editan el mismo usuario simultáneamente?** Último en guardar gana, pero mostrar warning si detecta cambio concurrente
- **¿Cómo se maneja un deeplink de invitación expirado?** Mostrar mensaje de error amigable con opción de solicitar nuevo link
- **¿Qué pasa si un usuario tiene sesión abierta en múltiples dispositivos y se elimina su cuenta?** Todas las sesiones se invalidan y se fuerza logout
- **¿Cómo se previene que un admin se elimine a sí mismo?** Sistema debe prevenir con validación "No puedes eliminar tu propia cuenta"
- **¿Qué sucede con los datos de un usuario eliminado?** Se implementa soft-delete: usuario y datos se marcan con deleted_at. Durante 30 días, el usuario puede solicitar reactivación contactando soporte técnico, quien limpia el campo deleted_at restaurando acceso completo. Después de 30 días, se ejecuta purga automática (hard-delete) de usuario y todos sus datos asociados.

## Requirements _(mandatory)_

### Functional Requirements

#### Navegación y UI

- **FR-001**: Sistema DEBE mostrar bottom navigation bar con 3 tabs (Dashboard, Estanques, Siembras) para usuarios con rol "user"
- **FR-002**: Sistema DEBE mostrar bottom navigation bar con 4 tabs (Dashboard, Estanques, Siembras, Admin) para usuarios con rol "admin"
- **FR-003**: Todos los formularios de creación y edición DEBEN implementarse en bottom sheet modals con altura adaptativa al contenido
- **FR-004**: Bottom sheets DEBEN ser dismiss-able tocando fuera del modal o botón "Cancelar"
- **FR-005**: Bottom sheets DEBEN crecer dinámicamente según el contenido hasta un máximo de 80% de la altura de pantalla; cuando el contenido excede ese límite, se activa scroll interno automáticamente
- **FR-006**: Todas las pantallas DEBEN usar SafeArea wrapper según Constitución Principio II

#### Dashboard

- **FR-007**: Pantalla Dashboard DEBE mostrar mensaje de bienvenida con nombre del usuario
- **FR-008**: Dashboard DEBE mostrar card con resúmen: "Total de Estanques" con número actualizado
- **FR-009**: Dashboard DEBE mostrar card con resúmen: "Siembras Activas" con número actualizado
- **FR-010**: Dashboard DEBE incluir botones de navegación rápida: "Ver Estanques", "Ver Siembras"
- **FR-011**: Cards de resúmen DEBEN ser touch-enabled y navegar a la pantalla correspondiente al tocarlos

#### Estanques

- **FR-012**: Pantalla Estanques DEBE mostrar listado en cards con: número estanque, capacidad, fecha creación
- **FR-013**: Card de estanque DEBE navegar a pantalla de detalle al tocarse
- **FR-014**: Detalle de estanque DEBE mostrar: número, capacidad, fecha creación, fecha última actualización, lista de siembras asociadas
- **FR-015**: Detalle de estanque DEBE tener botones "Editar" y "Eliminar"
- **FR-016**: FAB en listado de estanques DEBE abrir bottom sheet para crear nuevo estanque
- **FR-017**: Formulario de estanque DEBE validar: número único, capacidad > 0

#### Siembras

- **FR-018**: Pantalla Siembras DEBE mostrar listado en cards con: especie, estanque asociado, fecha siembra, cantidad inicial, muertes totales
- **FR-019**: Card de siembra DEBE navegar a pantalla de detalle al tocarse
- **FR-020**: Detalle de siembra DEBE tener dos pestañas: "Biometrías" y "Historial de Muertes"
- **FR-021**: Detalle de siembra DEBE mostrar información general: especie, estanque, fecha, cantidad inicial, muertes, cantidad actual
- **FR-022**: FAB en listado de siembras DEBE abrir bottom sheet para crear nueva siembra
- **FR-023**: Formulario de siembra DEBE requerir: especie, estanque (dropdown), fecha, cantidad inicial

#### Biometrías y Muertes

- **FR-024**: Pestaña Biometrías DEBE mostrar historial ordenado por fecha descendente con: fecha, peso promedio, tamaño promedio
- **FR-025**: FAB en pestaña Biometrías DEBE abrir bottom sheet para registrar nueva biometría
- **FR-026**: Formulario biometría DEBE requerir: fecha (default hoy), peso promedio (kg), tamaño promedio (cm)
- **FR-027**: Pestaña Historial de Muertes DEBE mostrar registros con: fecha, cantidad de muertes, observaciones
- **FR-028**: Botón en pestaña Muertes DEBE abrir bottom sheet para registrar muertes
- **FR-029**: Formulario de muertes DEBE requerir: fecha (default hoy), cantidad > 0, observaciones opcionales
- **FR-030**: Registrar muerte DEBE actualizar automáticamente contador total de muertes y cantidad actual de peces

#### Multi-tenancy

- **FR-031**: Cada tabla de datos DEBE tener columna user_id como foreign key a auth.users
- **FR-032**: Todos los queries SELECT DEBEN filtrar automáticamente por user_id del usuario autenticado
- **FR-033**: Todos los INSERT DEBEN asociar automáticamente el user_id del usuario autenticado
- **FR-034**: Row Level Security (RLS) DEBE estar habilitado en todas las tablas de datos
- **FR-035**: Policies DEBEN garantizar que usuarios solo accedan a sus propios datos
- **FR-036**: Admin NO DEBE tener acceso a datos de otros usuarios (cada admin gestiona su propio tenant)

#### Roles y Autenticación

- **FR-037**: Sistema DEBE soportar solo dos roles: "admin" y "user"
- **FR-038**: Rol DEBE almacenarse en tabla profiles con foreign key a auth.users
- **FR-039**: Usuario nuevo registrado desde la aplicación DEBE tener rol "user" por default automáticamente. El primer usuario admin DEBE ser creado manualmente en la base de datos por el equipo técnico durante la migración/instalación inicial.
- **FR-040**: Solo usuarios con rol "admin" pueden acceder a pantalla Admin
- **FR-041**: Cambio de rol DEBE recargar UI para mostrar/ocultar tab Admin

#### Auto-registro y Gestión de Perfil

- **FR-042**: Pantalla de login DEBE tener botón "Registrarse" visible para usuarios no autenticados
- **FR-043**: Formulario de registro DEBE requerir: email válido, contraseña (criterios FR-048), confirmar contraseña, nombre
- **FR-044**: Sistema DEBE validar que email no exista antes de crear cuenta, mostrando error "Este email ya está registrado" si duplicado
- **FR-045**: Al completar registro exitoso, sistema DEBE crear usuario con rol "user" y autenticarlo automáticamente
- **FR-046**: Usuario autenticado DEBE poder acceder a su perfil desde icono en AppBar y actualizar: nombre, cambiar contraseña. Email DEBE ser solo lectura.
- **FR-047**: AppBar superior DEBE mostrar icono de perfil en todas las pantallas para usuarios autenticados
- **FR-048**: Validación de contraseña (registro y cambio) DEBE cumplir: mínimo 8 caracteres, al menos 1 número, al menos 1 letra mayúscula. Caracteres especiales NO son obligatorios.
- **FR-049**: Usuario con rol "user" DEBE poder eliminar su propia cuenta desde su perfil mediante soft-delete
- **FR-050**: Usuario con rol "admin" NO DEBE poder eliminar su propia cuenta (sistema previene con mensaje)
- **FR-051**: Usuario con datos asociados (estanques) DEBE recibir advertencia antes de confirmar eliminación de cuenta
- **FR-052**: Usuario eliminado DEBE hacer soft-delete (marca deleted_at) no hard-delete

#### Consulta y Eliminación de Usuarios (Admin)

- **FR-053**: Pantalla Admin DEBE mostrar listado de usuarios con: email, rol, fecha creación, estado activo/inactivo
- **FR-054**: Admin DEBE poder ver detalles completos de cualquier usuario (solo lectura)
- **FR-055**: Admin DEBE poder eliminar usuario con rol "user" SOLO si no tiene estanques asociados
- **FR-056**: Sistema DEBE prevenir eliminación de usuarios con rol "admin" mostrando mensaje "No se pueden eliminar usuarios administradores"
- **FR-057**: Usuario eliminado por admin DEBE hacer soft-delete (marca deleted_at) no hard-delete

#### Gestión de Tablas de Alimentación (Admin)

- **FR-058**: Pantalla Admin DEBE tener sección "Tablas de Alimentación"
- **FR-059**: Admin DEBE poder crear tabla de referencia con: nombre, rangos de peso (min-max kg), % alimentación diaria, frecuencia (veces/día)
- **FR-060**: Admin DEBE poder editar tabla de referencia existente
- **FR-061**: Admin DEBE poder eliminar tabla de referencia con confirmación
- **FR-062**: Tabla de alimentación DEBE ser multi-tenant (user_id) y funcionar como datos de referencia independientes para cálculos

### Key Entities

- **users** (Supabase auth.users extendido con profiles):

  - id (UUID, PK)
  - email (string, unique)
  - nombre (string) - **NUEVO para perfil de usuario**
  - role (enum: 'admin', 'user', default: 'user')
  - created_at (timestamp)
  - deleted_at (timestamp, nullable)

- **estanques** (ponds):

  - id (UUID, PK)
  - user_id (UUID, FK to users) - **NUEVO para multi-tenancy**
  - numero (string, unique per user)
  - capacidad (float)
  - created_at (timestamp)
  - updated_at (timestamp)

- **siembras** (seedings):

  - id (UUID, PK)
  - user_id (UUID, FK to users) - **NUEVO para multi-tenancy**
  - estanque_id (UUID, FK to estanques)
  - especie (string)
  - fecha (date)
  - cantidad_inicial (integer)
  - cantidad_actual (integer, calculado)
  - muertes_totales (integer, calculado)
  - created_at (timestamp)
  - updated_at (timestamp)

- **biometria** (biometrics):

  - id (UUID, PK)
  - user_id (UUID, FK to users) - **NUEVO para multi-tenancy**
  - siembra_id (UUID, FK to siembras)
  - fecha (date)
  - peso_promedio (float, kg)
  - tamano_promedio (float, cm)
  - created_at (timestamp)

- **muertes** (deaths) - **NUEVA TABLA**:

  - id (UUID, PK)
  - user_id (UUID, FK to users)
  - siembra_id (UUID, FK to siembras)
  - fecha (date)
  - cantidad (integer)
  - observaciones (text, nullable)
  - created_at (timestamp)

- **tablas_alimentacion** (feeding tables) - **NUEVA TABLA**:

  - id (UUID, PK)
  - user_id (UUID, FK to users)
  - nombre (string)
  - peso_min (float, kg)
  - peso_max (float, kg)
  - porcentaje_alimentacion (float)
  - frecuencia_diaria (integer)
  - created_at (timestamp)
  - updated_at (timestamp)

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Usuarios pueden navegar entre las 3 pantallas principales en menos de 1 segundo mediante bottom navigation
- **SC-002**: Usuarios pueden crear un nuevo estanque en menos de 30 segundos usando bottom sheet modal
- **SC-003**: Usuarios pueden registrar una biometría en menos de 20 segundos desde detalle de siembra
- **SC-004**: 100% de aislamiento de datos: Usuario A nunca ve datos de Usuario B en ninguna pantalla
- **SC-005**: Nuevo usuario puede completar proceso de auto-registro en menos de 2 minutos
- **SC-006**: Usuario puede actualizar su perfil (nombre, contraseña) en menos de 1 minuto
- **SC-007**: Sistema previene el 100% de intentos de eliminación de usuarios admin o con datos asociados (sin confirmación)
- **SC-008**: Bottom sheets se cargan y responden en menos de 300ms en dispositivos mid-range
- **SC-009**: Todas las operaciones CRUD mantienen consistencia de datos multi-tenant sin excepciones

## Assumptions

1. **Supabase Row Level Security**: Se asume que Supabase RLS está disponible y funcionando correctamente para implementar multi-tenancy
2. **Supabase Auth**: Se asume que Supabase Auth soporta registro de usuarios con email/contraseña y gestión de perfiles
3. **Migración de datos existentes**: La aplicación actual tiene un único usuario. Durante la migración multi-tenant, todos los datos existentes (estanques, siembras, biometrías) se asignarán automáticamente al user_id de ese usuario único existente. El script de migración identificará al primer usuario en auth.users o creará un usuario admin por defecto si no existe ninguno.
4. **Sin soporte offline**: Fase 1 requiere conexión a internet, offline vendrá en futuras iteraciones
5. **Dispositivos objetivo**: Android 8+ e iOS 13+ según capacidades de Flutter 3.38.1
6. **Roles estáticos**: No se soportan permisos granulares más allá de admin/user en esta fase

## Dependencies

- Supabase RLS policies para multi-tenancy
- Supabase Auth para registro y autenticación de usuarios
- Migración de schema de DB para agregar user_id a tablas existentes y campo nombre en profiles

## Out of Scope (for this phase)

- ❌ Módulo de Alimentación automática (tabla de alimentación se crea pero no se usa aún)
- ❌ Dashboard con gráficas (se simplifica a cards informativas)
- ❌ Reportes y exportación de datos
- ❌ Notificaciones push
- ❌ Modo offline/sincronización
- ❌ Permisos granulares más allá de admin/user
- ❌ Multi-organización (cada admin es su propio tenant separado)
- ❌ Auditoría de cambios (quién editó qué)
- ❌ Búsqueda y filtros avanzados en listados

## Notes

- **Breaking changes**: Esta refactorización rompe compatibilidad con versión actual. Requiere migración de datos y actualización forzada.
- **Priorización**: Implementar User Stories en orden P1 → P2 → P3 permite entregas incrementales
- **Testing**: Cada User Story tiene escenarios de aceptación que se convierten directamente en tests según Constitución Principio III
