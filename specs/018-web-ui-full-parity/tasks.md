# Tasks: Web UI Full Feature Parity with Android App

**Feature**: `018-web-ui-full-parity`
**Date**: 2026-09-13
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, theme tokens, and TypeScript type declarations for all 11 financial entities.

- [X] T001 Define core financial entity types (11 entities + pending deletions) in apps/web/src/types/index.ts
- [X] T002 [P] Configure Tailwind CSS v4 design tokens and semantic theme CSS variables in apps/web/src/index.css
- [X] T003 [P] Implement ThemeContext (White Light Mode default, Slate Dark Mode, system preference listener) in apps/web/src/contexts/ThemeContext.tsx
- [X] T004 [P] Implement client-side IndexedDB / LocalStorage database adapter in apps/web/src/services/db.ts

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core state management, authentication, and client bidirectional sync engine.

- [X] T005 Implement client SyncService (mutation tracking `synced = 0`, tombstone records, debounce trigger, offline queue) in apps/web/src/services/syncService.ts
- [X] T006 Implement unified FinanceContext (reactive local store for all 11 entities) in apps/web/src/contexts/FinanceContext.tsx
- [X] T007 [P] Create reusable UI primitives (Button, Input, Select, Modal, Card, Badge, Alert) in apps/web/src/components/ui/index.tsx
- [X] T008 [P] Update REST API client to support full sync payload and profile endpoints in apps/web/src/services/api.ts

**Checkpoint**: Foundation ready - local financial store, theme tokens, and sync engine operational.

---

## Phase 3: User Story 1 - Financial Overview & Responsive Navigation (Priority: P1) 🎯 MVP

**Goal**: Deliver desktop/mobile navigation layout, header with sync status & theme switcher, and the central financial dashboard overview.

**Independent Test**: Load web app, verify crisp white light theme (default), toggle dark mode, view net worth and monthly cashflow summary cards.

- [X] T009 [P] [US1] Build responsive desktop Sidebar and mobile Navigation Drawer in apps/web/src/components/Sidebar.tsx
- [X] T010 [P] [US1] Update Top Navigation Header with live Sync Status badge, theme toggle, and user profile in apps/web/src/components/Navbar.tsx
- [X] T011 [US1] Build Net Worth summary, Monthly Cashflow metrics, and Quick Action buttons in apps/web/src/pages/Dashboard.tsx
- [X] T012 [US1] Connect Dashboard widgets with live FinanceContext data in apps/web/src/pages/Dashboard.tsx
- [X] T013 [US1] Integrate responsive layout and tab routing in apps/web/src/App.tsx

**Checkpoint**: Core layout and live overview dashboard fully functional in both Light and Dark themes.

---

## Phase 4: User Story 9 - Cross-Device Real-Time Sync & Authentication (Priority: P1)

**Goal**: Full Google Sign-In / session authentication and background bidirectional synchronization with Go server.

**Independent Test**: Sign in with Google, trigger manual sync, and verify local mutations sync to the server with `synced = 0` handling.

- [X] T014 [P] [US9] Integrate Google OAuth login screen and user session persistence in apps/web/src/pages/Login.tsx
- [X] T015 [US9] Hook online/offline browser events and background sync triggers in apps/web/src/contexts/FinanceContext.tsx
- [X] T016 [US9] Build Sync Status detail popover with last synced timestamp and manual "Sync Now" button in apps/web/src/components/SyncStatusPopover.tsx

**Checkpoint**: Web app authenticates seamlessly and syncs bi-directionally with the backend.

---

## Phase 5: User Story 2 - Comprehensive Transaction Management & Advanced Filtering (Priority: P1)

**Goal**: Date-grouped transaction timeline, advanced multi-parameter filtering, fuzzy search, full CRUD modal, and bulk operations.

**Independent Test**: Create an expense/income/transfer transaction, filter by date/wallet/category, search keywords, and bulk delete selected transactions.

- [X] T017 [P] [US2] Build TransactionFormModal (Amount calculator, Category picker with icons/colors, Wallet picker, Date/Time, Note) in apps/web/src/components/TransactionModal.tsx
- [X] T018 [P] [US2] Build Advanced Filter Bar (Date range presets, multi-category selector, wallet filter, type filter, amount range) in apps/web/src/components/TransactionFilterBar.tsx
- [X] T019 [US2] Build date-grouped Transaction List with daily income/expense subtotals and checkbox selection in apps/web/src/pages/Transactions.tsx
- [X] T020 [US2] Implement Fuzzy Search across transaction notes and contact names in apps/web/src/pages/Transactions.tsx
- [X] T021 [US2] Implement Bulk Actions toolbar (Bulk delete, bulk category change, bulk date change) in apps/web/src/pages/Transactions.tsx

**Checkpoint**: Transactions ledger fully manageable with desktop-grade filtering and bulk edits.

---

## Phase 6: User Story 3 - Multi-Wallet & Transfer Management (Priority: P1)

**Goal**: Multi-wallet account cards, wallet creation/editing modal, inter-wallet transfers with fee support, and wallet statement detail view.

**Independent Test**: Create a bank wallet, transfer funds to cash wallet with a fee, and inspect the wallet statement timeline.

- [X] T022 [P] [US3] Build WalletFormModal (Name, Type, Currency, Icon, Color, Credit Limit, Exclude from Total) in apps/web/src/components/WalletModal.tsx
- [X] T023 [P] [US3] Build WalletTransferModal (Source Wallet, Target Wallet, Amount, Fee, Note) in apps/web/src/components/WalletTransferModal.tsx
- [X] T024 [US3] Build Wallets grid view with balance totals and default wallet badges in apps/web/src/pages/Wallets.tsx
- [X] T025 [US3] Build Wallet Detail view with balance progression chart and filtered statement history in apps/web/src/pages/WalletDetail.tsx

**Checkpoint**: Multi-account ledger and inter-wallet transfers operational.

---

## Phase 7: User Story 4 - Monthly Budget & Category-Level Allocation (Priority: P2)

**Goal**: Overall monthly spending budget, category-specific allocations, visual progress bars with warning threshold badges, and multi-month navigation.

**Independent Test**: Set a 10M VND overall budget and 3M VND dining budget; verify color thresholds change as expenses accumulate.

- [X] T026 [P] [US4] Build BudgetModal (Overall monthly limit & per-category allocation limits) in apps/web/src/components/BudgetModal.tsx
- [X] T027 [US4] Build Budgets page with overall spending gauge, category progress bars (<80%, 80-100%, >100%), and month picker navigation in apps/web/src/pages/Budgets.tsx

**Checkpoint**: Monthly and category budget tracking working with visual alert indicators.

---

## Phase 8: User Story 5 - Saving Goals & Contribution Tracking (Priority: P2)

**Goal**: Saving goals grid, goal creation modal, deposit/withdraw contribution tracking linked to wallets.

**Independent Test**: Create a saving goal with a target amount and date, log a deposit from a wallet, and verify progress percentage.

- [X] T028 [P] [US5] Build SavingGoalModal (Name, Target Amount, Target Date, Color, Icon) in apps/web/src/components/SavingGoalModal.tsx
- [X] T029 [P] [US5] Build SavingGoalLogModal (Deposit / Withdraw funds linked to a wallet) in apps/web/src/components/SavingGoalLogModal.tsx
- [X] T030 [US5] Build Saving Goals page with progress cards, recommended monthly savings, and contribution history in apps/web/src/pages/SavingGoals.tsx

**Checkpoint**: Goal-oriented savings and deposits fully functional.

---

## Phase 9: User Story 6 - Debt & Loan Book (Sổ nợ / Vay & Cho vay) (Priority: P2)

**Goal**: Loan contacts directory, borrow/lend records, partial and full debt repayments, and settlement tracking.

**Independent Test**: Add contact, log a Lend transaction, record a repayment, and verify outstanding receivable balance.

- [X] T031 [P] [US6] Build LoanContactModal and LoanTransactionModal (Borrow, Lend, Repayment) in apps/web/src/components/LoanModal.tsx
- [X] T032 [US6] Build Loans page with Contact list, total receivables/payables summaries, and transaction settlement timeline in apps/web/src/pages/Loans.tsx

**Checkpoint**: Sổ nợ (Debts & Loans) tracking operating with complete settlement lifecycle.

---

## Phase 10: User Story 7 - Recurring Transactions Engine (Priority: P3)

**Goal**: Scheduled recurring transactions manager (daily, weekly, monthly, yearly) and upcoming due dates preview.

**Independent Test**: Create recurring rule for monthly rent, verify next run date calculation and upcoming preview.

- [X] T033 [P] [US7] Build RecurringModal (Frequency, Amount, Category, Wallet, Next Run Date) in apps/web/src/components/RecurringModal.tsx
- [X] T034 [US7] Build Recurring page with active schedules list and 30-day upcoming transactions preview in apps/web/src/pages/Recurring.tsx

**Checkpoint**: Recurring financial rules engine active.

---

## Phase 11: User Story 8 - Financial Reports, Visual Analytics & Data Export (Priority: P3)

**Goal**: Interactive Category Breakdown Donut chart, Cashflow Trend Bar/Line charts, CSV/Excel/PDF export, and JSON Database Backup/Restore.

**Independent Test**: View category spending breakdown for selected month, export transactions to Excel/PDF, and download full JSON backup.

- [X] T035 [P] [US8] Build Category Donut Chart and Cashflow Trend Bar/Line charts in apps/web/src/components/charts/FinancialCharts.tsx
- [X] T036 [P] [US8] Build client-side CSV, Excel (.xlsx), and PDF export generators in apps/web/src/services/exportService.ts
- [X] T037 [US8] Build Reports page with dynamic time-range filters, category breakdown percentages, and cashflow charts in apps/web/src/pages/Reports.tsx
- [X] T038 [US8] Build Export & Backup page with custom filters, file download buttons, and JSON Backup/Restore modal in apps/web/src/pages/ExportBackup.tsx

**Checkpoint**: Analytics charts and multi-format data export engine fully implemented.

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Categories management modal, Settings preferences, mock data generator, and End-to-End validation.

- [X] T039 [P] Build Categories management screen/modal (Add, Edit, Delete with reassignment) in apps/web/src/components/CategoryModal.tsx
- [X] T040 [P] Build Settings page (Currency selector, Language selector, Theme preferences, Mock Data Generator) in apps/web/src/pages/Settings.tsx
- [X] T041 Run TypeScript compiler (`tsc -b`) and linter (`oxlint`) across apps/web to ensure zero build errors
- [X] T042 Execute End-to-End Quickstart scenarios from specs/018-web-ui-full-parity/quickstart.md to verify 100% feature parity

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup (T001-T004) [COMPLETED]
        │
        ▼
Phase 2: Foundational (T005-T008) [COMPLETED]
        │
        ├──────────────────────┬──────────────────────┬──────────────────────┐
        ▼                      ▼                      ▼                      ▼
Phase 3: US1 Overview   Phase 4: US9 Sync      Phase 5: US2 Txns      Phase 6: US3 Wallets
(T009-T013)             (T014-T016)            (T017-T021)            (T022-T025)
[COMPLETED]             [COMPLETED]            [COMPLETED]            [COMPLETED]
        │                      │                      │                      │
        └──────────────────────┼──────────────────────┴──────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┬──────────────────────┐
        ▼                      ▼                      ▼                      ▼
Phase 7: US4 Budgets    Phase 8: US5 Goals     Phase 9: US6 Loans     Phase 10: US7 Recurring
(T026-T027)             (T028-T030)            (T031-T032)            (T033-T034)
[COMPLETED]             [COMPLETED]            [COMPLETED]            [COMPLETED]
        │                      │                      │                      │
        └──────────────────────┼──────────────────────┴──────────────────────┘
                               │
                               ▼
                        Phase 11: US8 Analytics & Export (T035-T038) [COMPLETED]
                               │
                               ▼
                        Phase 12: Polish & E2E Verification (T039-T042) [COMPLETED]
```
