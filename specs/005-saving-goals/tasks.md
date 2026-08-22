# Tasks: Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)

**Branch**: `005-saving-goals` | **Spec**: [specs/005-saving-goals/spec.md](spec.md) | **Plan**: [specs/005-saving-goals/plan.md](plan.md)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Localization and base configuration

- [x] T001 [P] Add localization strings for Saving Goals (English, Vietnamese, Chinese) in `lib/utils/localization.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models, SQLite schema migration v7, and repository layer

- [x] T002 [P] Create `SavingGoal` entity model in `lib/models/saving_goal.dart`
- [x] T003 [P] Create `SavingGoalLog` entity model in `lib/models/saving_goal_log.dart`
- [x] T004 Update `DatabaseHelper` schema version (v7) and create `saving_goals` and `saving_goal_logs` tables in `lib/repositories/database_helper.dart`
- [x] T005 Implement `SavingGoalRepository` with CRUD and atomic deposit/withdraw transactions in `lib/repositories/saving_goal_repository.dart`
- [x] T006 [P] Add unit tests for `SavingGoalRepository` in `test/unit/saving_goal_repository_test.dart`

**Checkpoint**: Foundation ready - User story implementation can begin

---

## Phase 3: User Story 1 - Create & Manage Saving Goals (Priority: P1) 🎯 MVP

**Goal**: Users can create, view, edit, and delete saving goals with target amounts, optional deadlines, custom colors, and icons.

**Independent Test**: Create saving goals with name, target amount, deadline, icon, color; verify goals list and editing actions work seamlessly.

### Implementation for User Story 1
- [x] T007 [US1] Create `SavingGoalNotifier` and `savingGoalProvider` in `lib/providers/saving_goal_provider.dart`
- [x] T008 [P] [US1] Build `SavingGoalFormModal` for creating/editing goals in `lib/widgets/saving_goal_form_modal.dart`
- [x] T009 [P] [US1] Build `SavingGoalCard` widget in `lib/widgets/saving_goal_card.dart`
- [x] T010 [US1] Build `SavingGoalsScreen` with goal list and floating action button in `lib/screens/saving_goals_screen.dart`

**Checkpoint**: At this point, User Story 1 is fully functional and testable independently

---

## Phase 4: User Story 2 - Deposit & Withdraw Funds with History Logs (Priority: P1)

**Goal**: Deposit and withdraw funds from individual saving goals with transparent chronological history logs and auto-completion status.

**Independent Test**: Deposit money into a goal, verify current amount increases, withdraw funds, check deposit/withdraw log timeline.

### Implementation for User Story 2
- [x] T011 [P] [US2] Build `SavingGoalLogModal` for deposit/withdraw inputs in `lib/widgets/saving_goal_log_modal.dart`
- [x] T012 [US2] Build `SavingGoalDetailScreen` with milestone summary, action buttons (Nạp/Rút), and chronological history timeline in `lib/screens/saving_goal_detail_screen.dart`

**Checkpoint**: User Stories 1 AND 2 work independently

---

## Phase 5: User Story 3 - Visual Progress Tracking & Smart Insights (Priority: P2)

**Goal**: Display total savings overview card (% overall progress) and smart monthly savings pacing recommendations.

**Independent Test**: View overview header with total target vs saved amounts, check monthly pacing calculation on goals with deadlines.

### Implementation for User Story 3
- [x] T013 [US3] Add Smart Pacing calculation helper (monthly savings pace) in `lib/models/saving_goal.dart`
- [x] T014 [US3] Build `_buildSavingGoalsOverviewHeader` widget in `lib/screens/saving_goals_screen.dart`

**Checkpoint**: User Stories 1, 2, and 3 work independently

---

## Phase 6: User Story 4 - Data Backup & Export Integration (Priority: P3)

**Goal**: Preserve saving goals and history logs in full JSON backup snapshots and Excel export workbooks.

**Independent Test**: Export JSON backup with saving goals, clear database, restore from backup, verify 100% data recovery.

### Implementation for User Story 4
- [x] T015 [P] [US4] Update `BackupSnapshot` and `BackupService` to backup/restore `saving_goals` and `saving_goal_logs` in `lib/models/backup_snapshot.dart` and `lib/services/backup_service.dart`
- [x] T016 [P] [US4] Update `ExportService.exportToExcel` to add "Mục tiêu tiết kiệm" sheet in `lib/services/export_service.dart`

**Checkpoint**: All 4 user stories are fully functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Navigation integration, ad banner, and test validation

- [x] T017 Add navigation entry points for Saving Goals in Quick Access Hub (`lib/widgets/dashboard/quick_access_hub.dart`) and Drawer (`lib/screens/dashboard_screen.dart`)
- [x] T018 [P] Add Banner ad and layout responsiveness to `lib/screens/saving_goals_screen.dart`
- [x] T019 Run all unit tests with `flutter test --concurrency=1 test/unit/` and verify `flutter analyze`
- [x] T020 Execute end-to-end validation scenarios in `specs/005-saving-goals/quickstart.md`
