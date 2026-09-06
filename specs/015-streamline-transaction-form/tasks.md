# Tasks: Streamline Transaction Form

**Feature**: `015-streamline-transaction-form`
**Specification**: [specs/015-streamline-transaction-form/spec.md](spec.md)
**Implementation Plan**: [specs/015-streamline-transaction-form/plan.md](plan.md)

---

## Phase 1: Setup (Shared UI Sub-Widgets)

**Purpose**: Create modular sub-widgets for category grid, wallet selector, and quick date bar.

- [x] T001 [P] Create CategoryGridPicker widget in lib/widgets/transaction/category_grid_picker.dart
- [x] T002 [P] Create WalletChipSelector widget in lib/widgets/transaction/wallet_chip_selector.dart
- [x] T003 [P] Create DateQuickChipsBar widget in lib/widgets/transaction/date_quick_bar.dart

---

## Phase 2: Foundational (Keypad & Calculation Engine Polish)

**Purpose**: Polish the custom calculator keypad for seamless embedding without layout overflows.

- [x] T004 Enhance CustomNumPad in lib/widgets/custom_num_pad.dart to support embeddable sizing, onDone callback, and responsive key height

**Checkpoint**: Shared components and keypad ready for integration into the transaction form screen.

---

## Phase 3: User Story 1 - Fast and Intuitive Single Transaction Creation (Priority: P1) 🎯 MVP

**Goal**: Enable users to log a single expense or income in seconds with a 1-tap type toggle, large amount display, direct custom keypad, and visual category icon grid.

**Independent Test**: Open the Add Transaction form, toggle Expense/Income, type a formula on CustomNumPad (e.g. 50k + 25k), pick a category from the 4-column icon grid, choose a wallet, tap Save, and verify transaction is persisted.

### Tests for User Story 1
- [x] T005 [P] [US1] Create widget test scaffold in test/widget_transaction_form_test.dart verifying creation layout, type toggle, and category grid rendering

### Implementation for User Story 1
- [x] T006 [US1] Implement top Type Selector (Expense / Income) and large live Amount Display with thousand separator formatting in lib/screens/transaction_form_screen.dart
- [x] T007 [US1] Integrate CategoryGridPicker and dynamically filter categories based on selected transaction type in lib/screens/transaction_form_screen.dart
- [x] T008 [US1] Integrate WalletChipSelector and DateQuickChipsBar for fast metadata picking in lib/screens/transaction_form_screen.dart
- [x] T009 [US1] Connect embedded CustomNumPad with live formula evaluation and single Save action to transactionProvider in lib/screens/transaction_form_screen.dart

**Checkpoint**: User Story 1 fully functional and testable independently as the core MVP.

---

## Phase 4: User Story 2 - Clear and Context-Preserving Edit Mode (Priority: P2)

**Goal**: Provide a clean editing experience with pre-filled context, original date preservation, and rollback capability.

**Independent Test**: Open an existing transaction in Edit mode, verify all fields pre-populate, change the category or amount, test the Original Date chip, save, and verify updates in DB.

### Tests for User Story 2
- [x] T010 [P] [US2] Add widget tests for Edit Mode in test/widget_transaction_form_test.dart verifying pre-filled data and original date rollback

### Implementation for User Story 2
- [x] T011 [US2] Wire pre-population of amount, formula, category, wallet, note, and transaction date in Edit Mode in lib/screens/transaction_form_screen.dart
- [x] T012 [US2] Implement Original Date rollback chip in DateQuickChipsBar and handle update logic via transactionProvider in lib/screens/transaction_form_screen.dart

**Checkpoint**: Both Creation (US1) and Editing (US2) work seamlessly and independently.

---

## Phase 5: User Story 3 - Continuous & Multi-Item Entry Flow (Priority: P3)

**Goal**: Empower users to rapidly log consecutive receipts without leaving the form.

**Independent Test**: Enter an expense, tap "Save & Add Another", verify the first transaction is saved while amount/note resets and wallet/date are kept, then log a second entry.

### Tests for User Story 3
- [x] T013 [P] [US3] Add widget tests for 'Save & Add Another' flow in test/widget_transaction_form_test.dart

### Implementation for User Story 3
- [x] T014 [US3] Implement 'Save & Add Another' action retaining active wallet and date while resetting amount and note in lib/screens/transaction_form_screen.dart

**Checkpoint**: All three user stories functional and verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates, static analysis, regression verification, and quickstart validation.

- [x] T015 [P] Run static analysis and fix any lint warnings across modified files using flutter analyze
- [x] T016 Run full transaction test suite verifying no regressions across test/widget_transaction_form_test.dart, test/widget_transaction_detail_test.dart, and test/unit/transaction_bulk_actions_test.dart
- [x] T017 Validate end-to-end user experience against scenarios defined in specs/015-streamline-transaction-form/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: No dependencies, can start immediately.
- **Foundational (Phase 2)**: Depends on Phase 1, blocks User Stories.
- **User Story 1 (Phase 3 - MVP)**: Depends on Phase 1 & 2.
- **User Story 2 (Phase 4)**: Depends on Phase 3.
- **User Story 3 (Phase 5)**: Depends on Phase 3.
- **Polish (Phase 6)**: Runs after all user stories are implemented.

### Parallel Opportunities
- T001, T002, T003 can be built concurrently.
- Test tasks marked with [P] (T005, T010, T013, T015) can run concurrently with independent files.
