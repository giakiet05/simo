# Contracts: Multi-Month Budget Management & Repository API

**Feature**: [Multi-Month Budget Management & Rich Mock Data](../spec.md)  
**Date**: 2026-08-21  

---

## 1. `MonthlyBudgetRepository` Interface Contract

```dart
abstract class MonthlyBudgetRepository {
  /// Get the total budget configured for a specific [year] and [month].
  /// Returns null if no budget has been set for this period.
  Future<MonthlyBudget?> getMonthlyBudget(int year, int month);

  /// Set or update the total monthly budget for [year] and [month].
  Future<void> setMonthlyBudget(int year, int month, double amount);

  /// Delete the total monthly budget for [year] and [month].
  Future<void> deleteMonthlyBudget(int year, int month);

  /// Get all category budgets for a specific [year] and [month].
  /// Returns a map of categoryId -> CategoryMonthlyBudget.
  Future<Map<String, CategoryMonthlyBudget>> getCategoryMonthlyBudgets(int year, int month);

  /// Set or update the budget limit for a specific category in [year] and [month].
  Future<void> setCategoryMonthlyBudget(String categoryId, int year, int month, double amount);

  /// Remove the budget limit for a category in a specific month.
  Future<void> deleteCategoryMonthlyBudget(String categoryId, int year, int month);

  /// Copy all budgets (total & categories) from [fromYear]/[fromMonth] to [toYear]/[toMonth].
  Future<void> copyBudgetsFromMonth({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  });

  /// Clear all budget records (used by Reset Data).
  Future<void> clearAllBudgets();
}
```

---

## 2. Riverpod Provider Contract

```dart
/// Provider for the monthly budget repository instance
final monthlyBudgetRepositoryProvider = Provider<MonthlyBudgetRepository>((ref) {
  return SqliteMonthlyBudgetRepository();
});

/// Family StateNotifier for managing and observing monthly budget summaries per (year, month)
final monthlyBudgetProvider = StateNotifierProvider.family<
    MonthlyBudgetNotifier,
    AsyncValue<MonthlyBudgetSummary>,
    ({int year, int month})>((ref, arg) {
  final repo = ref.watch(monthlyBudgetRepositoryProvider);
  final txsAsync = ref.watch(transactionProvider);
  final catsAsync = ref.watch(categoryProvider);
  return MonthlyBudgetNotifier(repo, arg.year, arg.month, txsAsync, catsAsync);
});
```

---

## 3. UI Interaction Contracts

### Month Navigation Component
- **Inputs**: `int currentYear`, `int currentMonth`, `Function(int year, int month) onMonthChanged`
- **Actions**:
  - `onPreviousMonth()`: Moves backward 1 month (wraps Dec -> Jan on year boundary).
  - `onNextMonth()`: Moves forward 1 month.
  - `onSelectMonth()`: Opens Month/Year picker bottom sheet / dialog.
- **Output Event**: Emits new `(year, month)` to reload budget state.
