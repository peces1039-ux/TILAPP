# TILAPP Constitution

## Core Principles

### I. Data-Driven Design

All features and decisions MUST be based on real, structured data stored in Supabase. The data model follows a relational structure with multi-tenancy support:

**Core Entities (Multi-tenant):**

- **profiles** (user profiles): id (FK to auth.users), role ('admin' | 'user'), nombre, created_at, updated_at
- **estanques** (ponds): id, user_id (FK), numero, capacidad, created_at, updated_at
- **siembras** (seedings): id, user_id (FK), estanque_id (FK), especie, fecha, cantidad_inicial, created_at, updated_at
- **biometria** (biometrics): id, user_id (FK), siembra_id (FK), fecha, peso_promedio, tamano_promedio, created_at, updated_at
- **muertes** (deaths): id, user_id (FK), siembra_id (FK), cantidad, fecha, observaciones, created_at, updated_at
- **tablas_alimentacion** (feeding reference tables): id, user*id (FK), nombre, peso_min, peso_max, porcentaje_alimentacion, frecuencia_diaria, created_at, updated_at - \_Reference data for calculations, no FK relationships to other entities*

**Data Model Evolution:**

- **v1.0** (legacy): Single-tenant with alimentacion entity directly linked to biometria
- **v1.1** (current): Multi-tenant architecture with user_id in all tables, profiles for role-based access, separate muertes tracking, and admin-managed tablas_alimentacion as independent reference data for feeding calculations

**Key Relationships:**

- profiles → auth.users (one-to-one)
- estanques → siembras (one-to-many with cascade considerations)
- siembras → biometria, muertes (one-to-many)
- tablas_alimentacion: Independent reference data with no FK relationships (used for calculations only)
- All entities include user_id for Row Level Security (RLS) isolation

No feature is accepted without a clear data model, foreign key relationships, proper CRUD operations, and multi-tenant data isolation.

### II. Mobile-First & Usability

The app MUST prioritize mobile usability, accessibility, and intuitive navigation on Android/iOS.

**Mandatory UI Requirements:**

- All screens MUST use SafeArea wrapper to prevent content overlap with system UI
- Bottom navigation bar with 3 tabs for users (Dashboard, Estanques, Siembras) + conditional Admin tab for admin role
- All forms MUST use bottom sheet modals with dynamic height (max 80% screen height with scroll)
- AppBar with profile icon on all screens for authenticated users
- Touch-optimized components (minimum 48x48 touch targets)
- Material Design principles with consistent color scheme (blue, white, grey)
- Responsive layouts that adapt to different screen sizes

**Current Screens:**

- Login/Register (authentication with auto-registration support)
- Profile Management (user profile with role display)
- Dashboard (summary cards with key metrics)
- Estanques (pond management with multi-tenant filtering)
- Siembras (seeding tracking with multi-tenant filtering)
- Siembra Detalle (individual seeding with biometrics and deaths tabs)
- Admin (user management and feeding tables - admin role only)

### III. Test-First (NON-NEGOTIABLE)

Automated tests are MANDATORY for every feature and bugfix. Red-Green-Refactor cycle is strictly enforced.

**Testing Requirements:**

- Unit tests for all services (auth_service, data services)
- Widget tests for all screens and critical UI components
- Integration tests for user flows and data persistence
- Test coverage MUST be maintained above 70%

**Current Test Structure:**

- test/services/ (service layer tests)
- test/screens/ (screen widget tests)
- test/widget_test.dart (integration tests)

**No code is merged without:**

1. All existing tests passing
2. New tests for new functionality
3. Tests covering all user stories and data flows

### IV. Integration & Data Consistency

All modules MUST be integrated and maintain data consistency through Supabase.

**Integration Points:**

- Authentication flow (LoginScreen/RegisterScreen → AuthService → ProfileService → HomePage)
- Multi-tenant data flows (CRUD operations via Supabase client with RLS policies)
- Foreign key relationships (profiles → estanques → siembras → biometria/muertes)
- Role-based access control (admin/user roles with conditional UI rendering)
- Row Level Security (RLS) policies enforce user_id filtering automatically

**Validation Requirements:**

- All CRUD operations MUST be validated end-to-end
- Foreign key constraints MUST be enforced in database
- Error handling MUST provide user-friendly messages
- Data integrity checks before operations (e.g., can't delete estanque with active siembras)

### V. Observability & Simplicity

All user actions and system events MUST be observable and the codebase MUST remain simple.

**Observability Requirements:**

- Debug logging for critical operations (auth, database operations)
- User-facing error messages via SnackBar
- Clear success/failure feedback for all actions
- Structured error handling with try-catch blocks

**Simplicity Principles:**

- Avoid premature optimization
- Keep widget trees shallow and readable
- One screen/page = one responsibility
- Services handle business logic, widgets handle UI
- Follow Flutter conventions and best practices

**Versioning:** Follows semantic versioning MAJOR.MINOR.PATCH

- App version: 1.0.0+1 (from pubspec.yaml)
- Constitution version: 1.2.0

## Technology Stack & Security

**Core Stack:**

- Language: Dart 3.9.2+
- Framework: Flutter 3.38.1+
- Backend: Supabase (PostgreSQL) with Real-time subscriptions
- State Management: StatefulWidget pattern
- Authentication: Supabase Auth with flutter_secure_storage

**Key Dependencies:**

- supabase_flutter: ^2.0.0 (database, auth, real-time)
- flutter_dotenv: ^6.0.0 (environment configuration)
- intl: ^0.20.2 (date formatting)
- cupertino_icons: ^1.0.8 (iOS-style icons)

**Security Requirements:**

- All environment variables MUST be loaded from assets/.env using flutter_dotenv
- Credentials MUST NEVER be hardcoded in source files (violation found in auth_service.dart)
- User authentication is REQUIRED for all data access beyond login
- Sensitive data MUST NOT be exposed in logs or UI
- Session management via Supabase client with secure token storage

## Development Workflow & Quality Gates

**Project Structure:**

- lib/main.dart (app entry point)
- lib/config/ (configuration classes)
- lib/screens/ (full-page navigation screens)
- lib/pages/ (bottom navigation tab pages)
- lib/services/ (business logic and external integrations)
- test/ (mirrors lib/ structure for tests)

**Code Review & Merge Requirements:**

- All code changes MUST pass code review
- All automated tests MUST pass (flutter test)
- No compile errors or warnings
- Code MUST follow flutter_lints rules
- Features developed in feature branches
- Meaningful commit messages describing SafeArea, data model, or feature changes

**Documentation Requirements:**

- Each feature MUST have a plan.md before implementation
- User stories MUST be documented in spec.md
- Code MUST include inline comments for complex logic
- README.md updated with setup instructions and environment variables

## Governance

- This constitution supersedes all other practices and templates
- Amendments require documentation, approval, and a migration plan
- All PRs and reviews MUST verify compliance with principles and workflow
- Versioning: MAJOR for breaking changes, MINOR for new principles/sections, PATCH for clarifications
- Compliance reviews are required quarterly or after major releases

**Known Technical Debt (must be addressed):**

- ⚠️ Hardcoded credentials in auth_service.dart (VIOLATION of Security principle)
- ⚠️ Missing test coverage for pages/ directory
- ⚠️ Testing infrastructure excluded for feature 001-app-refactor-multitenancy (documented deviation from Principle III)

**Version**: 1.2.0 | **Ratified**: 2025-11-16 | **Last Amended**: 2025-11-16

**Change Log:**

- 1.2.0 (2025-11-16): Updated data model to multi-tenant architecture (profiles, muertes, tablas_alimentacion added; alimentacion evolved to tablas_alimentacion as independent reference data with no FK relationships). Updated UI requirements for bottom sheet modals and conditional admin navigation. Updated integration points for RLS and role-based access control.
- 1.1.0 (2025-11-16): Added concrete implementation details, project structure, dependencies, and technical debt tracking
- 1.0.0 (2025-11-16): Initial constitution with core principles
