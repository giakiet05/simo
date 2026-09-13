# Feature Specification: Multi-Device Synchronization & Web Interface

**Feature Branch**: `016-multi-device-sync-and-web`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "backend để sync data giữa nhiều thiết bị, và giao diện web. 1 api sync kết hợp push/pull, PostgreSQL homeserver qua .env, offline-first tự động hoàn toàn"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Seamless Multi-Device Cloud Sync (Priority: P1)

As a Simo user who tracks personal finances on a mobile phone, I want all my transactions, wallets, categories, budgets, debts, and saving goals to sync automatically with the cloud whenever I have an internet connection, so that when I open the app on another phone or web browser, all my financial data is immediately up-to-date and consistent without requiring manual backup/restore actions.

**Why this priority**: Core value of the feature. Unlocks multi-device continuity and protects user data from device loss.

**Independent Test**:
1. User logs into Account X on Mobile Device A and creates a wallet "Techcombank" with initial balance 5,000,000 VND and records an expense "Lunch" of 50,000 VND.
2. User logs into Account X on Mobile Device B.
3. System automatically pulls data; Device B displays the "Techcombank" wallet with accurate balance 4,950,000 VND and the "Lunch" transaction.

**Acceptance Scenarios**:
1. **Given** a user is logged in on Mobile Device A with an active internet connection, **When** they add, edit, or delete any financial record, **Then** the local SQLite database is updated immediately (<16ms) and the change is pushed to the backend server within a short debounce window (~500ms).
2. **Given** a user opens Mobile Device B or brings it to the foreground, **When** the app connects to the network, **Then** the app queries the backend for changes since the last sync time and applies new/updated records to local storage without duplicate entries or data loss.
3. **Given** a user makes changes while offline on Mobile Device A, **When** internet connectivity is restored, **Then** all pending local mutations are automatically flushed to the backend and remote changes are pulled down.

---

### User Story 2 - Desktop & Web Financial Management Interface (Priority: P2)

As a user sitting at my desk or laptop, I want to access my Simo financial records through a fast, responsive web interface, so that I can comfortably review detailed monthly spending charts, manage budgets, and perform bulk transaction entries with a full keyboard and large screen.

**Why this priority**: Expands Simo beyond mobile, satisfying the need for desktop productivity and comprehensive financial review.

**Independent Test**:
1. User opens the Web App in any modern web browser and authenticates with their account.
2. Web App displays dashboard summary (total balance, monthly income/expenses, spending by category chart).
3. User adds a transaction on the Web App; the transaction immediately appears on their Mobile Device once synced.

**Acceptance Scenarios**:
1. **Given** an authenticated user on the Web App, **When** they navigate to the Dashboard, **Then** they see total assets, monthly budget progress, and breakdown charts matching their synced records.
2. **Given** a user edits a category or adds a transaction on the Web App, **When** they submit the form, **Then** the change is saved directly to the database and is ready to be pulled by mobile clients on their next sync cycle.

---

### User Story 3 - Automatic Conflict Resolution & Offline Convergence (Priority: P3)

As a user who occasionally records transactions in areas without cellular coverage, I want the system to resolve data conflicts automatically when both devices have been modified independently, so that my account balances and financial history remain accurate without confusing error prompts.

**Why this priority**: Ensures data integrity under edge cases (concurrent edits, network dropouts, clock skews).

**Independent Test**:
1. Device A and Device B both start with 1,000,000 VND balance.
2. Device A goes offline and records -200,000 VND expense.
3. Device B records -300,000 VND expense and syncs.
4. Device A comes back online and syncs.
5. Both devices converge to an exact calculated balance of 500,000 VND with both transactions preserved.

**Acceptance Scenarios**:
1. **Given** two devices modify the same record while one is offline, **When** both devices sync, **Then** the system applies the change with the latest modification timestamp (Last-Write-Wins), while preserving deleted states (Tombstones) over stale updates.
2. **Given** multiple transactions are added across different devices, **When** synchronizing, **Then** the wallet balance is recalculated from cumulative transaction deltas rather than blindly overwriting balance values.

---

### Edge Cases

- **Network Interruption mid-sync**: If the network connection drops after the server persists mutations but before the client receives the acknowledgment, the client will re-send the payload on the next attempt; the server must process it idempotently using client-generated UUIDs without creating duplicate records.
- **Client Clock Skew**: If a device has an inaccurate system clock, the sync engine uses the server's monotonic timestamp as the cursor (`last_synced_server_time`) to prevent skipping remote changes.
- **Orphaned Dependent Records**: If a category or wallet is deleted on Device B while Device A creates a transaction linked to it offline, the system safely unlinks or reassigns the transaction to a default wallet upon syncing rather than failing foreign key constraints.
- **Simultaneous Deletion and Edit**: If Device A deletes an entity while Device B edits it, the deletion (tombstone) takes precedence to prevent "zombie" records from reappearing.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a unified 2-way synchronization endpoint (`POST /api/v1/sync`) that accepts local mutations (upserts and deletions) and returns server changes generated after a client-supplied timestamp cursor.
- **FR-002**: System MUST process sync requests in "Push-First, Then Pull" order within a single transactional cycle to ensure mutations from the current request are committed before querying delta changes.
- **FR-003**: System MUST identify all financial records (wallets, categories, transactions, monthly budgets, saving goals, loans) using client-generated unique identifiers (UUID v4) to ensure idempotent upserts.
- **FR-004**: System MUST support soft deletions (tombstones) across all synchronizable entities so that deleted records propagate reliably to all client devices.
- **FR-005**: System MUST compute wallet current balances on client devices derived from initial balances and transaction deltas, ensuring balance convergence across devices without overwriting race conditions.
- **FR-006**: Backend service MUST load all database connection credentials (host, port, username, password, database name) strictly from environment variables without hardcoded connection strings.
- **FR-007**: Client app MUST maintain a local queue of unsynced mutations with a `synced` flag and automatically trigger synchronization upon mutation (with debounce), upon network reconnection, and upon application foregrounding.
- **FR-008**: System MUST authenticate all sync and management requests securely via tokens tied to the user account, ensuring strict multi-tenant data isolation.
- **FR-009**: Web interface MUST provide authenticated views for viewing dashboards, recording transactions, managing wallets/categories, and viewing spending statistics.

---

### Key Entities

- **User Profile**: Represents the authenticated user account and global preferences (currency, budget, language).
- **Wallet**: Represents a financial repository (Cash, Bank, E-Wallet) with an initial balance, currency, color, icon, and display priority.
- **Transaction**: Represents an individual income or expense record linked to a wallet and optional category, with amount, date, formula, and note.
- **Wallet Transfer**: Represents an atomic transfer between a source wallet and a destination wallet with an optional fee.
- **Category & Category Budget**: Represents spending/income classifications and optional monthly spending limits.
- **Monthly Budget**: Represents total spending limits for a given year and month.
- **Saving Goal & Goal Log**: Represents savings targets and individual deposit/withdrawal logs.
- **Loan Contact & Loan Transaction**: Represents debt/lending contacts and partial repayment histories.
- **Sync Mutation Batch**: Payload containing lists of entity upserts and tombstone deletions accompanied by the client's last sync timestamp cursor.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Data entered on one device appears on a second device within 3 seconds under normal network conditions.
- **SC-002**: 100% of offline transactions are successfully preserved and synchronized once connectivity is re-established without user intervention.
- **SC-003**: Zero duplicate transactions created even under simulated 50% network packet drop rates and repeated sync retries.
- **SC-004**: Web interface initial dashboard loads and renders financial data in under 1.5 seconds on desktop broadband.
- **SC-005**: Account balance across multiple devices converges to the exact same value in 100% of tested concurrent transaction scenarios.

---

## Assumptions

- Each user operates within their own isolated financial space (personal finance; no shared family wallets in v1).
- Client devices have local storage capabilities (SQLite on Mobile, local cache / API fetch on Web).
- Database is a standard PostgreSQL instance hosted on the user's infrastructure or cloud service, accessible via environment configuration.
- The standard user workflow is predominantly single-user interleaved actions across devices rather than high-frequency simultaneous typing on two devices at the exact same millisecond.
