# Research & Technical Decisions: Fix Transaction Date Handling and Timestamps

## Overview
This document records technical investigations and architectural decisions for fixing the transaction date mutation bug during edits, implementing 3-tier timestamp tracking (`transactionDate`, `createdAt`, `updatedAt`), and ensuring consistent sorting and presentation.

---

### Decision 1: Form Initialization & Date Fallback for Edit Mode
- **Decision**: Update `TransactionFormScreen` constructor and `TransactionItem` state to accept and pre-populate `editTransactionDate` and `editCreatedAt` (or accept the `Transaction` model directly). If `editTransactionDate` is present, use it; if null/legacy, fallback to `editCreatedAt`; default to `DateTime.now()` only for new transaction creation.
- **Rationale**: Currently `TransactionItem.transactionDate` defaults unconditionally to `DateTime.now()`, causing any edit to overwrite the transaction's date to the current date. Passing and binding the existing date directly prevents data corruption.
- **Alternatives Considered**:
  - *Fetching transaction again from DB in initState*: Adds unnecessary async state loading and latency when caller already has the complete `Transaction` entity.
  - *Setting transactionDate to null in form*: Would violate non-null domain contract in Flutter model.

---

### Decision 2: Timestamp Management & Persistence
- **Decision**:
  - `createdAt`: Set once upon creation (immutable).
  - `transactionDate`: User-editable; defaults to chosen date (or now) on creation, preserved during updates unless explicitly edited.
  - `updatedAt`: Refreshed to `DateTime.now()` on every update in repository/provider.
- **Rationale**: Provides full traceability of financial event time vs. record creation time vs. modification time.
- **Alternatives Considered**:
  - *Database triggers for `updated_at`*: SQLite triggers can be brittle across schema migrations and mock/unit tests. Explicit application-level assignment in `TransactionRepository` and `TransactionProvider` is standard for this codebase.

---

### Decision 3: Sorting Order Consistency Across Views
- **Decision**: Ensure all database queries and in-memory lists sort transactions by `COALESCE(transaction_date, created_at) DESC, created_at DESC`.
- **Rationale**: Groups and orders financial statements chronologically by when transactions occurred in reality rather than when they were entered into the system.
- **Alternatives Considered**:
  - *Sorting by `created_at`*: Breaks user expectation when entering backdated or historical expenses.

---

### Decision 4: UI Representation of 3-Tier Timestamps
- **Decision**: In transaction details / action modal bottom sheet:
  - Add a dedicated detail row or header displaying:
    1. **Ngày giao dịch (Transaction Date)**: Date when transaction occurred (`dd/MM/yyyy`).
    2. **Ngày tạo (Created At)**: Timestamp when record was created (`dd/MM/yyyy HH:mm`).
    3. **Ngày cập nhật (Updated At)**: Timestamp when record was last updated (`dd/MM/yyyy HH:mm`).
- **Rationale**: Satisfies explicit requirement for transparency and order of timestamps.
- **Alternatives Considered**:
  - *Showing only transaction date on tile, hiding others*: User explicitly requested viewing all three timestamps in order.
