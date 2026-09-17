import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to create a new income or expense transaction.
class CreateTransactionTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'transaction_create';

  @override
  String get description => 'Tạo mới giao dịch thu nhập hoặc chi tiêu';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount'],
    'properties': {
      'amount': {'type': 'number'},
      'type': {'type': 'string', 'enum': ['expense', 'income']},
      'note': {'type': 'string'},
      'categoryId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'date': {'type': 'string'},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final type = input['type'] as String? ?? 'expense';
    final note = input['note'] as String? ?? '';
    final dateStr = input['date'] as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    final categories = context.ref.read(categoryProvider).value ?? [];
    final wallets = context.ref.read(walletProvider).value ?? [];

    String categoryId = input['categoryId'] as String? ?? '';
    if (categoryId.isEmpty || !categories.any((c) => c.id == categoryId)) {
      categoryId = categories.where((c) => c.type == type).firstOrNull?.id ??
          (categories.isNotEmpty ? categories.first.id : '');
    }

    String walletId = input['walletId'] as String? ?? '';
    if (walletId.isEmpty || !wallets.any((w) => w.id == walletId)) {
      walletId = wallets.where((w) => w.isDefault).firstOrNull?.id ??
          (wallets.isNotEmpty ? wallets.first.id : '');
    }

    await context.ref.read(transactionProvider.notifier).createTransactions([
      {
        'id': const Uuid().v4(),
        'category_id': categoryId,
        'wallet_id': walletId,
        'amount': amount,
        'note': note,
        'type': type,
        'transaction_date': date.toIso8601String(),
      }
    ]);

    return true;
  }
}

/// Mutation tool to update an existing transaction.
class UpdateTransactionTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'transaction_update';

  @override
  String get description => 'Cập nhật thông tin một giao dịch hiện có';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['transactionId'],
    'properties': {
      'transactionId': {'type': 'string'},
      'amount': {'type': ['number', 'null']},
      'note': {'type': ['string', 'null']},
      'categoryId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'type': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final transactionId = input['transactionId'] as String?;
    if (transactionId == null || transactionId.isEmpty) {
      // If no explicit ID, fallback to finding the most recent transaction
      final txs = context.ref.read(transactionProvider).value ?? [];
      if (txs.isEmpty) return false;
      final target = txs.first;
      final amount = (input['amount'] as num?)?.toDouble();
      final note = input['note'] as String?;
      final categoryId = input['categoryId'] as String?;
      final walletId = input['walletId'] as String?;

      await context.ref.read(transactionProvider.notifier).updateTransaction(
        target.id,
        amount: amount,
        note: note,
        categoryId: categoryId,
        walletId: walletId,
      );
      return true;
    }

    final amount = (input['amount'] as num?)?.toDouble();
    final note = input['note'] as String?;
    final categoryId = input['categoryId'] as String?;
    final walletId = input['walletId'] as String?;
    final type = input['type'] as String?;

    await context.ref.read(transactionProvider.notifier).updateTransaction(
      transactionId,
      amount: amount,
      note: note,
      categoryId: categoryId,
      walletId: walletId,
      type: type,
    );

    return true;
  }
}

/// Mutation tool to delete a transaction.
class DeleteTransactionTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'transaction_delete';

  @override
  String get description => 'Xóa một giao dịch khỏi hệ thống';

  @override
  bool get isDestructive => true;

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'transactionId': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final transactionId = input['transactionId'] as String?;
    if (transactionId != null && transactionId.isNotEmpty) {
      await context.ref.read(transactionProvider.notifier).deleteTransactions([transactionId]);
      return true;
    }

    // If ID omitted, find most recent transaction
    final txs = context.ref.read(transactionProvider).value ?? [];
    if (txs.isNotEmpty) {
      await context.ref.read(transactionProvider.notifier).deleteTransactions([txs.first.id]);
      return true;
    }

    return false;
  }
}
