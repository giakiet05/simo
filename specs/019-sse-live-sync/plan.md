# Implementation Plan: Real-Time Live Sync & Multi-Tier Synchronization Architecture

**Branch**: `019-sse-live-sync` | **Date**: 2026-09-13 | **Spec**: [`spec.md`](spec.md)

**Input**: Feature specification from [`specs/019-sse-live-sync/spec.md`](spec.md)

---

## Summary

Implement a lightweight, battery-efficient, resilient **Server-Sent Events (SSE) Live Sync** system across the Go backend (`apps/server`), React Web UI (`apps/web`), and Flutter Mobile App (`apps/mobile`).

The architecture seamlessly harmonizes a **4-tier synchronization engine**:
1. **Lifecycle Sync**: Automatic delta pull upon app startup, tab focus, or app foreground resumption (`resumed` / `visibilitychange`).
2. **Action Sync**: Atomic 2-in-1 mutation push and remote delta pull in a single roundtrip upon user edits (`POST /api/v1/sync`).
3. **Live Event Sync**: Server broadcasts lightweight SSE signals (`data_changed` with `source_client_id`) over `GET /api/v1/sync/events` to trigger debounced background delta pulls on passive devices.
4. **Manual Sync**: Instant user-triggered "Sync Now" override.

---

## Technical Context

**Language/Version**: 
- Backend: Go 1.22+ (using enhanced routing in `net/http` and goroutines)
- Web Frontend: TypeScript 5.x / React 19 / Vite
- Mobile App: Dart 3.x / Flutter 3.x / Riverpod

**Primary Dependencies**: 
- Backend: Standard Go `net/http`, `sync`, `github.com/google/uuid`, `github.com/golang-jwt/jwt/v5`
- Web: Native browser `EventSource` / `fetch` stream handler, `lucide-react`
- Mobile: `http` package for streamed response, `flutter_riverpod`, `shared_preferences`

**Storage**: 
- Backend: PostgreSQL 16+ (existing database container)
- Web: IndexedDB / LocalStorage (`simo_db_state_v1`)
- Mobile: SQLite (`simo.db` v16)

**Testing**: 
- Docker-First: `docker compose run --rm simo-server go test -v ./...`
- Web Tests: `npm test` inside web container
- Unit tests for SSE Hub concurrency, echo prevention, and debounce logic

**Target Platform**: Linux / Docker (Backend & Web), Android/iOS (Mobile).

**Scale/Scope**: Real-time cross-device sync with sub-second propagation latency (<1.5s).

---

## Constitution Check

- [x] **Top 1 Priority for Go**: SSE Broker/Hub is built using standard Go channels, goroutines, and mutexes with zero bulky third-party message brokers.
- [x] **No hardcoded secrets**: Auth tokens validated via existing JWT secret and authentication middleware.
- [x] **Layered Architecture**: Clean separation between `router` $\rightarrow$ `handler.SSEHandler` $\rightarrow$ `service.SSEHub` $\rightarrow$ `service.SyncService`.
- [x] **Structured Logging & Clear Errors**: All connection events and broadcast metrics use structured logging with error wrapping.
- [x] **Docker First**: All tests and execution run in Docker containers.

---

## Project Structure

### Documentation (this feature)

```text
specs/019-sse-live-sync/
├── plan.md              # This file (/speckit-plan output)
├── research.md          # Phase 0 technical decisions & trade-offs
├── data-model.md        # Phase 1 event schemas and state transitions
├── contracts/           # Phase 1 API specifications
│   └── live-sync-events.json
├── quickstart.md        # Phase 1 verification and run guide
└── checklists/
    └── requirements.md  # Spec quality checklist
```

### Source Code Layout

```text
simo/
├── apps/
│   ├── server/
│   │   ├── internal/
│   │   │   ├── sse/
│   │   │   │   └── hub.go             # [NEW] In-memory thread-safe SSE connection hub & broker
│   │   │   ├── handler/
│   │   │   │   ├── sse_handler.go     # [NEW] GET /api/v1/sync/events streaming controller
│   │   │   │   └── sync_handler.go    # [MODIFY] Connect SyncHandler to SSEHub for event broadcast
│   │   │   ├── service/
│   │   │   │   └── sync_service.go    # [MODIFY] Notify SSEHub on successful sync cycles
│   │   │   ├── router/
│   │   │   │   └── router.go          # [MODIFY] Register SSE endpoint and auth query param support
│   │   │   └── middleware/
│   │   │       └── auth.go            # [MODIFY] Support JWT token from query param ?token=
│   │   └── test/
│   │       └── sse_test.go            # [NEW] SSE Hub & Streaming integration tests
│   │
│   ├── web/
│   │   └── src/
│   │       ├── services/
│   │       │   ├── syncService.ts     # [MODIFY] Add Live SSE stream listener & lifecycle hooks
│   │       │   └── api.ts             # [MODIFY] SSE stream URL helper
│   │       ├── context/
│   │       │   └── SyncContext.tsx    # [MODIFY] Expose live connection status to header
│   │       └── components/
│   │           └── Navbar.tsx         # [MODIFY] Render Live sync status indicator
│   │
│   └── mobile/
│       └── lib/
│           ├── services/
│           │   ├── live_sync_service.dart # [NEW] Flutter SSE stream client with auto-reconnect
│           │   └── sync_service.dart      # [MODIFY] Expose client device ID and debounce pull
│           ├── providers/
│           │   └── sync_provider.dart     # [MODIFY] Manage live stream lifecycle and riverpod states
│           └── main.dart                  # [MODIFY] Bind stream pause/resume to AppLifecycleState
```

---

## Complexity Tracking

| Decision | Why Needed | Simpler Alternative Rejected Because |
| :--- | :--- | :--- |
| **In-Memory SSE Hub in Go** | Real-time event broadcast per authenticated user without external infrastructure overhead. | Redis PubSub / RabbitMQ introduces heavy unnecessary infrastructure for a personal finance system. |
| **Thin Signal over SSE** | Server only sends `data_changed` ping; clients pull via existing sync API. | Full entity streaming over SSE duplicates transaction logic, creates schema divergence, and risks packet loss. |
| **Query Param Auth for SSE** | Native browser `EventSource` does not support custom `Authorization` HTTP headers. | Bloated JS polyfills or heavy WebSockets add unnecessary client bundle size and reconnection complexity. |
| **Lifecycle Stream Suspension on Mobile** | Closes SSE connection when app is in background/locked, saving battery and mobile bandwidth. | Keeping persistent sockets open in the background drains battery and causes OS kills. |
