# Tasks: Multi-Device Synchronization & Web Interface

**Feature**: `016-multi-device-sync-and-web`
**Spec**: [`spec.md`](spec.md) | **Plan**: [`plan.md`](plan.md)

---

## Phase 1: Setup (Monorepo & Workspace Initialization)

**Purpose**: Restructure the project into a clean Monorepo layout (`apps/mobile`, `apps/server`, `apps/web`) and initialize subproject dependencies.

- [X] T001 Move existing Flutter mobile codebase to `apps/mobile/` and verify Flutter build configurations
- [X] T002 Initialize Go backend module in `apps/server/` with `go.mod` (`go1.27`) and install core dependencies (`pgx/v5`, `golang-jwt/jwt/v5`, `godotenv`, `uuid`)
- [X] T003 Initialize React + TypeScript + Vite + Tailwind CSS frontend application in `apps/web/`
- [X] T004 [P] Create `.env.example` templates in `apps/server/` and `apps/mobile/` for homeserver PostgreSQL credentials

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core backend infrastructure, database connection pool, migration scripts, and middleware framework.

**⚠️ CRITICAL**: Must be completed before implementing any user story.

- [X] T005 Create PostgreSQL schema migration script in `apps/server/migrations/001_initial_schema.up.sql` covering all 11 entities with `user_id`, `server_updated_at`, and `deleted_at`
- [X] T006 Implement database migration runner CLI tool in `apps/server/cmd/migrate/main.go`
- [X] T007 Implement environment configuration loader in `apps/server/internal/config/config.go`
- [X] T008 [P] Implement PostgreSQL connection pool manager in `apps/server/internal/repository/db.go` using `pgxpool`
- [X] T009 [P] Implement standard JSON response envelope and error format in `apps/server/pkg/response/response.go`
- [X] T010 [P] Implement HTTP Middlewares (CORS, Structured Logger, Panic Recovery) in `apps/server/internal/middleware/`
- [X] T011 [P] Implement JWT Authentication Middleware and Token Verifier in `apps/server/internal/middleware/auth.go`
- [X] T012 Define all core Go data models and DTO structs in `apps/server/internal/model/`
- [X] T013 Create router bootstrap and HTTP server entrypoint in `apps/server/cmd/server/main.go` and `apps/server/internal/router/router.go`

**Checkpoint**: Foundation ready — database connects, migrations run cleanly, router and auth middlewares verified.

---

## Phase 3: User Story 1 - Seamless Multi-Device Cloud Sync (Priority: P1) 🎯 MVP

**Goal**: Deliver the unified 2-way sync engine (`POST /api/v1/sync`) enabling full-duplex synchronization between mobile devices and the Go backend.

**Independent Test**: Simulate two devices syncing sequentially; mutations created by Device A are pulled and applied cleanly by Device B.

### Tests for User Story 1 ⚠️

- [X] T014 [P] [US1] Write contract & integration test for `POST /api/v1/sync` in `apps/server/test/sync_test.go` verifying Push-First Pull-Second execution and cursor filtering

### Implementation for User Story 1

- [X] T015 [P] [US1] Implement Sync repository methods for batch upserting mutations and querying deltas by `server_updated_at` in `apps/server/internal/repository/sync_repo.go`
- [X] T016 [US1] Implement SyncService business logic with transaction orchestration in `apps/server/internal/service/sync_service.go`
- [X] T017 [US1] Implement SyncHandler HTTP controller and wire route in `apps/server/internal/handler/sync_handler.go` and `apps/server/internal/router/router.go`
- [X] T018 [P] [US1] Implement client-side `SyncService` in `apps/mobile/lib/services/sync_service.dart` with debounce queue, push payload builder, and delta SQLite transaction applier
- [X] T019 [US1] Implement Riverpod `SyncProvider` in `apps/mobile/lib/providers/sync_provider.dart` to expose sync status (idle, syncing, error, last_synced_time) to mobile UI
- [X] T020 [US1] Add sync status indicator and manual trigger button in mobile Settings screen `apps/mobile/lib/screens/settings_screen.dart`

**Checkpoint**: User Story 1 complete — multi-device 2-way sync fully functional between mobile and server.

---

## Phase 4: User Story 2 - Desktop & Web Financial Management Interface (Priority: P2)

**Goal**: Build a responsive desktop web application with dashboard analytics and direct transaction/wallet management.

**Independent Test**: Open the web application on a browser, log in, view synchronized financial charts, and record a new transaction that propagates to mobile upon sync.

### Implementation for User Story 2

- [X] T021 [P] [US2] Implement Web REST repositories for transactions, wallets, and dashboard aggregation in `apps/server/internal/repository/transaction_repo.go` and `apps/server/internal/repository/wallet_repo.go`
- [X] T022 [P] [US2] Implement Dashboard and Transaction services in `apps/server/internal/service/dashboard_service.go`
- [X] T023 [US2] Implement Web REST handlers (`/api/v1/dashboard`, `/api/v1/transactions`, `/api/v1/wallets`) in `apps/server/internal/handler/`
- [X] T024 [P] [US2] Setup API client, authentication state, and TypeScript interfaces in `apps/web/src/services/api.ts`
- [X] T025 [P] [US2] Build reusable UI widgets (Navbar, StatCard, Settings) in `apps/web/src/components/`
- [X] T026 [US2] Implement Dashboard Page with cashflow metrics and spending chart in `apps/web/src/pages/Dashboard.tsx`
- [X] T027 [US2] Implement Transactions Page with filtering, search, and pagination in `apps/web/src/pages/Transactions.tsx`
- [X] T028 [US2] Implement Wallets Management Page in `apps/web/src/pages/Wallets.tsx`

**Checkpoint**: User Story 2 complete — web interface fully capable of visualizing and managing financial records.

---

## Phase 5: User Story 3 - Automatic Conflict Resolution & Offline Convergence (Priority: P3)

**Goal**: Harden the sync engine against concurrent modifications, network dropouts, and offline balance discrepancies.

**Independent Test**: Two devices edit records and record transactions offline; when reconnected, balance recalculation converges and tombstones prevent resurrection.

### Implementation for User Story 3

- [X] T029 [P] [US3] Implement Last-Write-Wins (LWW) conflict arbiter and Tombstone priority logic in `apps/server/internal/repository/sync_repo.go`
- [X] T030 [P] [US3] Implement foreign-key fallback (soft-unlink and default cash wallet reassignment) in `apps/server/internal/repository/sync_repo.go`
- [X] T031 [US3] Implement automatic network connectivity listener (`connectivity_plus`) and auto-flush on reconnection in `apps/mobile/lib/services/sync_service.dart`
- [X] T032 [US3] Implement wallet balance recalculation routine on SQLite upon applying remote transaction deltas in `apps/mobile/lib/services/sync_service.dart`

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, validation against quickstart scenarios, and code quality verification.

- [X] T034 [P] Execute end-to-end verification scenarios per `specs/016-multi-device-sync-and-web/quickstart.md`
- [X] T035 [P] Run static linters and test suites across all projects (`go test ./...`, `flutter test`, `npm run build`)
- [X] T036 Update project architecture and deployment documentation in root `README.md`

---

## Verification Summary

- **Go Backend**: `go vet ./...` passed, `go build` for server and migrate binaries generated cleanly.
- **Flutter Mobile**: `flutter test --concurrency=1` passed 71/71 tests.
- **React Web App**: `npm run build` compiled production bundle in 231ms (gzip size 76kB).
