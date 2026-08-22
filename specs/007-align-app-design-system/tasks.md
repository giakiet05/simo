# Tasks: Align App-wide UI to SIMO Design System

**Branch**: `007-align-app-design-system` | **Spec**: [specs/007-align-app-design-system/spec.md](spec.md) | **Plan**: [specs/007-align-app-design-system/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Theme base verification

- [x] T001 [P] Verify theme base tokens and localization references across target screens

---

## Phase 2: User Story 1 - Standardize AppBars & Action Buttons (Priority: P1) 🎯 MVP

**Goal**: Make all screen AppBars flat (`elevation: 0`) and unify the top-right `+` create action button.

**Independent Test**: Open Recurring, Loans, and Category screens to verify clean flat AppBars with uniform `IconButton(icon: Icon(Icons.add))` actions.

### Implementation for User Story 1
- [x] T002 [P] [US1] Refactor AppBar in `lib/screens/recurring_screen.dart` (flat `elevation: 0`, remove `inversePrimary`, standard `IconButton(icon: Icon(Icons.add))`)
- [x] T003 [P] [US1] Standardize AppBar in `lib/screens/loan_screen.dart` (flat `elevation: 0`, remove `inversePrimary`)
- [x] T004 [P] [US1] Standardize AppBar in `lib/screens/category_screen.dart` (flat `elevation: 0`, remove `inversePrimary`)

**Checkpoint**: All AppBars and top action buttons adhere to Design System rules

---

## Phase 3: User Story 2 - Overflow-Proof Horizontal Filter Chips (Priority: P1)

**Goal**: Prevent `RenderFlex` overflow errors across all device widths by wrapping horizontal filter chip rows in `SingleChildScrollView`.

**Independent Test**: Change language to Vietnamese/Chinese and verify chips scroll smoothly in Loans, Recurring, and Statistics screens without layout warnings.

### Implementation for User Story 2
- [x] T005 [P] [US2] Wrap filter chips in `SingleChildScrollView(scrollDirection: Axis.horizontal)` in `lib/screens/loan_screen.dart` and `lib/screens/loan_detail_screen.dart`
- [x] T006 [P] [US2] Wrap filter chips in `SingleChildScrollView(scrollDirection: Axis.horizontal)` in `lib/screens/recurring_screen.dart`
- [x] T007 [P] [US2] Wrap filter chips in `SingleChildScrollView(scrollDirection: Axis.horizontal)` in `lib/screens/statistics_screen.dart`

**Checkpoint**: All filter chips are 100% overflow-proof

---

## Phase 4: User Story 3 - Unify Cards, Modals, and Deprecation Migration (Priority: P2)

**Goal**: Standardize modal top radii to 20dp, unify card borders, and migrate all deprecated `.withOpacity` calls to `.withValues(alpha: ...)`.

**Independent Test**: Verify modal sheets in Category Budgets open with 20dp top radius, and `flutter analyze lib/` reports 0 `deprecated_member_use` warnings on opacity.

### Implementation for User Story 3
- [x] T008 [P] [US3] Standardize modal bottom sheet radii to `Radius.circular(20)` in `lib/screens/category_budget_screen.dart`
- [x] T009 [P] [US3] Migrate `.withOpacity` to `.withValues(alpha: ...)` in `lib/screens/settings_screen.dart`, `lib/screens/dashboard_screen.dart`, `lib/screens/loan_detail_screen.dart`, and `lib/screens/transaction_form_screen.dart`
- [x] T010 [P] [US3] Migrate `.withOpacity` to `.withValues(alpha: ...)` in `lib/widgets/icon_picker_dialog.dart`, `lib/widgets/loan_transaction_modal.dart`, and `lib/widgets/voice_record_sheet.dart`

**Checkpoint**: All cards, modals, and color calls are fully modern and unified

---

## Phase 5: Polish & Verification

**Purpose**: Quality gate and test verification

- [x] T011 Run `flutter analyze lib/` to verify zero errors and zero deprecation warnings on withOpacity
- [x] T012 Run `flutter test --concurrency=1 test/unit/` to verify 100% test pass rate
