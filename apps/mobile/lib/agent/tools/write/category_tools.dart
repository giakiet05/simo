import '../agent_tool.dart';
import '../../../models/category.dart';
import '../../../providers/category_provider.dart';

/// Mutation tool to create a new transaction category.
class CreateCategoryTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'category_create';

  @override
  String get description => 'Tạo danh mục thu hoặc chi mới';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['categoryName'],
    'properties': {
      'categoryName': {'type': 'string'},
      'type': {'type': 'string', 'enum': ['expense', 'income']},
      'icon': {'type': ['string', 'null']},
      'color': {'type': ['string', 'null']},
      'budgetLimit': {'type': ['number', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final name = input['categoryName'] as String? ?? input['name'] as String?;
    if (name == null || name.trim().isEmpty) return false;

    final type = input['type'] as String? ?? 'expense';
    final icon = input['icon'] as String? ?? (type == 'income' ? 'savings' : 'category');
    final color = input['color'] as String? ?? (type == 'income' ? '#4CAF50' : '#FF9800');
    final budgetLimit = (input['budgetLimit'] as num?)?.toDouble();

    await context.ref.read(categoryProvider.notifier).createCategory(
      name.trim(),
      type,
      icon: icon,
      color: color,
      budgetLimit: budgetLimit,
    );
    return true;
  }
}

/// Mutation tool to delete an existing transaction category.
class DeleteCategoryTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'category_delete';

  @override
  String get description => 'Xóa một danh mục thu hoặc chi';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'categoryId': {'type': ['string', 'null']},
      'categoryName': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final categoryId = input['categoryId'] as String?;
    final categoryName = input['categoryName'] as String?;

    final categories = context.ref.read(categoryProvider).value ?? [];
    Category? target;

    if (categoryId != null && categoryId.isNotEmpty) {
      target = categories.where((c) => c.id == categoryId).firstOrNull;
    }

    if (target == null && categoryName != null && categoryName.isNotEmpty) {
      target = categories.where((c) => c.name.toLowerCase() == categoryName.toLowerCase().trim()).firstOrNull;
    }

    if (target == null) return false;

    // Guard against deleting internal system categories
    if (target.id.startsWith('sys_')) {
      return false;
    }

    await context.ref.read(categoryProvider.notifier).deleteCategory(target.id);
    return true;
  }
}
