import '../agent_tool.dart';
import '../../../models/recurring_config.dart';
import '../../../providers/recurring_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to schedule a recurring financial transaction (e.g. rent, bills, subscriptions).
class CreateRecurringTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'recurring_create';

  @override
  String get description => 'Tạo lịch giao dịch định kỳ lặp lại (tiền trọ, hóa đơn, lương)';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount', 'note'],
    'properties': {
      'amount': {'type': 'number'},
      'note': {'type': 'string'},
      'type': {'type': 'string', 'enum': ['expense', 'income']},
      'frequency': {'type': 'string', 'enum': ['daily', 'weekly', 'monthly', 'yearly']},
      'dayOfMonth': {'type': ['integer', 'null']},
      'categoryId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return {'isSuccess': false, 'error': 'Số tiền định kỳ không hợp lệ'};

    final note = input['note'] as String? ?? 'Giao dịch định kỳ';
    final type = input['type'] as String? ?? 'expense';
    final frequency = input['frequency'] as String? ?? 'monthly';
    final int? dayOfMonth = (input['dayOfMonth'] as num?)?.toInt();

    var categories = context.ref.read(categoryProvider).value ?? [];
    if (categories.isEmpty) {
      categories = await context.ref.read(categoryRepositoryProvider).getAll();
    }

    var wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }

    String? categoryId = input['categoryId'] as String?;
    if (categoryId == null || !categories.any((c) => c.id == categoryId)) {
      categoryId = categories.where((c) => c.type == type).firstOrNull?.id;
    }

    String? walletId = input['walletId'] as String?;
    if (walletId == null || !wallets.any((w) => w.id == walletId)) {
      walletId = wallets.where((w) => w.isDefault).firstOrNull?.id ??
          (wallets.isNotEmpty ? wallets.first.id : null);
    }

    final now = DateTime.now();
    DateTime nextRun = now;
    if (dayOfMonth != null && dayOfMonth > 0 && dayOfMonth <= 31) {
      if (now.day > dayOfMonth) {
        nextRun = DateTime(now.year, now.month + 1, dayOfMonth);
      } else {
        nextRun = DateTime(now.year, now.month, dayOfMonth);
      }
    }

    await context.ref.read(recurringProvider.notifier).createRecurringConfig(
      categoryId: categoryId,
      walletId: walletId,
      name: note,
      amount: amount,
      type: type,
      frequency: frequency,
      interval: 1,
      dayOfMonth: dayOfMonth ?? now.day,
      nextRun: nextRun,
    );

    return {
      'isSuccess': true,
      'name': note,
      'amount': amount,
      'type': type,
      'frequency': frequency,
      'dayOfMonth': dayOfMonth ?? now.day,
      'nextRun': nextRun.toIso8601String(),
    };
  }
}

/// Mutation tool to update an existing recurring transaction configuration.
class UpdateRecurringTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'recurring_update';

  @override
  String get description => 'Chỉnh sửa số tiền, ngày chạy, danh mục hoặc trạng thái của giao dịch định kỳ';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'recurringId': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
      'amount': {'type': ['number', 'null']},
      'dayOfMonth': {'type': ['integer', 'null']},
      'categoryId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'isActive': {'type': ['boolean', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    var configs = context.ref.read(recurringProvider).value ?? [];
    if (configs.isEmpty) {
      configs = await context.ref.read(recurringRepositoryProvider).getAll();
    }
    final recurringId = input['recurringId'] as String?;
    final note = input['note'] as String?;
    final amount = (input['amount'] as num?)?.toDouble();
    final dayOfMonth = (input['dayOfMonth'] as num?)?.toInt();
    final categoryId = input['categoryId'] as String?;
    final walletId = input['walletId'] as String?;
    final isActive = input['isActive'] as bool?;

    RecurringConfig? target;
    if (recurringId != null && recurringId.isNotEmpty) {
      target = configs.where((r) => r.id == recurringId).firstOrNull;
    }
    if (target == null && note != null && note.isNotEmpty) {
      target = configs.where((r) => r.name.toLowerCase().contains(note.toLowerCase())).firstOrNull;
    }

    if (target == null) return {'isSuccess': false, 'error': 'Không tìm thấy cấu hình định kỳ'};

    DateTime? nextRun;
    if (dayOfMonth != null && dayOfMonth > 0 && dayOfMonth <= 31) {
      final now = DateTime.now();
      if (now.day > dayOfMonth) {
        nextRun = DateTime(now.year, now.month + 1, dayOfMonth);
      } else {
        nextRun = DateTime(now.year, now.month, dayOfMonth);
      }
    }

    await context.ref.read(recurringProvider.notifier).updateRecurringConfig(
      target.id,
      name: note,
      amount: amount,
      dayOfMonth: dayOfMonth,
      categoryId: categoryId,
      walletId: walletId,
      isActive: isActive,
      nextRun: nextRun,
    );

    return {
      'isSuccess': true,
      'recurringId': target.id,
      'name': note ?? target.name,
      'amount': amount ?? target.amount,
      'isActive': isActive ?? target.isActive,
    };
  }
}

/// Mutation tool to delete an existing recurring configuration.
class DeleteRecurringTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'recurring_delete';

  @override
  String get description => 'Xóa hoặc hủy bỏ lịch giao dịch định kỳ';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'recurringId': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    var configs = context.ref.read(recurringProvider).value ?? [];
    if (configs.isEmpty) {
      configs = await context.ref.read(recurringRepositoryProvider).getAll();
    }
    final recurringId = input['recurringId'] as String?;
    final note = input['note'] as String?;

    RecurringConfig? target;
    if (recurringId != null && recurringId.isNotEmpty) {
      target = configs.where((r) => r.id == recurringId).firstOrNull;
    }
    if (target == null && note != null && note.isNotEmpty) {
      target = configs.where((r) => r.name.toLowerCase().contains(note.toLowerCase())).firstOrNull;
    }

    if (target == null) return false;

    await context.ref.read(recurringProvider.notifier).deleteRecurringConfig(target.id);
    return true;
  }
}
