import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/monthly_budget.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../repositories/monthly_budget_repository.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

final monthlyBudgetRepositoryProvider = Provider<MonthlyBudgetRepository>((ref) {
  return MonthlyBudgetRepository();
});

class MonthYearKey {
  final int year;
  final int month;

  const MonthYearKey(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYearKey &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

class MonthlyBudgetNotifier extends StateNotifier<AsyncValue<MonthlyBudgetSummary>> {
  final MonthlyBudgetRepository _repository;
  final int year;
  final int month;
  final Ref _ref;

  MonthlyBudgetNotifier(this._repository, this.year, this.month, this._ref)
      : super(const AsyncValue.loading()) {
    _ref.listen(transactionProvider, (previous, next) => loadBudget());
    _ref.listen(categoryProvider, (previous, next) => loadBudget());
    loadBudget();
  }

  Future<void> loadBudget() async {
    try {
      state = const AsyncValue.loading();

      final totalBudgetObj = await _repository.getMonthlyBudget(year, month);
      final categoryBudgetsMap = await _repository.getCategoryMonthlyBudgets(year, month);

      final txsState = _ref.read(transactionProvider);
      final catsState = _ref.read(categoryProvider);

      final List<Transaction> allTxs = txsState.value ?? [];
      final List<Category> allCats = catsState.value ?? [];

      // Filter transactions for this month and expense type
      final monthExpenseTxs = allTxs.where((tx) =>
          tx.type == 'expense' &&
          tx.transactionDate.year == year &&
          tx.transactionDate.month == month).toList();

      final double totalSpent = monthExpenseTxs.fold(0.0, (sum, tx) => sum + tx.amount);
      final double totalBudget = totalBudgetObj?.amount ?? 0.0;

      final categoryStatuses = <String, CategoryBudgetStatus>{};

      for (final cat in allCats.where((c) => c.type == 'expense')) {
        final catTxs = monthExpenseTxs.where((tx) => tx.categoryId == cat.id);
        final spent = catTxs.fold(0.0, (sum, tx) => sum + tx.amount);

        // Check if there is an explicit monthly budget for this category, otherwise fallback to category default
        final double budgetLimit = categoryBudgetsMap[cat.id]?.amount ?? (cat.budgetLimit ?? 0.0);
        final double remaining = budgetLimit - spent;
        final double percentage = budgetLimit > 0 ? (spent / budgetLimit) : 0.0;

        categoryStatuses[cat.id] = CategoryBudgetStatus(
          categoryId: cat.id,
          budgetLimit: budgetLimit,
          spent: spent,
          remaining: remaining,
          percentage: percentage,
        );
      }

      final double remainingTotal = totalBudget - totalSpent;
      final double percentageUsed = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

      state = AsyncValue.data(MonthlyBudgetSummary(
        year: year,
        month: month,
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        remaining: remainingTotal,
        percentageUsed: percentageUsed,
        categoryStatuses: categoryStatuses,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setTotalBudget(double amount) async {
    await _repository.setMonthlyBudget(year, month, amount);
    await loadBudget();
  }

  Future<void> deleteTotalBudget() async {
    await _repository.deleteMonthlyBudget(year, month);
    await loadBudget();
  }

  Future<void> setCategoryBudget(String categoryId, double amount) async {
    await _repository.setCategoryMonthlyBudget(categoryId, year, month, amount);
    await loadBudget();
  }

  Future<void> deleteCategoryBudget(String categoryId) async {
    await _repository.deleteCategoryMonthlyBudget(categoryId, year, month);
    await loadBudget();
  }

  Future<void> copyFromPreviousMonth() async {
    int prevYear = year;
    int prevMonth = month - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear -= 1;
    }

    await _repository.copyBudgetsFromMonth(
      fromYear: prevYear,
      fromMonth: prevMonth,
      toYear: year,
      toMonth: month,
    );
    await loadBudget();
  }
}

final monthlyBudgetFamily = StateNotifierProvider.family<
    MonthlyBudgetNotifier,
    AsyncValue<MonthlyBudgetSummary>,
    MonthYearKey>((ref, key) {
  final repo = ref.watch(monthlyBudgetRepositoryProvider);
  return MonthlyBudgetNotifier(repo, key.year, key.month, ref);
});
