# Tasks: Interactive Dashboard Financial Hub & Metric Navigation (Trung tâm điều phối tài chính Dashboard)

**Branch**: `012-dashboard-interactive-hub` | **Spec**: [specs/012-dashboard-interactive-hub/spec.md](spec.md) | **Plan**: [specs/012-dashboard-interactive-hub/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Component creation

- [x] T001 [P] Create `MonthlyMetricsGrid` widget in `lib/widgets/dashboard/monthly_metrics_grid.dart` with 2x2 grid for Income, Expense, Lent, and Borrowed

---

## Phase 2: User Story 1 - Unified 2x2 Monthly Metrics Grid on Dashboard (Priority: P1) 🎯 MVP

**Goal**: Present Income, Expense, Lent, and Borrowed in a balanced 2x2 grid with symmetrical styles and comma-separated numbers.

**Independent Test**: View Dashboard; verify Net Cashflow card is followed by the 2x2 metrics grid.

### Implementation for User Story 1
- [x] T002 [P] [US1] Streamline `MonthlyCashflowCard` in `lib/widgets/dashboard/monthly_cashflow_card.dart` to focus on Net Cashflow and support `onTap`
- [x] T003 [US1] Integrate `MonthlyMetricsGrid` into `DashboardScreen` in `lib/screens/dashboard_screen.dart` and remove standalone loan summary box

**Checkpoint**: 2x2 grid renders seamlessly on Dashboard

---

## Phase 3: User Story 2 - Comprehensive 1-Tap Dashboard Navigation (Priority: P1)

**Goal**: Connect interactive tap callbacks across all Dashboard cards to route directly to Statistics, Transactions, Loans, and Budgets.

**Independent Test**: Tap each card on Dashboard and verify immediate transition to corresponding screen.

### Implementation for User Story 2
- [x] T004 [US2] Wire tap handlers for Net Cashflow (to `StatisticsScreen`), Income/Expense (to `TransactionScreen`), Loans (to `LoanScreen`), and Budgets (to `CategoryBudgetScreen`) in `lib/screens/dashboard_screen.dart`

**Checkpoint**: All dashboard cards are fully interactive

---

## Phase 4: Polish & Verification

**Purpose**: Build verification and quality gate

- [x] T005 Run all unit tests with `flutter test --concurrency=1 test/unit/`
- [x] T006 Verify debug build with `flutter build apk --debug`
