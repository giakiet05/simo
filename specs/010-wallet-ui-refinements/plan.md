# Implementation Plan: Wallet UI & UX Refinements (Tinh chỉnh & Tối ưu Giao diện Ví tiền)

**Branch**: `010-wallet-ui-refinements` | **Date**: 2026-09-03 | **Spec**: [specs/010-wallet-ui-refinements/spec.md](spec.md)

**Input**: Feature specification from `/specs/010-wallet-ui-refinements/spec.md`

## Summary

Refine the Wallet UI and Dashboard integration to optimize visual feedback, declutter action buttons, and ensure robust text rendering:
1. **Dynamic Net Worth Gradient**: Emerald Green for $\ge 0$, Crimson Red for $< 0$ across Dashboard and WalletsScreen hero cards.
2. **Dashboard Hero Card Streamlining**: Remove redundant inline buttons from `DashboardNetWorthCard`.
3. **Wallets Screen Hero Card Cleanup**: Remove duplicate inline buttons from `WalletsScreen` hero card, keeping AppBar icons.
4. **Robust `WalletCard` Layout**: Ensure long wallet names and large currency amounts remain 100% visible and beautifully rendered.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `intl`
**Storage**: N/A (UI layout and style refinement)
**Testing**: Flutter unit and widget tests (`flutter test --concurrency=1 test/unit/`)
**Target Platform**: Android & iOS
**Performance Goals**: 60 FPS smooth rendering, zero layout overflows
**Scale/Scope**: 3 widget/screen files (`dashboard_net_worth_card.dart`, `wallets_screen.dart`, `wallet_card.dart`, `dashboard_screen.dart`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Design System Alignment**: Follows 20dp card corners, 16dp item radius, `.withValues(alpha: ...)`, zero elevation. **PASS**
- **Non-destructive UI Refinement**: Preserves existing wallet database records and state providers. **PASS**
- **Localization Consistency**: Uses `ref.watch(localizationProvider)`. **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/010-wallet-ui-refinements/
├── plan.md              # This file
├── research.md          # Visual & UX decisions
├── data-model.md        # UI models
├── quickstart.md        # Validation guide
├── contracts/
│   └── wallet-ui-contract.md # Component contracts
└── tasks.md             # Tasks file (via /speckit-tasks)
```

### Source Code Files Affected

```text
lib/
├── screens/
│   ├── dashboard_screen.dart                 # Remove unused callbacks passed to NetWorthCard
│   └── wallets_screen.dart                    # Clean up Hero card buttons & add dynamic gradient
└── widgets/
    ├── wallet_card.dart                      # Flexible layout for long names & balances
    └── dashboard/
        └── dashboard_net_worth_card.dart     # Dynamic gradient & remove inline buttons
```
