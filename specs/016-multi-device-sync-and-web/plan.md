# Implementation Plan: Multi-Device Synchronization & Web Interface

**Branch**: `016-multi-device-sync-and-web` | **Date**: 2026-09-12 | **Spec**: [`spec.md`](spec.md)

**Input**: Feature specification from [`specs/016-multi-device-sync-and-web/spec.md`](spec.md)

---

## Summary

Restructure the repository into a clean **Monorepo** layout (`apps/mobile`, `apps/server`, `apps/web`). Build a high-performance **Go Backend API** in `apps/server` using a clean **Layered Architecture (Router $\rightarrow$ Controller/Handler $\rightarrow$ Service $\rightarrow$ Repository)** with a unified **Push-First Pull-Second Delta Sync Engine** connected to PostgreSQL (loaded from `.env` pointing to the user's existing homeserver). Integrate a reactive sync client into the Flutter mobile app (`apps/mobile`) and develop a lightweight desktop management interface (`apps/web`).

---

## Technical Context

**Language/Version**: 
- Backend: Go 1.27+ (using modern `net/http` enhanced routing)
- Mobile App: Dart 3.13 / Flutter 3.47+
- Web Frontend: TypeScript 5.x / React 19 / Vite

**Primary Dependencies**: 
- Backend (`apps/server`): `github.com/jackc/pgx/v5`, `github.com/golang-jwt/jwt/v5`, `github.com/joho/godotenv`, `github.com/google/uuid`
- Mobile (`apps/mobile`): `flutter_riverpod`, `connectivity_plus`, `sqflite`, `sqflite_common_ffi`
- Web (`apps/web`): `react`, `react-dom`, `@tanstack/react-query`, `lucide-react`, `tailwindcss`

**Storage**: 
- Server: PostgreSQL 16+ (existing container on user's homeserver, credentials strictly from `.env`)
- Client: SQLite (`simo.db` v16) on mobile

**Testing**: 
- Backend: Standard Go tests (`go test -v ./...`) covering sync mutations, conflict arbitration, and transaction idempotency
- Mobile: Flutter tests with `sqflite_common_ffi`
- Web: Vitest / React Testing Library

**Target Platform**: Linux / Homeserver for Backend, Android/iOS for Mobile, Modern Web Browsers for Web.

**Project Type**: Monorepo (`apps/mobile`, `apps/server`, `apps/web`).

---

## Constitution Check

- [x] **Top 1 Priority for Go**: Backend is implemented 100% in Go standard library + lightweight libraries.
- [x] **No hardcoded secrets**: Database credentials strictly loaded from `.env`.
- [x] **Layered Architecture**: Clean 4-stage pipeline: Router $\rightarrow$ Controller/Handler $\rightarrow$ Service $\rightarrow$ Repository $\rightarrow$ PostgreSQL.
- [x] **Structured Logging & Clear Errors**: Go backend utilizes structured logging with contextual error wrapping.
- [x] **Test-First Discipline**: Integration tests for multi-device sync and concurrent conflict scenarios.

---

## Project Structure

### Documentation (this feature)

```text
specs/016-multi-device-sync-and-web/
├── plan.md              # Implementation plan (/speckit-plan output)
├── research.md          # Phase 0 technical decisions (/speckit-plan output)
├── data-model.md        # Phase 1 database & entity definitions (/speckit-plan output)
├── quickstart.md        # Phase 1 verification and run guide (/speckit-plan output)
├── contracts/           # Phase 1 API specifications
│   ├── sync-contract.json
│   ├── auth-contract.json
│   └── rest-api-contract.json
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code (Monorepo Layout)

```text
simo/                                  # Monorepo Root
├── apps/
│   ├── mobile/                        # 📱 Flutter Mobile App (Offline-First)
│   │   ├── android/
│   │   ├── ios/
│   │   ├── lib/                       # Flutter source code
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── repositories/          # SQLite DatabaseHelper
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   │   └── sync_service.dart  # [NEW] Sync client coordinating with Go server
│   │   │   └── widgets/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── server/                        # 🚀 Go Backend Service (Layered 3-Tier)
│   │   ├── cmd/
│   │   │   ├── server/
│   │   │   │   └── main.go            # Entrypoint & Router bootstrap
│   │   │   └── migrate/
│   │   │       └── main.go            # Database migration CLI tool
│   │   ├── internal/
│   │   │   ├── config/                # Load environment variables (.env)
│   │   │   ├── middleware/            # Auth JWT, Logger, CORS, Recovery
│   │   │   ├── model/                 # Entity DTOs and Database Structs
│   │   │   ├── router/                # Route definitions & URL mappings
│   │   │   │   └── router.go
│   │   │   ├── handler/               # Controllers (HTTP request/response handling)
│   │   │   │   ├── sync_handler.go
│   │   │   │   ├── auth_handler.go
│   │   │   │   ├── transaction_handler.go
│   │   │   │   └── wallet_handler.go
│   │   │   ├── service/               # Business Logic & Sync Engine
│   │   │   │   ├── sync_service.go
│   │   │   │   └── auth_service.go
│   │   │   └── repository/            # Data Access Layer (PostgreSQL with pgxpool)
│   │   │       ├── sync_repo.go
│   │   │       ├── user_repo.go
│   │   │       └── transaction_repo.go
│   │   ├── migrations/                # SQL Schema migration files
│   │   │   └── 001_initial_schema.up.sql
│   │   ├── pkg/
│   │   │   └── response/              # Standard JSON response envelope
│   │   ├── .env.example               # Example environment configuration for homeserver
│   │   ├── go.mod
│   │   └── go.sum
│   │
│   └── web/                           # 💻 Web Management App (React + TS + Vite)
│       ├── src/
│       │   ├── components/            # UI widgets (Navbar, Charts, Tables)
│       │   ├── pages/                 # Dashboard, Transactions, Wallets
│       │   ├── services/api.ts        # API client
│       │   ├── App.tsx
│       │   └── main.tsx
│       ├── package.json
│       ├── vite.config.ts
│       └── tailwind.config.js
│
├── docs/                              # Project documentation
└── specs/                             # Spec-kit specifications
```

---

## Complexity Tracking

| Decision | Why Needed | Simpler Alternative Rejected Because |
| :--- | :--- | :--- |
| **Monorepo (`apps/mobile`, `apps/server`, `apps/web`)** | Clean segregation of independent platforms while sharing domain specs and docs in one repository. | Polyrepo creates overhead managing separate git repositories for a personal project. |
| **Layered Router $\rightarrow$ Handler $\rightarrow$ Service $\rightarrow$ Repo** | Clean separation of concerns for a single personal finance domain without modular monolith overhead. | Flat structure lacks unit testability; Domain-Driven Design / Modular Monolith is over-engineering for single domain. |
| **Push-First Pull-Second Sync Endpoint** | Solves two-way data convergence in 1 HTTP roundtrip (<100ms) without race conditions. | Separate push/pull endpoints require multiple roundtrips and complex client state machines. |
| **Server Monotonic UTC Timestamp Cursor** | Eliminates clock skew and timezone bugs (e.g. US vs Vietnam devices). | Client-driven timestamp filtering breaks whenever device clocks are inaccurate or changed. |
