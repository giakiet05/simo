# Implementation Plan: Dashboard & Wallet Integration (Tích hợp Ví tiền & Tái cấu trúc Dashboard)

**Branch**: `009-dashboard-wallet-integration` | **Date**: 2026-08-26 | **Spec**: [specs/009-dashboard-wallet-integration/spec.md](spec.md)

**Input**: Feature specification from `/specs/009-dashboard-wallet-integration/spec.md`

## Summary

Integrate the Multi-Wallet system directly into the SIMO Dashboard via a clean Two-Tier architecture:
1. **Tier 1 (Top Hero & Mini-Wallet Carousel)**: Displays real-time Total Net Worth (Tổng tài sản) aggregating all active wallets, a privacy masking eye toggle (`••••••`), quick action buttons for `[Chuyển tiền]` (Transfer) and `[Ví tiền]` (Wallets management), and a horizontal mini-wallet carousel for 1-tap statement drill-down.
2. **Tier 2 (Selected Month Flow & Budgets)**: Re-labels the legacy "Số dư" (Balance) card to "Dòng tiền tháng" / "Thặng dư" (`Thu nhập - Chi tiêu`) to clearly separate lifetime wealth from monthly savings.
3. **Full Localization**: Completes 100% natural Vietnamese financial localization across all wallet touchpoints.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `intl`, `sqflite`, `uuid`, `shared_preferences`
**Storage**: SQLite database (Schema v14) with `wallets` and `wallet_transfers` tables
**Testing**: Flutter unit and widget testing (`flutter test --concurrency=1 test/unit/`)
**Target Platform**: Android & iOS (Offline-first mobile application)
**Project Type**: Mobile Application
**Performance Goals**: Instant Dashboard loading (< 100ms), 60 FPS smooth horizontal carousel scrolling
**Constraints**: Zero regression on existing transaction/budget features, zero untranslated English strings in Vietnamese mode
**Scale/Scope**: ~4 new/updated widgets, Dashboard screen reorganization, localization dictionary updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Design System Alignment**: Follows guidelines in `docs/design_system/` (20dp card corners, `.withValues(alpha: ...)`, comma currency formatting, elevation 0). **PASS**
- **Offline-First & Data Integrity**: Uses local SQLite v14 tables without server dependency. **PASS**
- **Non-destructive Migration**: Reorganizes UI without altering existing user transactions or database schema. **PASS**
- **Localization Consistency**: Full dictionary coverage for `en`, `vi`, `zh`. **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/009-dashboard-wallet-integration/
├── plan.md              # This file
├── research.md          # Architectural decisions & research
├── data-model.md        # Entities & state definitions
├── quickstart.md        # Verification & test guide
├── contracts/
│   └── dashboard-ui-contract.md # UI & Widget contracts
└── tasks.md             # Implementation tasks (generated via /speckit-tasks)
```

### Source Code (repository root)

```text
lib/
├── models/
│   ├── wallet.dart
│   └── wallet_transfer.dart
├── providers/
│   ├── wallet_provider.dart        # totalNetWorthProvider, isBalanceHiddenProvider
│   └── transaction_provider.dart
├── screens/
│   ├── dashboard_screen.dart       # Restructured 2-tier Dashboard
│   ├── wallets_screen.dart         # Wallets overview & CRUD
│   └── wallet_detail_screen.dart   # Individual account statement
├── widgets/
│   └── dashboard/
│       ├── dashboard_net_worth_card.dart  # Top Net Worth Hero card
│       ├── mini_wallet_carousel.dart      # Horizontal mini-wallet list
│       ├── monthly_cashflow_card.dart     # Restructured Month flow card
│       └── quick_access_hub.dart
└── utils/
    ├── localization.dart           # 100% Vietnamese wallet strings
    └── currency_input_formatter.dart
```

## Implementation Phases

### Phase 1: Localization & Provider Extensions
- Add remaining Vietnamese translations and getters for Net Worth, Monthly Cash Flow, and Privacy toggle in `lib/utils/localization.dart`.
- Add `isBalanceHiddenProvider` in `lib/providers/wallet_provider.dart`.

### Phase 2: Core Dashboard Widgets
- Build `DashboardNetWorthCard` in `lib/widgets/dashboard/dashboard_net_worth_card.dart`.
- Build `MiniWalletCarousel` in `lib/widgets/dashboard/mini_wallet_carousel.dart`.
- Build `MonthlyCashflowCard` in `lib/widgets/dashboard/monthly_cashflow_card.dart`.

### Phase 3: Dashboard Integration & Restructure
- Update `lib/screens/dashboard_screen.dart` to integrate Tier 1 (Net Worth + Mini Wallets) on top, and Tier 2 (Month Filter + Cashflow + Budgets) below.
- Wire `[Chuyển tiền]` to `WalletTransferModal.show(context)` and `[Ví tiền]` to `WalletsScreen`.

### Phase 4: Polish & Verification
- Verify privacy toggle across all cards.
- Run `flutter test --concurrency=1 test/unit/` and `flutter analyze lib/`.
