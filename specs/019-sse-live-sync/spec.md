# Feature Specification: Real-Time Live Sync & Multi-Tier Synchronization Architecture

**Feature Branch**: `019-sse-live-sync`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Thiết lập cơ chế Live Sync realtime qua Server-Sent Events (SSE) kết hợp kiến trúc đồng bộ 4 tầng (App Resume/Open Sync, Action Push-Pull Sync, Live Event Signal Sync, Manual Sync) cho cả Web UI, Mobile App và Backend Go"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instant Multi-Device Live Data Refresh (Priority: P1)

As a user managing finances across multiple active devices (e.g., logging an expense on the Web application while having the Mobile app open on a desk), I want changes made on one device to appear immediately on my other devices without needing to manually refresh or reload the screen.

**Why this priority**: Cross-device immediacy eliminates friction, ensures data consistency, and gives users total confidence that their financial records are up-to-date regardless of which screen they are looking at.

**Independent Test**: Can be tested by opening the application on Device A and Device B logged into the same account, creating a transaction on Device A, and observing Device B automatically update its list and totals within 1-2 seconds without user interaction on Device B.

**Acceptance Scenarios**:
1. **Given** Device A and Device B are both open and logged into the same user account, **When** the user creates, updates, or deletes a transaction on Device A, **Then** Device B receives a real-time change notification, pulls latest deltas, and updates the UI automatically.
2. **Given** a user transfers funds between wallets on Device A, **When** viewing the wallet list on Device B, **Then** the updated balances for both source and destination wallets reflect instantly.
3. **Given** a user is currently filling out a form or interacting with a list on Device B when an update arrives, **Then** the background data refresh occurs without resetting uncommitted user input or jumping scroll position.

---

### User Story 2 - Action-Triggered Atomic Mutation Sync (Priority: P1)

As a user performing financial operations (adding transactions, creating wallets, adjusting budgets), I want my active device to immediately save changes locally and atomically push them to the central server in a single roundtrip, ensuring offline reliability and immediate acknowledgment.

**Why this priority**: The active acting device must never rely on passive event signals to know its own changes succeeded; atomic push-pull ensures zero latency and immediate local-to-remote consistency.

**Independent Test**: Can be tested by performing any mutation on an active device, confirming local database persistence, verifying the outbound sync payload is sent immediately, and validating that server acknowledgments and timestamp tokens are saved.

**Acceptance Scenarios**:
1. **Given** the user creates a new record on Device A, **When** saving, **Then** the record is immediately committed to local storage with pending sync status and pushed to the server within a debounced window (<= 1 second).
2. **Given** a single sync request sent by Device A, **When** the server processes mutations, **Then** it returns updated server timestamps and any newly accumulated remote changes in the exact same response.
3. **Given** the active device receives confirmation from the server, **Then** local records are marked as synchronized and the sync indicator shows a completed state.

---

### User Story 3 - Application Resume & Tab Focus Lifecycle Sync (Priority: P2)

As a user switching back to the mobile app from another app or returning to a background browser tab after hours of inactivity, I want the application to automatically pull any missed updates that occurred while the app was asleep or backgrounded.

**Why this priority**: Devices in sleep or background mode do not maintain persistent real-time streaming connections to conserve system resources; lifecycle wakeup sync guarantees data integrity upon user return.

**Independent Test**: Can be tested by backgrounding the mobile app (or switching browser tabs), modifying financial data on another device, then bringing the app back to foreground (or switching back to the tab), and observing an automatic catch-up sync execute immediately.

**Acceptance Scenarios**:
1. **Given** the mobile app is in the background or the phone screen is locked, **When** the user brings the app to the foreground, **Then** the app triggers an immediate delta pull and updates all active screens.
2. **Given** the web app is in an inactive browser tab, **When** the user focuses or switches back to the tab, **Then** the web app detects the focus event and initiates a catch-up delta sync.
3. **Given** no new changes occurred while the app was backgrounded, **When** resumed, **Then** the sync check completes silently with zero UI churn or unnecessary data re-rendering.

---

### User Story 4 - Real-Time Connection State & Manual Sync Fallback (Priority: P2)

As a user with intermittent network connectivity, I want clear visual indicators showing my live synchronization status (Live, Reconnecting, Offline, Syncing) and the ability to trigger a manual sync anytime with a single tap.

**Why this priority**: Transparency builds trust by reassuring the user whether they are live, reconnecting, or working offline, with a guaranteed manual override when needed.

**Independent Test**: Can be tested by viewing the sync status badge in the header/settings, toggling device airplane mode to verify state transitions, and pressing the manual "Sync Now" button to force a full bidirectional cycle.

**Acceptance Scenarios**:
1. **Given** a healthy real-time stream connection, **When** viewing the application header, **Then** the status displays as "Live" or "Synced".
2. **Given** network loss occurs, **When** viewing the application, **Then** the status transitions to "Offline" or "Reconnecting", and local operations continue without interruption.
3. **Given** any connection state, **When** the user clicks the "Sync Now" button, **Then** an immediate full bidirectional sync cycle executes and provides explicit feedback (success or network error).

---

### User Story 5 - Battery & Network Efficient Stream Lifecycle (Priority: P3)

As a mobile user, I want the live synchronization stream to operate efficiently without draining battery, consuming background mobile data, or keeping background sockets open when the app is paused.

**Why this priority**: Mobile operating systems penalize or kill applications that maintain excessive background sockets; clean stream lifecycle management preserves device battery and operating system goodwill.

**Independent Test**: Can be tested by monitoring active network connections when transitioning between foreground, background, and app termination states.

**Acceptance Scenarios**:
1. **Given** the mobile app transitions to background or screen lock, **When** paused, **Then** the real-time event listener gracefully closes its network connection.
2. **Given** the mobile app transitions back to foreground, **When** resumed, **Then** the real-time event listener reconnects cleanly and triggers a catch-up delta sync.
3. **Given** a temporary network drop, **When** reconnecting, **Then** the client uses an exponential backoff retry strategy with a reasonable jitter to avoid overwhelming the server.

---

### Edge Cases

- **Self-Notification Filtering (Echo Prevention)**: When Device A triggers a mutation, the server broadcasts an event. Device A must recognize that it already processed this mutation during its own active action sync and avoid redundant pull cycles.
- **Thundering Herd / Rapid Bursts**: If a user imports 100 transactions or performs rapid successive edits on Device A, Device B must debounce incoming pull signals (e.g., 500ms debounce window) so it performs a single batch pull rather than 100 individual sync requests.
- **Offline Mutation Accumulation**: If Device B makes offline edits while disconnected and receives a live sync notification immediately upon reconnecting, Device B must push its pending local mutations before or alongside pulling remote deltas to prevent overwriting local uncommitted work.
- **Concurrent Conflict Resolution**: If Device A and Device B edit the exact same entity while offline and both connect simultaneously, the system resolves conflicts deterministically via Last-Write-Wins based on server timestamps.
- **Multiple Browser Tabs on the Same Machine**: When multiple tabs are open on the same browser, changes made in Tab 1 must propagate to Tab 2 seamlessly without causing infinite event loops between tabs.
- **Server Restart / Stream Drop**: If the central backend restarts or drops the streaming connection, all connected clients must automatically reconnect using backoff retry and initiate a catch-up sync once re-established.

---

## Requirements *(mandatory)*

### Functional Requirements

#### 4-Tier Sync Architecture
- **FR-001**: System MUST implement a unified 4-tier synchronization architecture comprising:
  1. *Lifecycle Sync*: Triggered automatically on app launch, tab focus, or app foreground resumption.
  2. *Action Sync*: Triggered immediately (debounced) upon any local user mutation (Create/Update/Delete).
  3. *Live Event Sync*: Triggered upon receiving a real-time server change event signal on passive connected devices.
  4. *Manual Sync*: Triggered on-demand by user interaction with the "Sync Now" control.
- **FR-002**: Action Sync MUST execute as an atomic 2-in-1 request that pushes local pending changes and pulls latest server deltas in a single roundtrip.
- **FR-003**: Live Event Sync MUST transmit lightweight signals (event type, entity name, timestamp, originating client ID) rather than heavy database payloads, prompting receiving clients to execute a standard delta pull.

#### Real-Time Event Streaming
- **FR-004**: Central server MUST maintain an authenticated real-time event stream endpoint scoped per user account.
- **FR-005**: Central server MUST broadcast change event signals to all active client connections belonging to the authenticated user whenever data is mutated.
- **FR-006**: Central server MUST include the originating client identifier in the event signal to allow the acting client to suppress redundant self-pulls.
- **FR-007**: Central server MUST periodically transmit lightweight keep-alive heartbeats over active streams to prevent intermediary proxy timeouts.

#### Client Event Listening & State Management
- **FR-008**: Web client MUST subscribe to the real-time event stream upon user authentication and maintain connection while the tab is active.
- **FR-009**: Mobile client MUST subscribe to the real-time event stream when in the foreground and terminate the connection when paused/backgrounded.
- **FR-010**: Client applications MUST debounce incoming live event signals (e.g., 300ms - 500ms window) before executing a pull, consolidating rapid successive events into a single delta pull.
- **FR-011**: Client applications MUST automatically invalidate cached data and update active UI views whenever pulled deltas contain modified or deleted records.
- **FR-012**: Client applications MUST NOT disrupt active user input, unsaved form fields, or scroll positions when live sync updates background data stores.

#### Connection Lifecycle & Resilience
- **FR-013**: Client applications MUST detect connection dropouts and attempt automatic reconnection using exponential backoff with jitter.
- **FR-014**: Client applications MUST execute an immediate catch-up delta sync upon successfully reconnecting after a disconnect period.
- **FR-015**: Client applications MUST expose real-time connection status (`connected`, `connecting`, `offline`, `syncing`) to the user interface.

---

### Key Entities

- **Sync Event Signal**: Lightweight notification payload transmitted over the live stream (`event_type`, `table_name`, `server_timestamp`, `source_client_id`).
- **Client Session**: Active streaming connection metadata maintained by the server (`user_id`, `client_id`, `platform`, `connected_at`, `last_ping_at`).
- **Sync State**: Local client synchronization metadata (`last_synced_at`, `connection_status`, `pending_mutations_count`, `active_stream_state`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: **Cross-Device Latency**: When a financial mutation is saved on Device A, Device B reflects the updated data within **1.5 seconds** under standard broadband/4G network conditions.
- **SC-002**: **Zero Data Loss**: 100% data consistency across all connected devices after concurrent or sequential mutations, verified by matching total balances and record counts across devices.
- **SC-003**: **Resource Efficiency**: Mobile application maintains **zero open streaming connections** while in the background or device locked state, resulting in 0% background battery drain from real-time sync.
- **SC-004**: **Auto-Recovery Time**: Following a network drop or server restart, clients re-establish connection and complete catch-up delta synchronization within **3 seconds** of network restoration.
- **SC-005**: **Non-Disruptive UI**: 100% of background sync updates complete without resetting form inputs, losing focus on active elements, or causing visual page flickering.
- **SC-006**: **Debounce Effectiveness**: Rapid bursts of 50 consecutive mutations within 2 seconds on Device A trigger at most **2 delta pull requests** on Device B.

---

## Assumptions

- Both Web UI and Mobile App share the existing backend synchronization protocol (`/api/v1/sync`) and domain entity schema.
- Server-Sent Events (SSE) standard HTTP streaming is supported by the deployment infrastructure (Docker, reverse proxies, and cloud host).
- Clients possess local persistent storage (SQLite on Mobile, IndexedDB on Web) capable of storing records and pending sync mutation queues offline.
- Authentication is handled via existing session cookies or JWT bearer tokens passed during stream connection initialization.
