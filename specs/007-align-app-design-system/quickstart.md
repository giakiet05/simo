# Quickstart & Verification: App-wide UI Alignment

**Feature**: `007-align-app-design-system`

## Verification Steps

1. **Static Analysis**:
   - Run `flutter analyze lib/` and verify that zero `deprecated_member_use` warnings remain for `withOpacity`.
2. **Unit Test Suite**:
   - Run `flutter test --concurrency=1 test/unit/` to verify all 20 tests pass with zero regressions.
3. **Screen-by-Screen UI Check**:
   - Open `RecurringScreen`, `LoanScreen`, `CategoryScreen`, `CategoryBudgetScreen`, `StatisticsScreen`, `SavingGoalsScreen`, `SettingsScreen` and verify uniform AppBars and scrollable filter chips.
