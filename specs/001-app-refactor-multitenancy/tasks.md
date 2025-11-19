# Tasks: App Refactor - Multi-tenancy & UI/UX Redesign

**Input**: Design documents from `/specs/001-app-refactor-multitenancy/`
**Prerequisites**: plan.md (completed), spec.md (completed)

**Tests**: NO TESTS - Testing has been deferred to a future phase per project decision

**Organization**: Tasks are grouped by user story to enable independent implementation of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a Flutter mobile project with the following structure:

- **Source code**: `lib/` (models, services, screens, widgets, config)
- **Database migrations**: `supabase/migrations/`
- **Assets**: `assets/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create supabase/ directory structure with migrations/ and seed/ subdirectories
- [x] T002 [P] Create lib/models/ directory for data model classes
- [x] T003 [P] Create lib/widgets/ directory for reusable UI components
- [x] T004 [P] Update pubspec.yaml dependencies if needed (verify supabase_flutter ^2.0.0, flutter_dotenv ^6.0.0, intl ^0.20.2)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Database Schema & Multi-tenancy Foundation

- [x] T005 Create migration supabase/migrations/20251116_add_profiles_table.sql to create profiles table (id FK to auth.users, role enum, nombre string, created_at, deleted_at)
- [x] T006 Create migration supabase/migrations/20251116_add_user_id_to_estanques.sql to add user_id UUID column to estanques with FK to auth.users and unique constraint on (user_id, numero)
- [x] T007 Create migration supabase/migrations/20251116_add_user_id_to_siembras.sql to add user_id UUID column to siembras with FK to auth.users
- [x] T008 Create migration supabase/migrations/20251116_add_user_id_to_biometria.sql to add user_id UUID column to biometria with FK to auth.users
- [x] T009 Create migration supabase/migrations/20251116_create_muertes_table.sql for muertes table (id, user_id, siembra_id, fecha, cantidad, observaciones, created_at)
- [x] T010 Create migration supabase/migrations/20251116_create_tablas_alimentacion_table.sql for tablas_alimentacion reference table (id, user_id, nombre, peso_min, peso_max, porcentaje_alimentacion, frecuencia_diaria, created_at, updated_at) - Independent reference data with NO foreign keys to other entities
- [x] T011 Create migration supabase/migrations/20251116_enable_rls_policies.sql to enable RLS on all tables and create policies for user_id filtering
- [x] T012 Create migration supabase/migrations/20251116_migrate_existing_data.sql to assign all existing data to first user in auth.users
- [x] T013 Create seed script supabase/seed/create_first_admin.sql with SQL to create first admin user in profiles table

### Data Models

- [x] T014 [P] Create UserProfile model in lib/models/user_profile.dart with fields (id, email, nombre, role, createdAt, deletedAt)
- [x] T015 [P] Create Estanque model in lib/models/estanque.dart with fields (id, userId, numero, capacidad, createdAt, updatedAt)
- [x] T016 [P] Create Siembra model in lib/models/siembra.dart with fields (id, userId, estanqueId, especie, fecha, cantidadInicial, cantidadActual, muertesTotales, createdAt, updatedAt)
- [x] T017 [P] Create Biometria model in lib/models/biometria.dart with fields (id, userId, siembraId, fecha, pesoPromedio, tamanoPromedio, createdAt)
- [x] T018 [P] Create Muerte model in lib/models/muerte.dart with fields (id, userId, siembraId, fecha, cantidad, observaciones, createdAt)
- [x] T019 [P] Create TablaAlimentacion model in lib/models/tabla_alimentacion.dart with fields (id, userId, nombre, pesoMin, pesoMax, porcentajeAlimentacion, frecuenciaDiaria, createdAt, updatedAt) - Reference data model with no relationships to other entities

### Core Services with Multi-tenancy

- [x] T020 Refactor auth_service.dart in lib/services/ to add registration method with email, password, nombre (creates user in auth.users and profile with role 'user')
- [x] T021 [P] Create ProfilesService in lib/services/profiles_service.dart with methods: getCurrentUserProfile(), updateProfile(nombre), changePassword(), deleteAccount() with soft-delete
- [x] T022 [P] Create AdminService in lib/services/admin_service.dart with methods: getAllUsers(), getUserById(), deleteUser() with validations (no estanques, not admin)
- [x] T023 Refactor EstanquesService in lib/services/estanques_service.dart to filter queries by current user_id and auto-add user_id on create
- [x] T024 Refactor SiembrasService in lib/services/siembras_service.dart to filter queries by current user_id and auto-add user_id on create
- [x] T025 Refactor BiometriaService in lib/services/biometria_service.dart to filter queries by current user_id and auto-add user_id on create
- [x] T026 [P] Create MuertesService in lib/services/muertes_service.dart with CRUD methods filtered by user_id
- [x] T027 [P] Create TablasAlimentacionService in lib/services/tablas_alimentacion_service.dart with CRUD methods filtered by user_id - Service for independent reference data used in feeding calculations

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 7 - Auto-registro y Gestión de Perfil (Priority: P1) 🎯 MVP Foundation

**Goal**: Enable user self-registration and profile management to allow onboarding and account control

**Independent Test**: Open app without login, complete registration form, login with new credentials, access profile from AppBar icon, update name, verify changes persist

### Implementation for User Story 7

- [x] T028 [P] [US7] Create RegisterScreen in lib/screens/register_screen.dart with form fields (email, password, confirm password, nombre) and validation
- [x] T029 [P] [US7] Create ProfileScreen in lib/screens/profile_screen.dart showing user info (email read-only, nombre editable, change password, delete account button)
- [x] T030 [US7] Update LoginScreen in lib/screens/login_screen.dart to add "Registrarse" button that navigates to RegisterScreen
- [x] T031 [US7] Implement registration logic in RegisterScreen: call auth_service.register(), validate password criteria (8+ chars, 1 number, 1 uppercase), confirm password match, handle error "Este email ya está registrado"
- [x] T032 [US7] Implement profile update logic in ProfileScreen: update nombre via ProfilesService, change password with validation, soft-delete account with confirmation (prevent if admin role)
- [x] T033 [US7] Add validation in ProfileScreen to show warning if user has estanques before account deletion

**Checkpoint**: User registration and profile management functional - users can onboard autonomously

---

## Phase 4: User Story 1 - Navegación Simplificada (Priority: P1) 🎯 MVP Core

**Goal**: Implement bottom navigation with 3 main screens (Dashboard, Estanques, Siembras) + conditional Admin tab

**Independent Test**: Launch app as authenticated user, verify 3 tabs in bottom navigation, tap each tab to navigate, verify screens load correctly. Login as admin and verify 4th Admin tab appears

### Implementation for User Story 1

- [x] T034 [P] [US1] Create CustomAppBar widget in lib/widgets/custom_app_bar.dart with profile icon that navigates to ProfileScreen
- [x] T035 [P] [US1] Create DashboardScreen skeleton in lib/screens/dashboard_screen.dart with SafeArea wrapper
- [x] T036 [US1] Refactor HomeScreen in lib/screens/home_screen.dart to implement BottomNavigationBar with 3-4 tabs based on user role (Dashboard, Estanques, Siembras, Admin for admins only)
- [x] T037 [US1] Integrate CustomAppBar in all main screens (DashboardScreen, EstanquesScreen, SiembrasScreen, AdminScreen)
- [x] T038 [US1] Implement navigation logic in HomeScreen to switch between screens when tapping bottom nav tabs, preserving state
- [x] T039 [US1] Add role check to conditionally show/hide Admin tab based on current user's role from ProfilesService

**Checkpoint**: Bottom navigation functional - users can navigate between main screens

---

## Phase 5: User Story 1 Extension - Dashboard Content (Priority: P1) 🎯 MVP Core

**Goal**: Populate Dashboard with summary cards showing key metrics

**Independent Test**: Navigate to Dashboard, verify summary cards display correct counts for estanques and siembras activas, tap cards to navigate to respective screens

### Implementation for Dashboard

- [x] T040 [P] [US1] Create SummaryCard widget in lib/widgets/summary_card.dart with props (title, value, icon, onTap)
- [x] T041 [US1] Implement Dashboard content in DashboardScreen: fetch total estanques count from EstanquesService
- [x] T042 [US1] Add siembras activas count to Dashboard using SiembrasService
- [x] T043 [US1] Add SummaryCard widgets for "Total de Estanques" and "Siembras Activas" with navigation onTap
- [x] T044 [US1] Add quick action buttons "Ver Estanques" and "Ver Siembras" that navigate using bottom nav

**Checkpoint**: Dashboard provides value with summary metrics and quick navigation

---

## Phase 6: User Story 3 - Listados con Navegación a Detalle (Priority: P1) 🎯 MVP Core

**Goal**: Display estanques and siembras in card lists, navigate to detail screens with edit/delete options

**Independent Test**: Navigate to Estanques, verify cards display with data, tap card to see detail, verify edit/delete buttons work. Repeat for Siembras

### Implementation for User Story 3

- [x] T045 [P] [US3] Refactor EstanquesScreen in lib/screens/estanques_screen.dart to display list of estanque cards with numero, capacidad, fecha creacion
- [x] T046 [P] [US3] Refactor SiembrasScreen in lib/screens/siembras_screen.dart to display list of siembra cards with especie, estanque, fecha, cantidad inicial, muertes totales
- [x] T047 [US3] Refactor EstanqueDetalleScreen in lib/screens/estanque_detalle_screen.dart to show full estanque details (numero, capacidad, created_at, updated_at, siembras asociadas)
- [x] T048 [US3] Add "Editar" and "Eliminar" buttons to EstanqueDetalleScreen
- [x] T049 [US3] Implement navigation from EstanquesScreen cards to EstanqueDetalleScreen passing estanque id
- [x] T050 [US3] Refactor SiembraDetalleScreen in lib/screens/siembra_detalle_screen.dart to show full siembra details
- [x] T051 [US3] Add "Editar" and "Eliminar" buttons to SiembraDetalleScreen
- [x] T052 [US3] Implement navigation from SiembrasScreen cards to SiembraDetalleScreen passing siembra id
- [x] T053 [US3] Implement delete confirmation dialog for estanques with validation (check siembras asociadas)
- [x] T054 [US3] Implement delete confirmation dialog for siembras

**Checkpoint**: Users can view and manage estanques and siembras through list and detail screens

---

## Phase 7: User Story 2 - Formularios en Bottom Sheet (Priority: P1) 🎯 MVP Core

**Goal**: Implement all CRUD forms as bottom sheet modals with dynamic height

**Independent Test**: Tap FAB in EstanquesScreen, verify bottom sheet appears from bottom, fill form, save, verify sheet closes and list refreshes. Test dismiss by tapping outside. Test with validation errors to verify sheet grows and enables scroll

### Implementation for User Story 2

- [x] T055 [P] [US2] Create BottomSheetForm widget in lib/widgets/bottom_sheet_form.dart with dynamic height (max 80% screen) and scroll when content exceeds
- [x] T056 [US2] Create EstanqueFormSheet using BottomSheetForm in lib/widgets/ with fields (numero, capacidad) and validation (FR-017: numero must be unique within user_id scope, capacidad > 0)
- [x] T057 [US2] Create SiembraFormSheet using BottomSheetForm in lib/widgets/ with fields (especie, estanque dropdown, fecha, cantidad inicial) and validation
- [x] T058 [US2] Add FAB to EstanquesScreen that opens EstanqueFormSheet via showModalBottomSheet
- [x] T059 [US2] Add FAB to SiembrasScreen that opens SiembraFormSheet via showModalBottomSheet
- [x] T060 [US2] Connect "Editar" button in EstanqueDetalleScreen to open EstanqueFormSheet with pre-filled data
- [x] T061 [US2] Connect "Editar" button in SiembraDetalleScreen to open SiembraFormSheet with pre-filled data
- [x] T062 [US2] Implement save logic in EstanqueFormSheet: validate numero uniqueness (check existing estanques for current user), call EstanquesService.create() or update(), handle duplicate error, close sheet, refresh list
- [x] T063 [US2] Implement save logic in SiembraFormSheet: call SiembrasService.create() or update(), close sheet, refresh list
- [x] T064 [US2] Implement dismiss on tap outside or "Cancelar" button for all bottom sheets
- [x] T065 [US2] Add validation error display in forms that prevents submission but keeps sheet open

**Checkpoint**: All CRUD operations use bottom sheet modals with proper UX - MVP is feature complete for basic usage

---

## Phase 8: User Story 4 - Biometrías y Muertes (Priority: P2)

**Goal**: Enable tracking of biometrics and deaths within siembra details using tabs

**Independent Test**: Navigate to siembra detail, verify two tabs (Biometrías, Historial de Muertes), register biometría via FAB in bottom sheet, verify appears in list. Register muerte, verify counter updates and appears in history

### Implementation for User Story 4

- [x] T066 [US4] Add TabBar to SiembraDetalleScreen with two tabs: "Biometrías" and "Historial de Muertes"
- [x] T067 [P] [US4] Create BiometriasTab widget showing list of biometria records ordered by fecha descending
- [x] T068 [P] [US4] Create MuertesTab widget showing list of muerte records with fecha, cantidad, observaciones
- [x] T069 [P] [US4] Create BiometriaFormSheet using BottomSheetForm with fields (fecha default today, peso promedio kg, tamano promedio cm)
- [x] T070 [P] [US4] Create MuerteFormSheet using BottomSheetForm with fields (fecha default today, cantidad > 0, observaciones optional)
- [x] T071 [US4] Add FAB to BiometriasTab that opens BiometriaFormSheet via showModalBottomSheet
- [x] T072 [US4] Add button to MuertesTab that opens MuerteFormSheet via showModalBottomSheet
- [x] T073 [US4] Implement save logic in BiometriaFormSheet: call BiometriaService.create(), close sheet, refresh tab
- [x] T074 [US4] Implement save logic in MuerteFormSheet: call MuertesService.create(), update siembra muertes_totales and cantidad_actual, close sheet, refresh tab
- [x] T075 [US4] Implement tap on biometria record to show detail view with edit/delete options

**Checkpoint**: Biometrics and deaths tracking fully functional within siembra management

---

## Phase 9: User Story 5 - Multi-tenancy Verification (Priority: P2)

**Goal**: Verify RLS policies enforce complete data isolation between users

**Independent Test**: Create 2 test users, login with each, create estanques/siembras, verify User A never sees User B's data in any screen. Test direct URL access with other user's IDs returns 403 or not found

### Verification Tasks for User Story 5

- [x] T076 [US5] Verify EstanquesService queries filter by user_id and return only current user's estanques
- [x] T077 [US5] Verify SiembrasService queries filter by user_id and return only current user's siembras
- [x] T078 [US5] Verify BiometriaService queries filter by user_id and return only current user's biometrias
- [x] T079 [US5] Verify MuertesService queries filter by user_id and return only current user's muertes
- [x] T080 [US5] Verify RLS policies on Supabase prevent cross-user data access at database level
- [x] T081 [US5] Test user creation automatically associates user_id on INSERT operations
- [x] T082 [US5] Test logout/login with different users shows completely different data sets

**Checkpoint**: Multi-tenancy verified - data isolation is guaranteed

---

## Phase 10: User Story 6 - Consulta y Eliminación de Usuarios Admin (Priority: P3)

**Goal**: Provide admin interface to view all users and delete users with validations

**Independent Test**: Login as admin, navigate to Admin tab, view user list with details, attempt to delete user with estanques (should fail), delete user without data (should succeed), attempt to delete admin user (should fail)

### Implementation for User Story 6

- [x] T083 [P] [US6] Create AdminScreen in lib/screens/admin_screen.dart with sections for Users and Tablas de Alimentación
- [x] T084 [P] [US6] Create UserListTile widget in lib/widgets/user_list_tile.dart to display user info (email, role, fecha creación, estado)
- [x] T085 [US6] Implement Users section in AdminScreen: fetch all users via AdminService.getAllUsers(), display in list
- [x] T086 [US6] Add user detail view showing complete user information (read-only)
- [x] T087 [US6] Implement "Eliminar" button for users with validations: check role != 'admin', check no estanques associated via EstanquesService
- [x] T088 [US6] Show appropriate error messages: "No se pueden eliminar usuarios administradores" or "Usuario tiene datos asociados, debe eliminar estanques primero"
- [x] T089 [US6] Implement soft-delete via AdminService.deleteUser() setting deleted_at timestamp
- [x] T090 [US6] Add confirmation dialog before user deletion

**Checkpoint**: Admin can manage users with proper safeguards

---

## Phase 11: User Story 8 - Gestión de Tablas de Alimentación (Priority: P3)

**Goal**: Allow admins to create and manage feeding tables for calculation parameters

**Independent Test**: Navigate to Tablas de Alimentación section as admin, create new tabla with weight ranges and percentages, edit existing tabla, verify data persists. Attempt to delete tabla in use and verify confirmation warning

### Implementation for User Story 8

- [x] T091 [P] [US8] Create TablasAlimentacionSection widget for AdminScreen showing list of feeding tables
- [x] T092 [P] [US8] Create TablaAlimentacionFormSheet using BottomSheetForm with fields (nombre, peso_min, peso_max, porcentaje_alimentacion, frecuencia_diaria)
- [x] T093 [US8] Add "Nueva tabla" button in TablasAlimentacionSection that opens TablaAlimentacionFormSheet
- [x] T094 [US8] Implement save logic in TablaAlimentacionFormSheet: call TablasAlimentacionService.create() or update()
- [x] T095 [US8] Add edit button for each tabla in list that opens form with pre-filled data
- [x] T096 [US8] Implement delete logic with confirmation dialog checking if tabla is in use by active siembras
- [x] T097 [US8] Show warning "Esta tabla está en uso por siembras activas" when attempting to delete tabla in use

**Checkpoint**: Feeding tables management complete - all admin features implemented

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final quality checks

- [x] T098 [P] Update README.md with new navigation structure, features, and setup instructions
- [x] T099 [P] Create .env.example file with required Supabase configuration variables
- [x] T100 Deprecate old pages/ directory: move biometria_page.dart, dashboard_page.dart, estanques_page.dart, home_page.dart, siembras_page.dart to archive or delete
- [x] T101 Verify all screens use SafeArea wrapper as per Constitution Principle II
- [x] T102 Add loading indicators for all async operations (service calls)
- [x] T103 Add SnackBar success/error messages for all CRUD operations
- [x] T104 Verify password validation criteria (8+ chars, 1 number, 1 uppercase) in registration and profile change
- [x] T105 Add confirmation dialogs for all destructive actions (delete estanque, siembra, user, account)
- [x] T106 Optimize bottom sheet performance: test on mid-range devices, verify <300ms load time
- [ ] T107 Verify multi-tenancy data isolation: run manual tests with multiple users
- [ ] T108 [P] Run database migrations on staging environment and validate data integrity
- [x] T109 Performance optimization: add indexes on user_id columns if not already present
- [ ] T110 Validate quickstart.md instructions by setting up fresh environment
- [x] T111 Code cleanup: remove unused imports, format code with `dart format`
- [x] T112 Security review: verify RLS policies, check for hardcoded credentials (constitution debt item)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-11)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order: P1 (US7, US1, US3, US2) → P2 (US4, US5) → P3 (US6, US8)
- **Polish (Phase 12)**: Depends on all desired user stories being complete

### User Story Dependencies

**Priority 1 (MVP):**

- **User Story 7 (Auto-registro)**: Can start after Foundational (Phase 2) - No dependencies on other stories - MUST be first for user onboarding
- **User Story 1 (Navegación)**: Depends on US7 (needs ProfileService for role check, AppBar profile icon) - Core navigation structure
- **User Story 3 (Listados)**: Depends on US1 (navigation must exist) - Data display layer
- **User Story 2 (Bottom Sheets)**: Depends on US3 (needs screens to attach forms to) - UI interaction layer

**Priority 2:**

- **User Story 4 (Biometrías/Muertes)**: Depends on US3 (needs SiembraDetalleScreen) - Extends siembra management
- **User Story 5 (Multi-tenancy)**: Can verify after US7, US1, US3, US2 complete - Validates security

**Priority 3:**

- **User Story 6 (Admin Users)**: Depends on US1 (Admin tab in navigation), US7 (user management) - Admin feature
- **User Story 8 (Tablas Alimentación)**: Depends on US1, US6 (Admin screen structure) - Admin feature

### Within Each User Story

- Database migrations before models
- Models before services
- Services before screens/widgets
- Core screens before forms
- Forms before detail views
- Validation after core functionality

### Parallel Opportunities

- **Phase 1 Setup**: All T001-T004 tasks can run in parallel
- **Phase 2 Foundational**:
  - Migrations T005-T012 must run sequentially (order matters)
  - Models T014-T019 can all run in parallel (different files)
  - Services: ProfilesService (T021), AdminService (T022), MuertesService (T026), TablasAlimentacionService (T027) can run in parallel
- **Phase 3-11 User Stories**: If team has capacity, different developers can work on different user stories simultaneously AFTER foundational phase
- **Within US7**: RegisterScreen (T028) and ProfileScreen (T029) can be built in parallel
- **Within US1**: CustomAppBar (T034) and DashboardScreen (T035) can be built in parallel
- **Within US1 Extension**: SummaryCard widget (T040) can be built while implementing Dashboard content (T041-T044)
- **Within US3**: EstanquesScreen (T045) and SiembrasScreen (T046) refactors can run in parallel
- **Within US2**: All form sheets (T056, T057, T069, T070, T092) can be built in parallel by different developers
- **Within US4**: BiometriasTab (T067) and MuertesTab (T068) can be built in parallel, as can the two form sheets (T069, T070)
- **Within US6**: AdminScreen (T083) and UserListTile (T084) can be built in parallel
- **Within US8**: TablasAlimentacionSection (T091) and TablaAlimentacionFormSheet (T092) can be built in parallel
- **Phase 12 Polish**: Most tasks (T098, T099, T104, T108, T111) can run in parallel

---

## Parallel Example: User Story 2 - Bottom Sheets

```bash
# Once US1 and US3 are complete, all form sheets can be built in parallel:
Task: "Create EstanqueFormSheet using BottomSheetForm in lib/widgets/" (T056)
Task: "Create SiembraFormSheet using BottomSheetForm in lib/widgets/" (T057)
Task: "Create BiometriaFormSheet using BottomSheetForm with fields" (T069)
Task: "Create MuerteFormSheet using BottomSheetForm with fields" (T070)
Task: "Create TablaAlimentacionFormSheet using BottomSheetForm with fields" (T092)

# These can all be developed simultaneously by different team members
```

---

## Implementation Strategy

### MVP First (P1 User Stories Only)

1. Complete Phase 1: Setup → Foundation structure ready
2. Complete Phase 2: Foundational → Multi-tenancy and models ready (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 7 → Users can register and manage profiles
4. Complete Phase 4: User Story 1 → Bottom navigation established
5. Complete Phase 5: User Story 1 Extension → Dashboard has value
6. Complete Phase 6: User Story 3 → Users can view and navigate data
7. Complete Phase 7: User Story 2 → Users can create/edit via bottom sheets
8. **STOP and VALIDATE**: Test complete user journey (register → navigate → view lists → CRUD estanques/siembras)
9. Deploy MVP if ready

**MVP Scope**: 7 phases, ~65 tasks, delivers core functionality for regular users to manage estanques and siembras

### Incremental Delivery

1. **Foundation** (Phase 1-2) → Database and models ready
2. **MVP** (Phase 3-7) → Core app usable by regular users
3. **Enhanced Features** (Phase 8-9) → Biometrics tracking + multi-tenancy validation
4. **Admin Features** (Phase 10-11) → Admin can manage users and feeding tables
5. **Production Ready** (Phase 12) → Polished and optimized

Each phase adds value without breaking previous functionality.

### Parallel Team Strategy

With multiple developers, after Foundational phase completes:

**Team A (Frontend Lead):**

- User Story 7 (Registration/Profile) → Phase 3
- User Story 1 (Navigation) → Phase 4-5
- User Story 2 (Bottom Sheets) → Phase 7

**Team B (CRUD Developer):**

- User Story 3 (Lists/Details) → Phase 6
- User Story 4 (Biometrics) → Phase 8

**Team C (Admin Developer):**

- User Story 6 (Admin Users) → Phase 10
- User Story 8 (Feeding Tables) → Phase 11

**Team D (QA/DevOps):**

- User Story 5 (Multi-tenancy Validation) → Phase 9
- Polish & Testing → Phase 12

Stories complete and integrate independently.

---

## Task Summary

**Total Tasks**: 112 tasks

- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 23 tasks (migrations + models + services)
- Phase 3 (US7 - Auto-registro): 6 tasks
- Phase 4 (US1 - Navegación): 6 tasks
- Phase 5 (US1 Extension - Dashboard): 5 tasks
- Phase 6 (US3 - Listados): 10 tasks
- Phase 7 (US2 - Bottom Sheets): 11 tasks
- Phase 8 (US4 - Biometrías/Muertes): 10 tasks
- Phase 9 (US5 - Multi-tenancy): 7 tasks
- Phase 10 (US6 - Admin Users): 8 tasks
- Phase 11 (US8 - Tablas Alimentación): 7 tasks
- Phase 12 (Polish): 15 tasks

**Parallel Opportunities**: ~35 tasks marked [P] can run in parallel within their phase

**MVP Scope**: Phases 1-7 (65 tasks) deliver functional app for regular users

**User Story Breakdown**:

- US7 (Auto-registro): 6 tasks
- US1 (Navegación + Dashboard): 11 tasks
- US2 (Bottom Sheets): 11 tasks
- US3 (Listados): 10 tasks
- US4 (Biometrías/Muertes): 10 tasks
- US5 (Multi-tenancy): 7 tasks
- US6 (Admin Users): 8 tasks
- US8 (Tablas Alimentación): 7 tasks

**Independent Testing**: Each user story can be tested independently once its phase completes

---

## Notes

- [P] tasks = different files, no dependencies within phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Tests are EXCLUDED per project decision (testing deferred to future phase)
- All tasks include exact file paths for clarity
- Multi-tenancy is baked into services layer (T020-T027) for data isolation
- Bottom sheets use dynamic height pattern (max 80% screen + scroll)
- SafeArea mandatory per Constitution Principle II
- RLS policies critical for multi-tenancy security (T011)
