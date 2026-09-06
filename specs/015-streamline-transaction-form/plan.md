# Implementation Plan: Streamline Transaction Form

**Branch**: `015-streamline-transaction-form` | **Date**: 2026-09-05 | **Spec**: [specs/015-streamline-transaction-form/spec.md](spec.md)

**Input**: Feature specification from `specs/015-streamline-transaction-form/spec.md`

## Summary

Modernize and streamline the transaction entry and editing experience in `TransactionFormScreen`. The redesign replaces legacy nested `DropdownButtonFormField` controls with a fast, high-ergonomics interface: a one-tap Expense/Income segmented toggle, prominent amount display with live thousand formatting, an intuitive visual `CategoryGridPicker` (4-column icon grid), a compact `WalletChipSelector`, quick date chips, and continuous receipt entry ("Save & Add Another"). Crucially, the beloved custom calculator keypad (`CustomNumPad`) with arithmetic operators and instant `000` multiplier is 100% preserved and directly integrated into the flow.

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x)

**Primary Dependencies**: `flutter_riverpod` (state management), `intl` (date and currency formatting), `sqflite` (local SQLite persistence)

**Storage**: SQLite via `DatabaseHelper` and `TransactionRepository` / `WalletRepository`

**Testing**: `flutter test` (Widget tests using `WidgetTester` and unit tests)

**Target Platform**: Mobile (Android & iOS)

**Project Type**: Mobile Application (Flutter)

**Performance Goals**: 60fps smooth scrolling, zero input lag on keypad press (<16ms frame time), sub-100ms screen load time

**Constraints**: Local-first offline-first execution, 100% preservation of `CustomNumPad` calculation features, no layout overflow (`RenderFlex` overflow) across all device screen sizes

**Scale/Scope**: Refactoring `TransactionFormScreen`, introducing modular sub-widgets (`CategoryGridPicker`, `WalletChipSelector`, `DateQuickBar`), and adding full widget test coverage

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Single-Responsibility & Modularity**: PASS. Extracted `CategoryGridPicker`, `WalletChipSelector`, and `DateQuickBar` into reusable, self-contained widgets under `lib/widgets/transaction/` rather than a monolithic screen.
- **II. English-Only Codebase**: PASS. All variables, comments, widget names, and methods are written in 100% English.
- **III. Zero Emojis**: PASS. No emojis used in code, logs, or commit messages.
- **IV. Test-First & Auto-Run**: PASS. Comprehensive widget and unit tests written and automated.
- **V. Pragmatism & No Over-Engineering**: PASS. Refactoring existing screen and widgets cleanly using Riverpod without adding unnecessary complex state machines.

## Project Structure

### Documentation (this feature)

```text
specs/015-streamline-transaction-form/
├── spec.md              # Feature specification
├── plan.md              # This implementation plan
├── research.md          # Ergonomics, keypad preservation & layout research
├── data-model.md        # State transitions & validation model
├── quickstart.md        # Runnable verification guide
├── contracts/           # UI & widget component contracts
│   └── transaction-form-contract.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Implementation tasks (/speckit-tasks output)
```

### Source Code (repository root)

```text
lib/
├── screens/
│   └── transaction_form_screen.dart          # Refactored streamlined screen
├── widgets/
│   ├── custom_num_pad.dart                   # Preserved calculator keypad
│   └── transaction/
│       ├── category_grid_picker.dart         # New visual 4-column category grid
│       ├── wallet_chip_selector.dart         # New compact wallet selector
│       └── date_quick_bar.dart               # New quick date shortcut bar
test/
├── widget_transaction_form_test.dart         # New widget tests for streamlined form
├── widget_transaction_detail_test.dart       # Regression tests
└── unit/
    └── transaction_bulk_actions_test.dart    # Repository unit tests
```

**Structure Decision**: Decompose the bulky `TransactionFormScreen` into dedicated modular widgets in `lib/widgets/transaction/` to allow independent unit/widget testing and guarantee maintainability.

## Complexity Tracking

> **No Constitution violations detected. All changes follow KISS and DRY principles.**
