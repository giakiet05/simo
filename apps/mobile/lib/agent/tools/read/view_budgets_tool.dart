import '../agent_tool.dart';
import '../../../models/ai_message.dart';
import '../../../providers/monthly_budget_provider.dart';
import '../../../providers/category_provider.dart';

/// Read tool to calculate budget progress and return [BudgetProgressViewPayload].
class ViewBudgetsTool extends SimoAgentTool<Map<String, dynamic>, BudgetProgressViewPayload?> {
  @override
  String get name => 'view_budgets';

  @override
  String get description => 'Xem tiến độ và hạn mức ngân sách chi tiêu trong tháng';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'month': {'type': ['string', 'null']},
      'categoryId': {'type': ['string', 'null']},
    },
  };

  @override
  Future<BudgetProgressViewPayload?> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final now = DateTime.now();
    int targetYear = now.year;
    int targetMonth = now.month;

    final monthStr = input['month'] as String?;
    if (monthStr != null && monthStr.contains('-')) {
      final parts = monthStr.split('-');
      if (parts.length >= 2) {
        targetYear = int.tryParse(parts[0]) ?? targetYear;
        targetMonth = int.tryParse(parts[1]) ?? targetMonth;
      }
    }

    final key = MonthYearKey(targetYear, targetMonth);
    final summaryAsync = context.ref.read(monthlyBudgetFamily(key));
    final summary = summaryAsync.value;
    final categories = context.ref.read(categoryProvider).value ?? [];

    final formattedMonth = '$targetYear-${targetMonth.toString().padLeft(2, '0')}';
    final totalLimit = summary?.totalBudget ?? 0.0;
    final totalSpent = summary?.totalSpent ?? 0.0;
    final totalPct = summary?.percentageUsed ?? (totalLimit > 0 ? totalSpent / totalLimit : 0.0);

    final catBudgetItems = <CategoryBudgetItemViewData>[];
    if (summary?.categoryStatuses != null) {
      for (final entry in summary!.categoryStatuses.entries) {
        final cat = categories.where((c) => c.id == entry.key).firstOrNull;
        catBudgetItems.add(
          CategoryBudgetItemViewData(
            categoryId: entry.key,
            categoryName: cat?.name ?? 'Danh mục',
            categoryIcon: cat?.icon ?? 'pie_chart',
            limitAmount: entry.value.budgetLimit,
            spentAmount: entry.value.spent,
            percentage: entry.value.percentage,
          ),
        );
      }
    }

    return BudgetProgressViewPayload(
      month: formattedMonth,
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      totalPercentage: totalPct,
      categories: catBudgetItems,
    );
  }
}
