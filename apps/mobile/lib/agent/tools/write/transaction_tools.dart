import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/category.dart';
import '../../../models/wallet.dart';
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

    final rawCatId = input['categoryId'] as String?;
    final rawCatName = (input['categoryName'] as String?) ?? (input['category'] as String?);

    Category? matchedCategory;
    // 1. Direct ID match
    if (rawCatId != null && rawCatId.isNotEmpty) {
      matchedCategory = categories.where((c) => c.id == rawCatId).firstOrNull;
    }

    // 2. Exact or partial match by categoryName
    if (matchedCategory == null && rawCatName != null && rawCatName.trim().isNotEmpty) {
      final query = rawCatName.trim().toLowerCase();
      matchedCategory = categories.where((c) => c.name.toLowerCase() == query).firstOrNull ??
          categories.where((c) => c.name.toLowerCase().contains(query) || query.contains(c.name.toLowerCase())).firstOrNull;
    }

    // 3. In case the AI put the category name inside categoryId
    if (matchedCategory == null && rawCatId != null && rawCatId.trim().isNotEmpty) {
      final query = rawCatId.trim().toLowerCase();
      matchedCategory = categories.where((c) => c.name.toLowerCase() == query).firstOrNull ??
          categories.where((c) => c.name.toLowerCase().contains(query) || query.contains(c.name.toLowerCase())).firstOrNull;
    }

    // 4. Match based on note keywords
    if (matchedCategory == null && note.isNotEmpty) {
      final noteLower = note.toLowerCase();
      matchedCategory = categories.where((c) =>
        c.type == type && (noteLower.contains(c.name.toLowerCase()) || c.name.toLowerCase().contains(noteLower))
      ).firstOrNull;
    }

    // 5. Fallback to first category of matching type or first available
    matchedCategory ??= categories.where((c) => c.type == type).firstOrNull ?? (categories.isNotEmpty ? categories.first : null);

    final String? categoryId = matchedCategory?.id;

    // Wallet matching
    final rawWalletId = input['walletId'] as String?;
    final rawWalletName = (input['walletName'] as String?) ?? (input['wallet'] as String?);

    Wallet? matchedWallet;
    if (rawWalletId != null && rawWalletId.isNotEmpty) {
      matchedWallet = wallets.where((w) => w.id == rawWalletId).firstOrNull;
    }
    if (matchedWallet == null && rawWalletName != null && rawWalletName.trim().isNotEmpty) {
      final query = rawWalletName.trim().toLowerCase();
      matchedWallet = wallets.where((w) => w.name.toLowerCase() == query).firstOrNull ??
          wallets.where((w) => w.name.toLowerCase().contains(query)).firstOrNull;
    }
    if (matchedWallet == null && rawWalletId != null && rawWalletId.trim().isNotEmpty) {
      final query = rawWalletId.trim().toLowerCase();
      matchedWallet = wallets.where((w) => w.name.toLowerCase() == query).firstOrNull ??
          wallets.where((w) => w.name.toLowerCase().contains(query)).firstOrNull;
    }
    matchedWallet ??= wallets.where((w) => w.isDefault).firstOrNull ?? (wallets.isNotEmpty ? wallets.first : null);

    final String? walletId = matchedWallet?.id;

    await context.ref.read(transactionProvider.notifier).createTransactions([
      {
        'id': const Uuid().v4(),
        'categoryId': categoryId,
        'walletId': walletId,
        'amount': amount,
        'note': note,
        'type': type,
        'transactionDate': date,
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
      'categoryName': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'walletName': {'type': ['string', 'null']},
      'type': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final categories = context.ref.read(categoryProvider).value ?? [];
    final wallets = context.ref.read(walletProvider).value ?? [];

    String? categoryId = input['categoryId'] as String?;
    final categoryName = (input['categoryName'] as String?) ?? (input['category'] as String?);
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final matched = categories.where((c) => c.name.toLowerCase() == categoryName.toLowerCase().trim()).firstOrNull ??
          categories.where((c) => c.name.toLowerCase().contains(categoryName.toLowerCase().trim())).firstOrNull;
      if (matched != null) {
        categoryId = matched.id;
      }
    }

    String? walletId = input['walletId'] as String?;
    final walletName = (input['walletName'] as String?) ?? (input['wallet'] as String?);
    if (walletName != null && walletName.trim().isNotEmpty) {
      final matched = wallets.where((w) => w.name.toLowerCase() == walletName.toLowerCase().trim()).firstOrNull ??
          wallets.where((w) => w.name.toLowerCase().contains(walletName.toLowerCase().trim())).firstOrNull;
      if (matched != null) {
        walletId = matched.id;
      }
    }

    final transactionId = input['transactionId'] as String?;
    if (transactionId == null || transactionId.isEmpty) {
      // If no explicit ID, fallback to finding the most recent transaction
      final txs = context.ref.read(transactionProvider).value ?? [];
      if (txs.isEmpty) return false;
      final target = txs.first;
      final amount = (input['amount'] as num?)?.toDouble();
      final note = input['note'] as String?;

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
