# Implementation Plan: Multi-Month Budget Management & Rich Mock Data

**Feature**: [Multi-Month Budget Management & Rich Mock Data](spec.md)  
**Branch**: `003-multi-month-budgets`  
**Status**: In Progress  
**Created**: 2026-08-21  

---

## Technical Context

- **Architecture**: Flutter (Riverpod StateNotifier + SQLite via `sqflite`)
- **Key Modules**:
  - `lib/models/monthly_budget.dart`: Domain entities for monthly budget & category monthly limits.
  - `lib/repositories/database_helper.dart`: Schema migrations (v4) for `monthly_budgets` and `category_monthly_budgets` tables.
  - `lib/repositories/monthly_budget_repository.dart`: CRUD repository for monthly budgets.
  - `lib/providers/monthly_budget_provider.dart`: Riverpod state management and budget calculation logic.
  - `lib/screens/category_budget_screen.dart`: Multi-month navigation header and monthly category limit editor.
  - `lib/utils/mock_data_generator.dart`: Generation of 6 months (03/2026 to 08/2026) of total & category budgets.
  - `lib/screens/statistics_screen.dart`: Integration with monthly budget for category breakdown.
  - `lib/widgets/dashboard/budget_sheet.dart`: Monthly budget summary for active month.

---

## Constitution Check

- [X] **Clean Architecture**: Separation between SQLite storage, domain repositories, Riverpod providers, and presentation layer.
- [X] **Backward Compatibility**: Existing database versions upgraded smoothly via `_upgradeDB` in `DatabaseHelper`.
- [X] **No Destructive Overwrites**: Real production database intact; isolated development environment.
- [X] **Comprehensive Test Coverage**: Unit tests for repository, calculation logic, and mock data generation.

---

## Phase Breakdown

### Phase 1: Database Schema & Entity Models
- Define `MonthlyBudget` and `CategoryMonthlyBudget` data models.
- Add `monthly_budgets` and `category_monthly_budgets` tables in `DatabaseHelper` (Database version bump to 4) with unique indices.
- Update `clearAllData()` in `DatabaseHelper` to truncate new budget tables.

### Phase 2: Repository & Riverpod State Management
- Implement `MonthlyBudgetRepository` with methods to query, save, delete, and copy monthly budgets.
- Implement `monthlyBudgetProvider` to compute real-time spending progress against budgets per `(year, month)`.

### Phase 3: Multi-Month Mock Data Generation (User Story 2)
- Update `MockDataGenerator` to generate total monthly budgets and per-category budget allocations for March, April, May, June, July, and August 2026.
- Ensure varied compliance states (under budget, near limit, over budget).

### Phase 4: Category Budget Screen Multi-Month UI (User Story 1)
- Add month selector header (`< Tháng M/YYYY >` + Month picker bottom sheet) to `CategoryBudgetScreen`.
- Bind total budget tab and category budget tab to the active selected month.
- Allow setting/editing total budget and category budget for any historical or future month.
- Provide "Sao chép từ tháng trước" (Copy from previous month) when entering an unconfigured month.

### Phase 5: Statistics & Dashboard Synchronization (User Story 3)
- Connect `StatisticsScreen` category expense breakdown to the selected month's `category_monthly_budgets`.
- Update `budget_sheet.dart` to observe `monthlyBudgetProvider` for the active month.

### Phase 6: Testing & Quality Validation
- Create unit tests in `test/unit/monthly_budget_test.dart`.
- Update `test/unit/mock_data_generator_test.dart` to assert multi-month budget generation.
- Run `flutter analyze lib/` and execute quickstart validation scenarios.
