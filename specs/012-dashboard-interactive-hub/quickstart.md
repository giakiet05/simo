# Quickstart & Validation Guide: Interactive Dashboard Financial Hub

**Feature**: `012-dashboard-interactive-hub`
**Date**: 2026-09-03

## 1. Validation Scenarios

### Scenario 1: Symmetrical 2x2 Financial Metrics Grid
1. Open Dashboard.
2. Verify beneath the Net Cashflow card there is a 2x2 grid with Income, Expense, Lent, and Borrowed.
3. Verify all numbers use `,` thousands separators and auto-scale cleanly.

### Scenario 2: Tap-to-Navigate Interaction
1. Tap Net Cashflow card -> Verify `StatisticsScreen` opens.
2. Tap Income tile -> Verify `TransactionScreen` opens.
3. Tap Expense tile -> Verify `TransactionScreen` opens.
4. Tap Lent / Borrowed tile -> Verify `LoanScreen` opens.
5. Tap Monthly Budget card -> Verify `CategoryBudgetScreen` opens.
6. Tap Saving Goals carousel card -> Verify `SavingGoalsScreen` opens.
