# Tasks: Real-Time Live Sync & Multi-Tier Synchronization Architecture

**Feature**: `019-sse-live-sync`
**Spec**: [`spec.md`](spec.md) | **Plan**: [`plan.md`](plan.md)

---

## Phase 1: Setup & Foundational Infrastructure

**Purpose**: Core backend SSE broker and streaming infrastructure required before connecting clients.

- [X] T001 Update auth middleware in `apps/server/internal/middleware/auth.go` to support JWT token extraction from query parameter `?token=` (enabling native browser `EventSource`).
- [X] T002 [P] Create in-memory thread-safe `SSEHub` broker in `apps/server/internal/sse/hub.go` for managing client subscriptions, broadcasting per user ID, echo suppression, and periodic heartbeat pings.
- [X] T003 [P] Create unit and concurrency tests for `SSEHub` in `apps/server/internal/sse/hub_test.go`.
- [X] T004 Implement `GET /api/v1/sync/events` streaming controller in `apps/server/internal/handler/sse_handler.go` with HTTP flusher and context cancellation handling.
- [X] T005 Register SSE endpoint and wire `SSEHub` in `apps/server/internal/router/router.go` and `apps/server/cmd/server/main.go`.

---

## Phase 2: User Story 1 - Instant Multi-Device Live Data Refresh (Priority: P1) 🎯 MVP

**Goal**: When a user modifies data on one device, all other active devices viewing the account receive an SSE signal and automatically pull deltas to refresh the UI in <= 1.5s.

**Independent Test**: Connect two clients (Web/Mobile/curl), perform a mutation on Client A, verify Client B receives `data_changed` and updates without manual intervention.

### Tests for User Story 1
- [X] T006 [P] [US1] Create backend integration test in `apps/server/test/sse_test.go` verifying that `POST /api/v1/sync` triggers a broadcast to active SSE subscribers.

### Implementation for User Story 1
- [X] T007 [US1] Integrate `SSEHub.Broadcast` into `apps/server/internal/service/sync_service.go` when mutations are committed during a sync cycle.
- [X] T008 [P] [US1] Implement SSE client service in `apps/web/src/services/liveSyncService.ts` with connection management, event parsing, echo suppression, and debounced delta pull.
- [X] T009 [US1] Connect `liveSyncService` into `apps/web/src/services/syncService.ts` and `apps/web/src/context/SyncContext.tsx` to automatically trigger state refresh on incoming events.
- [X] T010 [P] [US1] Implement Flutter SSE stream client in `apps/mobile/lib/services/live_sync_service.dart` using streamed `http.Client`.
- [X] T011 [US1] Wire `live_sync_service.dart` into `apps/mobile/lib/providers/sync_provider.dart` to trigger debounced delta sync on `data_changed` event.

---

## Phase 3: User Story 2 - Action-Triggered Atomic Mutation Sync (Priority: P1)

**Goal**: Acting device saves mutations locally and atomically pushes to server with immediate acknowledgment, suppressing self-echo.

**Independent Test**: Mutate a record on Web/Mobile, verify immediate 2-in-1 push-pull roundtrip, verify local `synced = 1`, and verify the acting client does NOT perform a redundant self-pull.

### Implementation for User Story 2
- [X] T012 [P] [US2] Ensure persistent `device_id` is included in all outbound sync payloads and SSE query parameters in `apps/web/src/services/syncService.ts`.
- [X] T013 [P] [US2] Ensure persistent `device_id` is passed in `apps/mobile/lib/services/sync_service.dart` and `apps/mobile/lib/services/live_sync_service.dart`.
- [X] T014 [US2] Add unit test for echo suppression in `apps/server/test/sse_test.go` confirming originating client ID is broadcasted for receiver-side filtering.

---

## Phase 4: User Story 3 - Application Resume & Tab Focus Lifecycle Sync (Priority: P2)

**Goal**: Pull missed updates immediately when returning to an inactive browser tab or foregrounding a paused mobile app.

**Independent Test**: Put app in background, modify data on another device, bring app to foreground, verify automatic delta sync runs immediately.

### Implementation for User Story 3
- [X] T015 [P] [US3] Add visibility change (`document.addEventListener('visibilitychange')`) and window focus (`window.addEventListener('focus')`) listeners in `apps/web/src/services/liveSyncService.ts` to trigger catch-up sync.
- [X] T016 [US3] Enhance `WidgetsBindingObserver` in `apps/mobile/lib/main.dart` and `apps/mobile/lib/providers/sync_provider.dart` to trigger catch-up delta sync when transitioning to `AppLifecycleState.resumed`.

---

## Phase 5: User Story 4 - Real-Time Connection State & Manual Sync Fallback (Priority: P2)

**Goal**: Provide live connection indicators (Live, Reconnecting, Offline, Syncing) and instant manual sync fallback button.

**Independent Test**: Toggle airplane mode/network, verify status transitions smoothly; press "Sync Now" button and verify forced bidirectional sync.

### Implementation for User Story 4
- [X] T017 [P] [US4] Add `LiveStreamState` (`connected`, `connecting`, `reconnecting`, `disconnected`) to `apps/web/src/types/index.ts` and expose it through `apps/web/src/context/SyncContext.tsx`.
- [X] T018 [US4] Update Header & Sync Indicator in `apps/web/src/components/Navbar.tsx` and `apps/web/src/pages/Settings.tsx` with live indicator pulse badge and "Sync Now" button.
- [X] T019 [P] [US4] Add `LiveStreamStatus` to `apps/mobile/lib/providers/sync_provider.dart` and update sync status widget in `apps/mobile/lib/screens/settings_screen.dart`.

---

## Phase 6: User Story 5 - Battery & Network Efficient Stream Lifecycle (Priority: P3)

**Goal**: Maximize mobile battery life and minimize network overhead by closing background sockets and reconnecting with exponential backoff.

**Independent Test**: Background mobile app and verify SSE stream is cleanly disconnected; foreground app and verify stream reconnects within 1s.

### Implementation for User Story 5
- [X] T020 [P] [US5] Implement exponential backoff with jitter and max retry cap in `apps/web/src/services/liveSyncService.ts`.
- [X] T021 [US5] Implement background stream termination and foreground reconnection in `apps/mobile/lib/services/live_sync_service.dart` tied to `AppLifecycleState.paused`/`resumed`.
- [X] T022 [P] [US5] Add unit test for Flutter SSE stream parser and reconnection in `apps/mobile/test/unit/live_sync_test.dart`.

---

## Phase 7: Polish, Verification & Docker Test

**Purpose**: Validate end-to-end functionality across all components inside Docker.

- [X] T023 [P] Execute backend unit and integration tests inside Docker container via `docker compose run --rm simo-server go test -v ./...`.
- [X] T024 [P] Build and verify Web UI with `docker compose run --rm simo-web npm run build`.
- [X] T025 Execute multi-device live sync validation scenario per `specs/019-sse-live-sync/quickstart.md`.

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup & Foundational (Phase 1)**: No dependencies - can start immediately. Blocks all user stories.
- **User Story 1 (Phase 2 - P1 MVP)**: Depends on Phase 1 completion.
- **User Story 2 (Phase 3 - P1)**: Depends on Phase 1 completion. Can run in parallel with US1.
- **User Story 3 (Phase 4 - P2)**: Depends on Phase 1 and US1 client implementations.
- **User Story 4 (Phase 5 - P2)**: Depends on Phase 1 and US1 client implementations.
- **User Story 5 (Phase 6 - P3)**: Depends on Phase 1 and Mobile SSE client implementation.
- **Polish & Docker Test (Phase 7)**: Runs after all user stories are implemented.

### Parallel Opportunities
- **Backend & Web & Mobile Tasks marked `[P]`**:
  - T002 (`hub.go`), T003 (`hub_test.go`) can be written in parallel.
  - T008 (`liveSyncService.ts` on Web) and T010 (`live_sync_service.dart` on Mobile) can be implemented in parallel.
  - T017 (Web UI status) and T019 (Mobile UI status) can be implemented in parallel.
  - T023 (Backend Docker test) and T024 (Web build test) can run in parallel.

---

## Implementation Strategy

### MVP First (Phases 1 & 2)
1. Complete Phase 1 (Go `SSEHub`, Auth query param, `GET /api/v1/sync/events` endpoint).
2. Complete Phase 2 (Broadcast on sync mutation, Web & Mobile SSE listeners).
3. **Validate MVP**: Create a transaction on Web and observe instant live sync on another client in <1.5s.

### Incremental Delivery
1. Foundation + MVP (Live Sync works).
2. Add Lifecycle Sync & Echo Suppression (Seamless tab resume / app resume).
3. Add Connection State UI & Battery lifecycle management (Production polish).
4. Run 100% Docker verification tests.
