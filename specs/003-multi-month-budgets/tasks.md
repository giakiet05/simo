# Tasks: Multi-Month Budget Management & Rich Mock Data

**Feature**: [Multi-Month Budget Management & Rich Mock Data](spec.md)  
**Plan**: [Implementation Plan](plan.md)  
**Status**: Completed  

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure verification

- [X] T001 Verify SQLite database helper and migration hooks in lib/repositories/database_helper.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models, database migration v4, repository, and Riverpod providers that MUST be completed before UI work begins

- [X] T002 [P] Create MonthlyBudget and CategoryMonthlyBudget entity models in lib/models/monthly_budget.dart
- [X] T003 Upgrade SQLite schema to version 4 with monthly_budgets and category_monthly_budgets tables in lib/repositories/database_helper.dart
- [X] T004 Implement MonthlyBudgetRepository with CRUD and copy operations in lib/repositories/monthly_budget_repository.dart
- [X] T005 Implement monthlyBudgetRepositoryProvider and monthlyBudgetProvider in lib/providers/monthly_budget_provider.dart
- [X] T006 [P] Add localization strings for month selection, budget copy, and status messages in lib/utils/localization.dart

---

## Phase 3: User Story 1 - Multi-Month Budget Navigation & Historical Tracking (Priority: P1) 🎯 MVP

**Goal**: Enable users to navigate between past, current, and future months in CategoryBudgetScreen, viewing and editing total and per-category budgets for any selected month.

**Independent Test**: Open CategoryBudgetScreen, navigate to a past month (e.g. Month 4/2026), edit a category limit, navigate to another month, and verify the edited budget persists accurately for Month 4 without modifying other months.

- [X] T007 [US1] Add month navigation header with previous/next arrows and month picker in lib/screens/category_budget_screen.dart
- [X] T008 [US1] Update total budget tab to view, set, and edit total budget for the selected month in lib/screens/category_budget_screen.dart
- [X] T009 [US1] Update category budget tab to view, set, and edit per-category budget limits for the selected month in lib/screens/category_budget_screen.dart
- [X] T010 [US1] Add "Sao chép từ tháng trước" (Copy from previous month) quick action in lib/screens/category_budget_screen.dart

---

## Phase 4: User Story 2 - Comprehensive Multi-Month Mock Data Generation (Priority: P1)

**Goal**: Populate 6 months (March 2026 to August 2026) of realistic total budgets and per-category budget limits with diverse compliance states (normal, near-limit, over-budget).

**Independent Test**: Tap "Tạo dữ liệu mẫu" in Settings, open CategoryBudgetScreen, and verify all 6 months have total and category budgets with varied progress percentages.

- [X] T011 [US2] Implement multi-month budget generation for March to August 2026 with diverse compliance profiles in lib/utils/mock_data_generator.dart
- [X] T012 [US2] Update clearAllData in lib/repositories/database_helper.dart and lib/screens/settings_screen.dart to clear budget tables

---

## Phase 5: User Story 3 - Synchronized Multi-Month Budget in Statistics & Dashboard (Priority: P2)

**Goal**: Synchronize Statistics and Dashboard budget indicators with the active/selected month's budget data.

**Independent Test**: Select a historical month in Statistics and verify the category budget progress bars match that month's budget allocation.

- [X] T013 [US3] Update category expense breakdown to use selected month's category budget in lib/screens/statistics_screen.dart
- [X] T014 [US3] Update budget overview sheet to bind to active month's monthlyBudgetProvider in lib/widgets/dashboard/budget_sheet.dart

---

## Phase 6: Polish & Verification

**Purpose**: Validation, unit testing, and code quality

- [X] T015 [P] Create unit tests for MonthlyBudgetRepository and budget calculation logic in test/unit/monthly_budget_test.dart
- [X] T016 [P] Update unit tests in test/unit/mock_data_generator_test.dart to assert multi-month budget generation
- [X] T017 Run flutter analyze lib/ to ensure 0 lint errors
- [X] T018 Run quickstart validation scenarios in specs/003-multi-month-budgets/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Story 1 (Phase 3)**: MVP - Multi-month navigation & budget editor UI
- **User Story 2 (Phase 4)**: Mock data generator updates (depends on Phase 2)
- **User Story 3 (Phase 5)**: Statistics & Dashboard integration (depends on Phase 2 & 3)
- **Polish (Phase 6)**: Validation & automated tests

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete Phase 1 & Phase 2 (Data models, DB migration v4, Repository, Riverpod Provider)
2. Implement Phase 3 (Multi-month navigation & budget editor UI in `category_budget_screen.dart`)
3. Validate User Story 1 independently

### Incremental Delivery (User Story 2 & 3)
1. Implement Phase 4 (Multi-month mock data generation)
2. Implement Phase 5 (Statistics & Dashboard synchronization)
3. Execute Phase 6 (Unit tests and analyzer validation)
