# Implementation Plan: Interactive Dashboard Financial Hub & Metric Navigation (Trung tâm điều phối tài chính Dashboard)

**Branch**: `012-dashboard-interactive-hub` | **Date**: 2026-09-03 | **Spec**: [specs/012-dashboard-interactive-hub/spec.md](spec.md)

**Input**: Feature specification from `/specs/012-dashboard-interactive-hub/spec.md`

## Summary

Transform the SIMO Dashboard into a cohesive, actionable financial hub:
1. **Streamline `MonthlyCashflowCard`**: Focus on Net Cashflow (Thặng dư / Thâm hụt) and Savings Rate, supporting direct tap-to-`StatisticsScreen`.
2. **Build `MonthlyMetricsGrid`**: Create a balanced 2x2 grid containing Income, Expense, Lent, and Borrowed cards with responsive scaling and dedicated navigation callbacks.
3. **Connect Actionable Navigation on Tap**: Wire tap handlers across Budget, Saving Goals, Loans, Cashflow, and Transactions.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `intl`
**Target Platform**: Android & iOS
**Testing**: Flutter unit and widget tests (`flutter test --concurrency=1 test/unit/`)
**Scale/Scope**: 3 files (`monthly_cashflow_card.dart`, `monthly_metrics_grid.dart`, `dashboard_screen.dart`)

## Constitution Check

- **Design System Alignment**: Follows SIMO 20dp card corners, 16dp item radius, `.withValues(alpha: ...)`, zero elevation. **PASS**
- **Localization Consistency**: Uses `ref.watch(localizationProvider)` / `l10n`. **PASS**
- **Clean Architecture**: Decoupled presentation components. **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/012-dashboard-interactive-hub/
├── plan.md              # This file
├── research.md          # Technical decisions
├── data-model.md        # Presentation models
├── quickstart.md        # Validation scenarios
├── contracts/
│   └── dashboard-contracts.md # Component contracts
└── tasks.md             # Tasks file (via /speckit-tasks)
```

### Source Code Files Affected

```text
lib/
├── widgets/
│   └── dashboard/
│       ├── monthly_cashflow_card.dart     # Focus on Net Cashflow & tap-to-statistics
│       └── monthly_metrics_grid.dart      # 2x2 Grid for Income, Expense, Lent, Borrowed
└── screens/
    └── dashboard_screen.dart              # Wire 2x2 grid and navigation routes
```
