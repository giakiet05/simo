# Tasks: Features Hub Screen on Bottom Navigation Bar (Màn hình Chức năng)

**Branch**: `013-features-hub-tab` | **Spec**: [specs/013-features-hub-tab/spec.md](spec.md) | **Plan**: [specs/013-features-hub-tab/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Localization and foundational keys setup

- [X] T001 [P] Add localization strings and getters for Features Hub (`featuresHub`, `sectionCashflowAndAssets`, `sectionFinancialPlanning`, `sectionDebtsAndAnalytics`, `sectionDataAndUtilities`) in `lib/utils/localization.dart`

---

## Phase 2: User Story 1 - Replace Bottom Bar Tab with "Chức năng" Hub (Priority: P1) 🎯 MVP

**Goal**: Seamlessly mount `FeaturesScreen` on the bottom navigation bar replacing the single-purpose "Sổ nợ" tab.

**Independent Test**: Tap the 4th tab on bottom navigation bar; verify it switches to `FeaturesScreen` with `Icons.grid_view_rounded` and back gesture returns to Dashboard.

### Implementation for User Story 1
- [X] T002 [P] [US1] Create `FeaturesScreen` base scaffold in `lib/screens/features_screen.dart`
- [X] T003 [US1] Update `HomeScreen` in `lib/screens/home_screen.dart` to mount `FeaturesScreen` as 4th tab and update bottom bar item icon & label

**Checkpoint**: "Chức năng" tab is accessible from bottom navigation bar

---

## Phase 3: User Story 2 & 3 - Actionable Tool Cards with Live Previews & Categorized Workspace (Priority: P1 & P2)

**Goal**: Deliver rich, live-preview cards for Wallets, Recurring, Budgets, Saving Goals, Loans, Statistics, and Data Management tools.

**Independent Test**: Navigate to "Chức năng" tab with mock data; verify each card displays live metrics (wallet balances, budget %, debt totals, goal progress) and action buttons route correctly.

### Implementation for User Story 2 & 3
- [X] T004 [US2] Implement Dòng tiền & Tài sản section cards (Wallets with balance & actions; Recurring with next due date) in `lib/screens/features_screen.dart`
- [X] T005 [US2] Implement Kế hoạch Tài chính section cards (Budgets with % used badge; Saving Goals with mini progress bar) in `lib/screens/features_screen.dart`
- [X] T006 [US2] Implement Đối soát & Thống kê section cards (Loans with borrowed/lent summary; Statistics with analytics link) in `lib/screens/features_screen.dart`
- [X] T007 [US3] Implement Dữ liệu & Tiện ích section cards (Categories, Data Export, Backup & Restore) in `lib/screens/features_screen.dart`

**Checkpoint**: All 4 workspace sections are fully populated with live reactive state and navigation targets

---

## Phase 4: Polish & Verification

**Purpose**: Build verification and quality gate

- [X] T008 Run all unit tests with `flutter test --concurrency=1 test/unit/`
- [X] T009 Verify debug build with `flutter build apk --debug`
