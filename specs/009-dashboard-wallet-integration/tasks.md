# Tasks: Dashboard & Wallet Integration (Tích hợp Ví tiền & Tái cấu trúc Dashboard)

**Branch**: `009-dashboard-wallet-integration` | **Spec**: [specs/009-dashboard-wallet-integration/spec.md](spec.md) | **Plan**: [specs/009-dashboard-wallet-integration/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Localization keys and shared configuration

- [x] T001 [P] Add localization strings and getters for Net Worth, Monthly Cash Flow, Surplus, Deficit, and Privacy masking in `lib/utils/localization.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: State management for privacy masking and aggregate net worth

- [x] T002 [P] Add `isBalanceHiddenProvider` state provider in `lib/providers/wallet_provider.dart`
- [x] T003 [P] Ensure `totalNetWorthProvider` is reactive and properly exported in `lib/providers/wallet_provider.dart`

**Checkpoint**: Foundation ready - UI components can now be built and tested independently

---

## Phase 3: User Story 1 - Total Net Worth & Mini-Wallet Carousel on Dashboard (Priority: P1) 🎯 MVP

**Goal**: Users see their real-time Total Net Worth and individual wallet balances in a mini carousel at the top of the Dashboard, with privacy toggle and quick transfer action.

**Independent Test**: Open Dashboard, verify Total Net Worth reflects the sum of active wallets, toggle privacy masking (`••••••`), scroll the mini-wallet carousel, and tap any wallet to navigate to its statement.

### Implementation for User Story 1
- [x] T004 [P] [US1] Build `DashboardNetWorthCard` widget in `lib/widgets/dashboard/dashboard_net_worth_card.dart`
- [x] T005 [P] [US1] Build `MiniWalletCarousel` widget in `lib/widgets/dashboard/mini_wallet_carousel.dart`
- [x] T006 [US1] Integrate `DashboardNetWorthCard` and `MiniWalletCarousel` at the top of `lib/screens/dashboard_screen.dart`

**Checkpoint**: User Story 1 (Dashboard Net Worth & Mini Wallets) is fully functional

---

## Phase 4: User Story 2 - Monthly Cash Flow Disambiguation & Dashboard Restructure (Priority: P1)

**Goal**: Restructure Dashboard Tier 2 to replace the legacy "Số dư" (Balance) card with a clear "Dòng tiền tháng" / "Thặng dư tháng" card (`Income - Expense`) that updates dynamically when changing months without affecting Top Net Worth.

**Independent Test**: Change the month dropdown in Dashboard; verify the top Net Worth card remains constant while the Monthly Cash Flow card recalculates strictly for the selected month.

### Implementation for User Story 2
- [x] T007 [P] [US2] Build `MonthlyCashflowCard` widget with surplus/deficit badges in `lib/widgets/dashboard/monthly_cashflow_card.dart`
- [x] T008 [US2] Update `lib/screens/dashboard_screen.dart` to use `MonthlyCashflowCard` and cleanly separate Tier 1 and Tier 2

**Checkpoint**: User Story 2 is fully functional with clear separation between Net Worth and Monthly Cash Flow

---

## Phase 5: User Story 3 - Full Vietnamese Localization & UX Consistency (Priority: P2)

**Goal**: Provide 100% complete, natural Vietnamese financial terminology across all wallet forms, cards, transfer sheets, and statement views.

**Independent Test**: Switch language to Vietnamese; verify every account type, field label, and button across wallet dialogs is translated naturally with zero English strings.

### Implementation for User Story 3
- [x] T009 [P] [US3] Review and update all Vietnamese wallet strings and account type helpers in `lib/utils/localization.dart` and `lib/widgets/wallet_card.dart`
- [x] T010 [P] [US3] Verify and update localized text in `lib/widgets/wallet_form_modal.dart` and `lib/widgets/wallet_transfer_modal.dart`

**Checkpoint**: All 3 user stories are complete and localized

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validation, testing, and build verification

- [x] T011 Run all unit tests with `flutter test --concurrency=1 test/unit/`
- [x] T012 Run static analysis with `flutter analyze lib/` and verify debug build with `flutter build apk --debug`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: Can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all User Stories
- **User Story 1 (Phase 3)**: Depends on Phase 2
- **User Story 2 (Phase 4)**: Depends on Phase 2 (can run in parallel with or after US1)
- **User Story 3 (Phase 5)**: Depends on Phase 1/2
- **Polish (Phase 6)**: Depends on all implementation phases

### Parallel Opportunities
- `T001`, `T002`, `T003` can run in parallel
- `T004`, `T005`, `T007`, `T009`, `T010` can be built concurrently as separate widget files
