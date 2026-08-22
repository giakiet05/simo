# Feature Specification: Fix Transaction Date Handling and Timestamps

**Feature Branch**: `001-fix-transaction-dates`

**Created**: 2026-08-20

**Status**: Draft

**Input**: User description: "hiện tại đang có 1 bug như thế này: transaction đã tạo ở tháng 3 (lúc đó chưa tách 2 field là ngày tạo và ngày giao dịch ) -> update transaction vào tháng 8 -> transactin đó bị dời lên tháng 8 (ngày tạo là tháng 3 nhưng ngày giao dịch là tháng 8). Lí do: trong form update đang set ngày giao dịch là hôm nay, đúng ra phải set là ngày tạo (nếu ngày giao dịch = null hoặc = ngày tạo, của data trước đợt migration sang 2 ngày). tốt nhất nên bổ sung thêm ngày cập nhật nữa (updatedAt), ví dụ tháng 7, tạo một transaction cho tháng 3, sau đó tháng 8 update transaction này thì trong giao diện hiện đủ 3 ngày theo thứ tự: ngày giao dịch là tháng 3, ngày tạo là tháng 7, ngày cập nhật là tháng 8. sort thì theo ngày giao dichj"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Preserve Transaction Date on Edit (Priority: P1)

When a user edits an existing transaction (e.g., changing amount, note, or category), the transaction must preserve its original transaction date and remain in its original timeframe/month rather than unintentionally jumping to today's date.

**Why this priority**: Core bug fix. When updating past transactions, changing their financial occurrence date corrupts monthly expense tracking and financial reports.

**Independent Test**: Edit a transaction from a past month (e.g., changing note or amount without touching the date selector) and verify that after saving, its transaction date is preserved and it remains listed under the original month.

**Acceptance Scenarios**:

1. **Given** an existing transaction with `transactionDate` in March, **When** the user opens the edit form and updates the transaction note or amount and saves, **Then** the `transactionDate` remains in March and the transaction stays in the March summary.
2. **Given** a legacy transaction where `transactionDate` was not distinctly initialized or equals `createdAt` (March), **When** the user edits the transaction, **Then** the edit form pre-populates the transaction date with March (the original creation date) instead of the current date.
3. **Given** an edit form open for a transaction, **When** the user explicitly selects a new transaction date and saves, **Then** the transaction date is updated to the newly selected date.

---

### User Story 2 - Transaction Sorting by Transaction Date (Priority: P1)

When viewing the transaction list, monthly breakdown, or recent activities on the dashboard, transactions are ordered chronologically based on their Transaction Date (the date the transaction actually happened), not by when they were created or edited.

**Why this priority**: Users view and balance their budget according to when spending or income occurred in reality.

**Independent Test**: Create or update a transaction setting its transaction date in the past (e.g., created today for last week) and verify it appears in the list positioned by last week's date.

**Acceptance Scenarios**:

1. **Given** multiple transactions with different transaction dates, creation dates, and update dates, **When** the user views the transaction list or dashboard, **Then** transactions are sorted descending by `transactionDate` (newest transaction date at the top).
2. **Given** a transaction created in July with a transaction date in March, **When** the user checks the March transaction history, **Then** the transaction appears in the March list and monthly total.

---

### User Story 3 - View Detailed 3-Tier Timestamps (Priority: P2)

When a user inspects a transaction's details, the UI clearly presents all three distinct timestamps in a consistent, logical sequence: Transaction Date, Created At date/time, and Updated At date/time.

**Why this priority**: Transparency and auditability. Allows users to clearly distinguish between when money was spent, when the record was entered, and when it was last modified.

**Independent Test**: View the details of a transaction created in July for an event in March and edited in August, and verify that all 3 dates are displayed in the specified order.

**Acceptance Scenarios**:

1. **Given** a transaction created in July for March and updated in August, **When** the user views the transaction details, **Then** the UI displays:
   - 1st: Transaction Date (March)
   - 2nd: Created Date & Time (July)
   - 3rd: Updated Date & Time (August)
2. **Given** a newly created transaction that has not been updated yet, **When** the user views the transaction details, **Then** the UI displays the Transaction Date and Created Date/Time (and Updated Date matching Created Date or cleanly indicated).

---

### Edge Cases

- **Legacy data with null/missing transaction date**: The system must gracefully fallback to `createdAt` as the initial transaction date when loading or editing the transaction.
- **Multiple rapid edits**: Every save updates `updatedAt` to the exact time of modification without altering `createdAt` or `transactionDate` (unless explicitly changed).
- **Timezone consistency**: Date conversions and comparisons for grouping/sorting must preserve the user's local date calendar boundaries.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST pre-populate the transaction edit form with the existing `transactionDate` of the record being edited.
- **FR-002**: For legacy records without an explicit `transactionDate`, the edit form MUST fallback to using the record's `createdAt` as the default transaction date instead of the current date.
- **FR-003**: System MUST record and maintain three distinct timestamp attributes for each transaction:
  - `transactionDate`: The date/time when the expense or income occurred.
  - `createdAt`: The date/time when the record was initially created.
  - `updatedAt`: The date/time when the record was last modified.
- **FR-004**: System MUST automatically refresh `updatedAt` with the current timestamp whenever any property of a transaction is updated.
- **FR-005**: System MUST sort transactions throughout all listing views (dashboard, transaction history, reports) by `transactionDate` in descending order by default.
- **FR-006**: System MUST present all three timestamps on the transaction detail interface in the specific order:
  1. Transaction Date
  2. Created At (Date & Time)
  3. Updated At (Date & Time)
- **FR-007**: System MUST ensure `createdAt` remains immutable once a transaction is saved.

### Key Entities *(include if feature involves data)*

- **Transaction**: Represents a financial record containing:
  - `id`: Unique record identifier
  - `amount`: Monetary value
  - `type`: Expense, Income, or Transfer
  - `category`: Associated spending/income category
  - `note`: Optional user note/description
  - `transactionDate`: Date/time of actual financial occurrence (used for reporting and sorting)
  - `createdAt`: Timestamp when record was created (immutable)
  - `updatedAt`: Timestamp when record was last modified

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of transaction edit operations preserve the existing `transactionDate` unless the user explicitly alters the date selector in the form.
- **SC-002**: 100% of transaction lists, monthly balances, and expense reports reflect data grouped and sorted by `transactionDate`.
- **SC-003**: Zero incidents of transactions unintentionally shifting to the current month after editing details like note or amount.
- **SC-004**: Users can view all 3 timestamps (`transactionDate`, `createdAt`, `updatedAt`) on the transaction detail screen in a single view.

## Assumptions

- When a transaction is newly created, `transactionDate` defaults to the date chosen by the user (or current date if not specified), `createdAt` is set to the current timestamp, and `updatedAt` is set to the current timestamp.
- User interface sorting is always based on `transactionDate` descending, with secondary tie-breaker on `createdAt` descending.
- Legacy transactions prior to date separation will treat `createdAt` as the source of truth for `transactionDate` if `transactionDate` was missing.
