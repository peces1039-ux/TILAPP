# Implementation Plan: App Refactor - Multi-tenancy & UI/UX Redesign

**Branch**: `001-app-refactor-multitenancy` | **Date**: 2025-11-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-app-refactor-multitenancy/spec.md`

**Note**: This plan follows the `/speckit.plan` workflow. Phase 0 (research.md), Phase 1 (data-model.md, contracts/, quickstart.md), and agent context update will be generated after this plan.

## Summary

**Primary Requirement**: Refactorizar aplicación TILAPP con navegación simplificada (3 pantallas principales), formularios en bottom sheet modals, multi-tenancy con aislamiento de datos por usuario, auto-registro de usuarios, y gestión de perfiles/usuarios admin.

**Technical Approach**:

- Migrar arquitectura de navegación actual a bottom navigation bar con 3 tabs (Dashboard, Estanques, Siembras) + tab Admin condicional
- Implementar bottom sheet modals para todos los formularios CRUD usando showModalBottomSheet de Flutter con altura dinámica
- Agregar multi-tenancy mediante user_id en todas las tablas y Row Level Security (RLS) policies en Supabase
- Implementar auto-registro con Supabase Auth y gestión de perfiles con roles (admin/user)
- Migrar datos existentes al primer usuario identificado en auth.users
- Crear tabla profiles para almacenar rol y nombre de usuario
- Agregar tablas nuevas: muertes, tablas_alimentacion
- Implementar AppBar con icono de perfil en todas las pantallas
- Dashboard con cards informativos de resumen

## Technical Context

**Language/Version**: Dart 3.9.2+
**Framework**: Flutter 3.38.1+
**Primary Dependencies**:

- supabase_flutter ^2.0.0 (database, auth, real-time, RLS)
- flutter_dotenv ^6.0.0 (environment configuration)
- intl ^0.20.2 (date formatting)
- flutter_secure_storage (session tokens)

**Storage**: Supabase PostgreSQL con Row Level Security (RLS) habilitado
**Target Platform**: Android 8+, iOS 13+ (según capacidades Flutter 3.38.1)
**Project Type**: Mobile app (Flutter single codebase) + Backend as a Service (Supabase)
**Performance Goals**:

- Navegación entre pantallas: <1s
- Bottom sheets: <300ms en dispositivos mid-range
- Operaciones CRUD: <2s con feedback visual
- Auto-registro completo: <2min

**Constraints**:

- SafeArea obligatorio en todas las pantallas (Constitution Principle II)
- Multi-tenancy con 100% aislamiento de datos (SC-004)
- Bottom sheets altura máxima 80% de pantalla con scroll dinámico
- Sin modo offline en Fase 1

**Scale/Scope**:

- 8 User Stories (4 P1, 2 P2, 2 P3)
- 61 Functional Requirements
- 6 entidades de datos (3 nuevas: profiles, muertes, tablas_alimentacion)
- 3 pantallas principales + 1 Admin condicional
- Sistema multi-usuario con roles (admin/user)

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Principle I: Data-Driven Design

**Status**: ✅ **PASS** (with migration required)

- Spec defines 6 key entities with clear relationships (users, estanques, siembras, biometria, muertes, tablas_alimentacion)
- All tables have user_id for multi-tenancy (FR-031)
- Foreign key relationships documented: estanques → siembras → biometria/muertes
- CRUD operations specified in 61 FRs
- **Migration needed**: Existing tables (estanques, siembras, biometria) need user_id column added
- **Migration needed**: New table profiles for storing role and nombre
- **Migration needed**: New tables muertes and tablas_alimentacion

### Principle II: Mobile-First & Usability

**Status**: ✅ **PASS**

- Bottom navigation bar with 3-4 tabs specified (FR-001, FR-002)
- All forms use bottom sheet modals with altura dinámica (FR-003 to FR-005)
- SafeArea explicitly required (FR-006)
- Touch-optimized: cards touch-enabled, FAB for actions, AppBar con icono de perfil (FR-047)
- Material Design patterns: bottom sheets, SnackBar for feedback
- Responsive: bottom sheets adapt to content dynamically up to 80% screen height

### Principle III: Test-First

**Status**: ❌ **NOT APPLICABLE**

- Testing is explicitly excluded from this feature implementation
- Project decision: Focus on rapid feature delivery without test coverage
- **Note**: This represents a deviation from the constitution. Constitution may need update to reflect current development practices.

### Principle IV: Integration & Data Consistency

**Status**: ✅ **PASS**

- Supabase integration maintained for auth and database
- RLS policies required for multi-tenancy (FR-034, FR-035)
- Foreign key constraints explicit in data model
- Data integrity checks: prevent deletion with associations (FR-055, FR-051)
- Error handling in edge cases documented
- Multi-tenant query filtering automated (FR-032, FR-033)

### Principle V: Observability & Simplicity

**Status**: ✅ **PASS**

- SnackBar for user feedback implied in acceptance scenarios
- Error messages specified (e.g., "Este email ya está registrado" in FR-044)
- Success/failure feedback for all actions
- Simplicity: Reduced from complex navigation to 3 main screens
- Clear separation: services for logic, widgets for UI (existing pattern maintained)
- **Note**: Debug logging will be maintained per existing codebase patterns

### Overall Assessment

**🟢 ALL GATES PASS** - Feature is compliant with constitution. No violations or exceptions needed.

**Critical Points**:

1. Database migration is breaking change - requires careful planning and execution
2. RLS policies are new - requires research and validation in Phase 0
3. Multi-tenancy is architectural change - requires validation of Supabase RLS capabilities
4. **Testing excluded**: No automated tests will be implemented - manual validation only

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

## Project Structure

### Documentation (this feature)

```text
specs/001-app-refactor-multitenancy/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (in progress)
├── research.md          # Phase 0 output (to be created)
├── data-model.md        # Phase 1 output (to be created)
├── quickstart.md        # Phase 1 output (to be created)
├── contracts/           # Phase 1 output (to be created)
│   ├── auth.md
│   ├── estanques.md
│   ├── siembras.md
│   ├── biometria.md
│   ├── admin.md
│   └── profiles.md
└── checklists/
    └── requirements.md  # Quality validation (completed)
```

### Source Code (repository root)

```text
lib/
├── main.dart                    # App entry point
├── config/
│   └── supabase_config.dart     # Supabase initialization
├── models/                      # NEW: Data models
│   ├── user_profile.dart        # User with role
│   ├── estanque.dart
│   ├── siembra.dart
│   ├── biometria.dart
│   ├── muerte.dart              # NEW entity
│   └── tabla_alimentacion.dart  # NEW entity
├── services/
│   ├── auth_service.dart        # REFACTOR: Add registration
│   ├── auth_guard.dart
│   ├── estanques_service.dart   # REFACTOR: Add multi-tenancy
│   ├── siembras_service.dart    # REFACTOR: Add multi-tenancy
│   ├── biometria_service.dart   # REFACTOR: Add multi-tenancy
│   ├── muertes_service.dart     # NEW service
│   ├── profiles_service.dart    # NEW service
│   └── admin_service.dart       # NEW service
├── screens/
│   ├── login_screen.dart        # REFACTOR: Add registration button
│   ├── register_screen.dart     # NEW screen
│   ├── profile_screen.dart      # NEW screen
│   ├── home_screen.dart         # REFACTOR: Bottom navigation
│   ├── dashboard_screen.dart    # REFACTOR: Add summary cards
│   ├── estanques_screen.dart    # REFACTOR: Multi-tenancy
│   ├── estanque_detalle_screen.dart  # REFACTOR: Bottom sheets
│   ├── siembras_screen.dart     # REFACTOR: Multi-tenancy
│   ├── siembra_detalle_screen.dart   # REFACTOR: Tabs + bottom sheets
│   └── admin_screen.dart        # NEW screen (users list + feeding tables)
├── widgets/                     # NEW: Reusable components
│   ├── bottom_sheet_form.dart   # Reusable bottom sheet wrapper
│   ├── custom_app_bar.dart      # AppBar with profile icon
│   ├── summary_card.dart        # Dashboard summary cards
│   └── user_list_tile.dart      # Admin user list item
└── pages/                       # DEPRECATE: Remove after migration
    ├── biometria_page.dart      # To be merged into screens
    ├── dashboard_page.dart
    ├── estanques_page.dart
    ├── home_page.dart
    └── siembras_page.dart

assets/
├── .env                         # Supabase credentials
└── images/                      # App assets

supabase/                        # NEW: Database migrations
├── migrations/
│   ├── 20251116_add_profiles_table.sql
│   ├── 20251116_add_user_id_to_estanques.sql
│   ├── 20251116_add_user_id_to_siembras.sql
│   ├── 20251116_add_user_id_to_biometria.sql
│   ├── 20251116_create_muertes_table.sql
│   ├── 20251116_create_tablas_alimentacion_table.sql
│   ├── 20251116_enable_rls_policies.sql
│   └── 20251116_migrate_existing_data.sql
└── seed/
    └── create_first_admin.sql
```

**Structure Decision**: Mobile (Flutter) single codebase with Backend as a Service (Supabase). The structure follows Flutter conventions with clear separation:

- `models/` for data structures
- `services/` for business logic and Supabase interactions
- `screens/` for full-page navigation (replacing pages/ directory)
- `widgets/` for reusable UI components
- `supabase/` for database migrations and RLS policies

**Key Changes**:

1. Consolidating pages/ into screens/ for simpler navigation model
2. Adding models/ directory for type-safe data handling
3. Adding widgets/ for reusable bottom sheets and components
4. Adding supabase/ directory for version-controlled migrations

## Complexity Tracking

**Constitution Principle III Deviation Documented**

| Principle Deviated                         | Justification                                                                                                                                                                                        | Alternative Approach                                                                                                                                    |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Principle III: Test-First (NON-NEGOTIABLE) | Project priority is rapid feature delivery. Testing infrastructure would add significant time overhead. Team size and timeline constraints make test-first development impractical for this release. | Manual validation and QA testing will be performed. Focus on functional delivery first, potential test coverage in future maintenance cycles if needed. |

**Impact Assessment**: Higher risk of regressions, longer debugging cycles, reduced confidence in refactoring. Accepted trade-off for faster time-to-market.

---

## Phase 0: Research & Unknowns Resolution

**Goal**: Resolve all NEEDS CLARIFICATION items and research best practices for unknowns.

### Research Tasks

The following items require investigation before design can proceed:

1. **Supabase Row Level Security (RLS) Patterns**

   - **Why**: Multi-tenancy is core requirement (FR-031 to FR-036) but team may not have RLS experience
   - **Questions**:
     - How to create RLS policies for user_id filtering?
     - Performance impact of RLS on queries?
     - How to handle admin role that should NOT see other users' data?
     - Migration strategy for enabling RLS on existing tables?
   - **Deliverable**: Document RLS policy patterns with code examples

2. **Flutter Bottom Sheet Implementation**

   - **Why**: All forms must use bottom sheets (FR-003 to FR-005) with specific behavior
   - **Questions**:
     - How to implement dynamic height up to 80% with scroll?
     - Best practices for form state management in bottom sheets?
     - How to handle keyboard overlaying bottom sheet content?
     - Performance considerations for complex forms?
   - **Deliverable**: Prototype reusable BottomSheetForm widget pattern

3. **Supabase Auth with Roles**

   - **Why**: Auto-registration + role management is new (FR-037 to FR-052)
   - **Questions**:
     - How to extend Supabase auth.users with profiles table?
     - How to set role on registration automatically?
     - How to query current user's role for UI conditional rendering?
     - Session management and role caching strategies?
   - **Deliverable**: Auth flow diagram with role integration

4. **Database Migration Strategy**

   - **Why**: Breaking changes to schema require careful migration (Assumption 3)
   - **Questions**:
     - How to add user_id to existing tables without data loss?
     - How to identify "first user" for data assignment?
     - Migration rollback strategy if errors occur?
     - How to handle app versions during migration window?
   - **Deliverable**: Step-by-step migration plan with rollback procedures

5. **Flutter Navigation Architecture**
   - **Why**: Consolidating pages/ into screens/ with bottom navigation (US1)
   - **Questions**:
     - Best practice for bottom navigation with conditional tabs?
     - State preservation when switching tabs?
     - Deep linking with bottom navigation?
     - How to show AppBar with profile icon consistently?
   - **Deliverable**: Navigation architecture diagram

### Research Output Format

Each research task will be documented in `research.md` with:

```markdown
## [Research Topic]

### Decision

[What approach was chosen]

### Rationale

[Why this approach was chosen over alternatives]

### Alternatives Considered

[What other options were evaluated and why rejected]

### Implementation Notes

[Key details, gotchas, code snippets]

### References

[Documentation links, Stack Overflow, tutorials]
```

### Research Success Criteria

- All "How to" questions answered with concrete examples
- At least 2 alternatives evaluated per decision
- Code examples provided for complex patterns
- Performance implications documented
- Migration risks identified with mitigations

---

## Phase 1: Design & Contracts

**Prerequisites**: research.md complete with all unknowns resolved

### 1.1 Data Model (`data-model.md`)

**Purpose**: Define complete database schema with RLS policies

**Scope**:

- Schema definitions for all 6 entities (profiles, estanques, siembras, biometria, muertes, tablas_alimentacion)
- Foreign key relationships and cascading behavior
- Indexes for query performance (especially user_id filtering)
- RLS policies for each table
- Migration scripts with before/after states
- Data validation rules at DB level

**Key Entities to Define**:

1. **profiles** (NEW)

   - Links to auth.users
   - Stores role ('admin' | 'user') and nombre
   - RLS: users can read own profile, admins can read all

2. **estanques** (MODIFIED)

   - Add user_id FK
   - Add unique constraint on (user_id, numero)
   - RLS: users see only their estanques

3. **siembras** (MODIFIED)

   - Add user_id FK
   - Maintain FK to estanques with cascade considerations
   - RLS: users see only their siembras

4. **biometria** (MODIFIED)

   - Add user_id FK
   - FK to siembras
   - RLS: users see only their biometria

5. **muertes** (NEW)

   - user_id, siembra_id FKs
   - cantidad, fecha, observaciones
   - RLS: users see only their muertes

6. **tablas_alimentacion** (NEW - Reference Data)
   - user_id FK (for multi-tenancy only)
   - nombre, peso_min, peso_max, porcentaje_alimentacion, frecuencia_diaria
   - RLS: users see only their tablas
   - **Note**: Independent reference data with NO foreign key relationships to other entities. Used for feeding calculations and decision-making only.

**Migration Considerations**:

- Existing data assignment to first admin user
- Handling foreign key constraints during migration
- Rollback procedures

### 1.2 API Contracts (`contracts/` directory)

**Purpose**: Define request/response formats for all operations

**Files to Create**:

**`auth.md`**:

- POST /auth/register (email, password, nombre) → user + session
- POST /auth/login (email, password) → session
- POST /auth/logout → success
- GET /auth/session → current user with role
- PATCH /auth/profile (nombre, password) → updated profile
- DELETE /auth/account → soft-delete confirmation

**`profiles.md`**:

- GET /profiles/me → current user profile with role
- PATCH /profiles/me (nombre) → updated profile

**`estanques.md`** (multi-tenant):

- GET /estanques → list (filtered by user_id)
- GET /estanques/:id → detail (with RLS check)
- POST /estanques (numero, capacidad) → created (user_id auto-added)
- PATCH /estanques/:id (numero, capacidad) → updated (RLS enforced)
- DELETE /estanques/:id → deleted (check siembras associations)

**`siembras.md`** (multi-tenant):

- GET /siembras → list (filtered by user_id)
- GET /siembras/:id → detail with biometrias + muertes (RLS)
- POST /siembras (estanque_id, especie, fecha, cantidad_inicial) → created
- PATCH /siembras/:id → updated
- DELETE /siembras/:id → deleted (check associations)

**`biometria.md`** (multi-tenant):

- GET /biometria?siembra_id=:id → list for siembra (RLS)
- POST /biometria (siembra_id, fecha, peso_promedio, tamano_promedio) → created
- PATCH /biometria/:id → updated
- DELETE /biometria/:id → deleted

**`admin.md`** (admin-only endpoints):

- GET /admin/users → list all users (admin role required)
- GET /admin/users/:id → user details (admin role required)
- DELETE /admin/users/:id → soft-delete user (validations: no estanques, not admin)
- GET /admin/tablas-alimentacion → list feeding reference tables
- POST /admin/tablas-alimentacion → create reference table
- PATCH /admin/tablas-alimentacion/:id → update reference table
- DELETE /admin/tablas-alimentacion/:id → delete reference table (no dependency checks needed)

**Contract Format**:

````markdown
## Endpoint Name

**Method**: GET/POST/PATCH/DELETE
**Path**: /resource/:id
**Auth**: Required (role: user/admin)
**RLS**: Enforced on user_id

### Request

```json
{
  "field": "type (validation rules)"
}
```
````

### Response Success (200/201)

```json
{
  "field": "value"
}
```

### Response Error (400/403/404/500)

```json
{
  "error": "message"
}
```

### Business Rules

- Rule 1
- Rule 2

### RLS Policy

- Policy name
- Policy rule (user_id = auth.uid())

````

### 1.3 Quickstart Guide (`quickstart.md`)

**Purpose**: Step-by-step setup for developers

**Sections**:

1. **Prerequisites**
   - Flutter 3.38.1+ installation
   - Dart 3.9.2+ installation
   - Supabase account
   - Android Studio / Xcode for mobile development

2. **Environment Setup**
   - Clone repository
   - Copy .env.example to .env
   - Configure Supabase URL and ANON_KEY in .env
   - Run `flutter pub get`

3. **Database Setup**
   - Run migration scripts in order:
     ```bash
     supabase db push
     ```
   - Create first admin user manually:
     ```sql
     -- Run in Supabase SQL Editor
     INSERT INTO auth.users (email, encrypted_password, ...)
     INSERT INTO profiles (id, role) VALUES ('<user-id>', 'admin');
     ```

4. **Running the App**
   - `flutter run` for development
   - Select device (Android emulator / iOS simulator / physical device)
   - First launch shows login screen
   - Use first admin credentials or register new user

5. **Troubleshooting**
   - Common errors and solutions
   - Supabase connection issues
   - RLS policy debugging
   - Migration rollback steps

**Note**: Testing section intentionally excluded - no automated tests planned for this feature.

### 1.4 Agent Context Update

**Action**: Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`

**Purpose**: Add new technologies and patterns to AI agent context file

**Technologies to Add**:
- Supabase Row Level Security (RLS)
- Flutter Bottom Sheet patterns
- Multi-tenancy architecture
- Soft-delete pattern
- Role-based access control (RBAC)

---

## Phase 2: Task Breakdown

**Note**: Phase 2 (tasks.md) is generated by `/speckit.tasks` command, NOT by `/speckit.plan`.

This phase will break down the 8 User Stories into concrete implementation tasks with:
- File paths for each change
- Dependencies between tasks
- Estimated complexity
- Implementation order (P1 → P2 → P3)

**Expected Task Categories**:
1. Database migrations (8 scripts)
2. Model classes (6 entities)
3. Service layer refactoring (6 services)
4. Screen refactoring (10+ screens/widgets)
5. Bottom sheet widgets (4-5 reusable components)
6. Navigation architecture (bottom nav + AppBar)
7. Documentation updates

---

## Implementation Risks & Mitigations

### High Priority Risks

1. **Data Migration Complexity**
   - **Risk**: Existing data corruption during user_id assignment
   - **Mitigation**:
     - Create full database backup before migration
     - Test migration on staging environment first
     - Implement rollback script
     - Document manual recovery procedures

2. **RLS Performance Impact**
   - **Risk**: Row Level Security may slow down queries
   - **Mitigation**:
     - Add indexes on user_id columns
     - Profile queries before and after RLS
     - Consider materialized views for complex queries
     - Monitor query performance in production

3. **Breaking Changes Communication**
   - **Risk**: Users unable to use app during migration window
   - **Mitigation**:
     - Schedule migration during low-usage window
     - Implement forced app update mechanism
     - Display maintenance message
     - Prepare user communication (email/notification)

### Medium Priority Risks

4. **Bottom Sheet UX on Small Devices**
   - **Risk**: 80% height may be too large on small screens
   - **Mitigation**:
     - Test on multiple device sizes (4" to 6.7")
     - Adjust max height for small screens dynamically
     - Ensure scroll works smoothly
     - Consider landscape orientation

### Low Priority Risks

6. **Admin Role Bootstrap**
   - **Risk**: Forgetting to create first admin user blocks admin features
   - **Mitigation**:
     - Document process clearly in quickstart.md
     - Include SQL script in seed/ directory
     - Add validation check in app startup

---

## Success Validation

### Phase 0 Complete When:
- [ ] All 5 research tasks documented in research.md
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Code examples provided for RLS and bottom sheets
- [ ] Migration strategy documented with rollback

### Phase 1 Complete When:
- [ ] data-model.md has complete schema with RLS policies
- [ ] contracts/ directory has all 6 API contract files
- [ ] quickstart.md created for developer setup
- [ ] Agent context updated with new technologies
- [ ] Constitution Check re-evaluated (all gates still PASS)

### Phase 2 Complete When:
- [ ] tasks.md generated with all implementation tasks
- [ ] Tasks prioritized by User Story priority (P1 → P2 → P3)
- [ ] Dependencies mapped between tasks
- [ ] Estimated effort assigned

### Feature Complete When:
- [ ] All 61 Functional Requirements implemented
- [ ] All 8 User Stories acceptance scenarios validated manually
- [ ] 10 Success Criteria validated through manual testing
- [ ] Database migration successful in production
- [ ] Constitution Principle III deviation documented and accepted
- [ ] Breaking changes communicated to users

---

## Next Steps

1. **Immediate**: Create `research.md` by investigating 5 research tasks
2. **After Research**: Create `data-model.md` with complete schema and RLS
3. **After Data Model**: Create `contracts/` directory with 6 API definition files
4. **After Contracts**: Create `quickstart.md` for developer onboarding
5. **After Quickstart**: Run `update-agent-context.ps1` to add new technologies
6. **After Agent Update**: Re-evaluate Constitution Check
7. **Finally**: Run `/speckit.tasks` to generate tasks.md for implementation

**Estimated Timeline**:
- Phase 0 (Research): 2-3 days
- Phase 1 (Design): 3-4 days
- Phase 2 (Task Planning): 1 day
- **Total Planning**: ~1 week before implementation starts

**Resources Needed**:
- Access to Supabase dashboard for RLS policy testing
- Flutter development environment for bottom sheet prototyping
- Staging database for migration testing
- Team review of research decisions and architecture

---

*This plan follows the speckit methodology and Constitution v1.1.0. All changes are tracked in feature branch `001-app-refactor-multitenancy`.*

````
