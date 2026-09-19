import '../agent_tool.dart';
import '../../../providers/monthly_budget_provider.dart';
import '../../../providers/category_provider.dart';

/// Mutation tool to set or update a category or total monthly budget.
class SetBudgetTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'budget_set';

  @override
  String get description => 'Thiết lập hạn mức chi tiêu cho danh mục hoặc tổng chi tiêu tháng';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount'],
    'properties': {
      'amount': {'type': 'number'},
      'categoryId': {'type': ['string', 'null']},
      'categoryName': {'type': ['string', 'null']},
      'month': {'type': ['string', 'null']}, // Format: YYYY-MM
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

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

    final categoryId = input['categoryId'] as String?;
    final categoryName = input['categoryName'] as String?;
    final categories = context.ref.read(categoryProvider).value ?? [];

    String? matchedCatId = categoryId;
    if (matchedCatId == null && categoryName != null && categoryName.isNotEmpty) {
      matchedCatId = categories
          .where((c) => c.name.toLowerCase().contains(categoryName.toLowerCase()))
          .firstOrNull
          ?.id;
    }

    final key = MonthYearKey(targetYear, targetMonth);
    final notifier = context.ref.read(monthlyBudgetFamily(key).notifier);

    if (matchedCatId != null && matchedCatId.isNotEmpty) {
      await notifier.setCategoryBudget(matchedCatId, amount);
    } else {
      await notifier.setTotalBudget(amount);
    }

    return true;
  }
}

/// Mutation tool to delete or clear a monthly budget limit.
class DeleteBudgetTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'budget_delete';

  @override
  String get description => 'Xóa bỏ hạn mức chi tiêu của một danh mục hoặc tổng ngân sách trong tháng';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'categoryId': {'type': ['string', 'null']},
      'categoryName': {'type': ['string', 'null']},
      'month': {'type': ['string', 'null']}, // Format: YYYY-MM
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
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

    final categoryId = input['categoryId'] as String?;
    final categoryName = input['categoryName'] as String?;
    final categories = context.ref.read(categoryProvider).value ?? [];

    String? matchedCatId = categoryId;
    if (matchedCatId == null && categoryName != null && categoryName.isNotEmpty) {
      matchedCatId = categories
          .where((c) => c.name.toLowerCase().contains(categoryName.toLowerCase()))
          .firstOrNull
          ?.id;
    }

    final key = MonthYearKey(targetYear, targetMonth);
    final notifier = context.ref.read(monthlyBudgetFamily(key).notifier);

    if (matchedCatId != null && matchedCatId.isNotEmpty) {
      await notifier.deleteCategoryBudget(matchedCatId);
    } else {
      await notifier.deleteTotalBudget();
    }

    return true;
  }
}
