import '../agent_tool.dart';
import '../../../providers/recurring_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to schedule a recurring financial transaction (e.g. rent, bills, subscriptions).
class CreateRecurringTool extends SimoAgentTool<Map<String, dynamic>, bool> {
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
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final note = input['note'] as String? ?? 'Giao dịch định kỳ';
    final type = input['type'] as String? ?? 'expense';
    final frequency = input['frequency'] as String? ?? 'monthly';
    final int? dayOfMonth = (input['dayOfMonth'] as num?)?.toInt();

    final categories = context.ref.read(categoryProvider).value ?? [];
    final wallets = context.ref.read(walletProvider).value ?? [];

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

    return true;
  }
}
