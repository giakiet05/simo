# Implementation Plan: Fix Transaction Date Handling and Timestamps

**Branch**: `001-fix-transaction-dates` | **Date**: 2026-08-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-fix-transaction-dates/spec.md`

## Summary

Fix bug where editing a past transaction resets its `transactionDate` to today's date due to uninitialized date state in `TransactionFormScreen`. Implement full 3-tier timestamp management (`transactionDate`, `createdAt`, `updatedAt`) across models, database queries, and state providers, and display all 3 timestamps in the transaction detail UI in chronological order. Ensure all transaction listings sort by `transactionDate` descending.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x

**Primary Dependencies**: `flutter_riverpod` (^2.6.1), `sqflite` (^2.4.1), `intl` (^0.19.0)

**Storage**: SQLite local database via `sqflite` (`transactions` table)

**Testing**: `flutter_test` unit & widget tests

**Target Platform**: Android & iOS mobile app

**Project Type**: Flutter Mobile Application

**Performance Goals**: Instant form initialization and <16ms UI frame render time for transaction lists

**Constraints**: Offline-first local storage; backward compatibility with legacy transaction records where `transaction_date` or `updated_at` may be null or equal to `created_at`

**Scale/Scope**: Impacts Transaction model, SQLite repository queries, TransactionFormScreen, TransactionScreen, and DashboardScreen

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Principle I (Modularity): PASSED - Repository and provider abstraction respected.
- Principle II (Data Integrity & Backward Compatibility): PASSED - Legacy data migration fallback preserves existing records.
- Principle III (Test-First): PASSED - Verification scenarios defined in quickstart.md.

## Project Structure

### Documentation (this feature)

```text
specs/001-fix-transaction-dates/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── transaction-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
lib/
├── models/
│   └── transaction.dart               # Transaction model with transactionDate, createdAt, updatedAt
├── providers/
│   └── transaction_provider.dart      # TransactionNotifier update & sorting logic
├── repositories/
│   ├── database_helper.dart           # SQLite schema & migrations
│   └── transaction_repository.dart    # SQLite queries sorted by transaction_date
├── screens/
│   ├── transaction_form_screen.dart   # Edit form date pre-population & fallback
│   ├── transaction_screen.dart        # List display, 3-tier timestamp modal, sorting
│   └── dashboard_screen.dart          # Recent transactions sorting & edit routing
test/
└── unit/
    └── transaction_date_test.dart     # Unit tests for date fallback, sorting & timestamp updates
```

**Structure Decision**: Standard Flutter Clean/Layered feature structure: Model -> Repository -> Provider -> UI Screen.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| None | N/A | N/A |
