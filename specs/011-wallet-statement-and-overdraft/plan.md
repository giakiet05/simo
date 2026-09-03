# Implementation Plan: Wallet Statement Filtering & Overdraft Management (Sao kê nâng cao & Quản lý ví thấu chi/âm)

**Branch**: `011-wallet-statement-and-overdraft` | **Date**: 2026-09-03 | **Spec**: [specs/011-wallet-statement-and-overdraft/spec.md](spec.md)

**Input**: Feature specification from `/specs/011-wallet-statement-and-overdraft/spec.md`

## Summary

Implement advanced statement filtering, time scoping, overdraft transfer confirmation, dynamic alert gradient for negative balance wallets, and robust fixed-box amount presentation:
1. **Localization keys**: Add translations for overdraft warning dialog and filter labels.
2. **Overdraft transfer confirmation**: Upgrade `WalletTransferModal` to prompt user confirmation on overdraft instead of blocking.
3. **Wallet detail filters**: Add type filter chips (`All`, `Income`, `Expense`, `Transfers`) and month/period selector to `WalletDetailScreen`.
4. **Negative balance alert theme**: Dynamically render Crimson Red gradient in `WalletDetailScreen` when `currentBalance < 0`.
5. **Fixed width amount box**: Ensure `WalletCard` has fixed amount box constraints with auto-scaling.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `intl`
**Target Platform**: Android & iOS
**Testing**: Flutter unit and widget tests (`flutter test --concurrency=1 test/unit/`)
**Scale/Scope**: 4 files (`localization.dart`, `wallet_transfer_modal.dart`, `wallet_detail_screen.dart`, `wallet_card.dart`)

## Constitution Check

- **Design System Alignment**: Follows SIMO 20dp card corners, 16dp item radius, `.withValues(alpha: ...)`, zero elevation. **PASS**
- **Localization Consistency**: Uses `ref.watch(localizationProvider)`. **PASS**
- **Non-destructive Data Operations**: Safe database transactions. **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/011-wallet-statement-and-overdraft/
├── plan.md              # This file
├── research.md          # Technical decisions
├── data-model.md        # Filter & activity models
├── quickstart.md        # Validation scenarios
├── contracts/
│   └── wallet-detail-contract.md # Contracts & localization
└── tasks.md             # Tasks file (via /speckit-tasks)
```

### Source Code Files Affected

```text
lib/
├── utils/
│   └── localization.dart                      # Add overdraft warning & filter strings
├── screens/
│   └── wallet_detail_screen.dart              # Type chips, Month selector, Red gradient on negative
└── widgets/
    ├── wallet_card.dart                       # Fixed width amount box with auto-scaling
    └── wallet_transfer_modal.dart             # Overdraft warning confirmation dialog
```
