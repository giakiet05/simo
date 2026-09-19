import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/category.dart';
import '../../../models/wallet.dart';
import '../../../models/transaction.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to create a new income or expense transaction.
class CreateTransactionTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
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
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return {'isSuccess': false};

    final type = input['type'] as String? ?? 'expense';
    final note = input['note'] as String? ?? '';
    final date = AgentDateHelper.parseDate(input['date'] as String?);

    var allCategories = context.ref.read(categoryProvider).value ?? [];
    if (allCategories.isEmpty) {
      allCategories = await context.ref.read(categoryRepositoryProvider).getAll();
    }
    final userCategories = allCategories.where((c) => !c.id.startsWith('sys_')).toList();

    var wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }

    final rawCatId = input['categoryId'] as String?;
    final rawCatName = (input['categoryName'] as String?) ?? (input['category'] as String?);

    Category? matchedCategory;
    // 1. Direct ID match (exclude internal sys_ categories)
    if (rawCatId != null && rawCatId.isNotEmpty && !rawCatId.startsWith('sys_')) {
      matchedCategory = userCategories.where((c) => c.id == rawCatId).firstOrNull;
    }

    // 2. Exact or partial match by categoryName
    if (matchedCategory == null && rawCatName != null && rawCatName.trim().isNotEmpty) {
      final query = rawCatName.trim().toLowerCase();
      matchedCategory = userCategories.where((c) => c.name.toLowerCase() == query).firstOrNull ??
          userCategories.where((c) => c.name.toLowerCase().contains(query) || query.contains(c.name.toLowerCase())).firstOrNull;
    }

    // 3. In case the AI put the category name inside categoryId
    if (matchedCategory == null && rawCatId != null && rawCatId.trim().isNotEmpty && !rawCatId.startsWith('sys_')) {
      final query = rawCatId.trim().toLowerCase();
      matchedCategory = userCategories.where((c) => c.name.toLowerCase() == query).firstOrNull ??
          userCategories.where((c) => c.name.toLowerCase().contains(query) || query.contains(c.name.toLowerCase())).firstOrNull;
    }

    // 4. Match based on note keywords
    if (matchedCategory == null && note.isNotEmpty) {
      final noteLower = note.toLowerCase();
      matchedCategory = userCategories.where((c) =>
        c.type == type && (noteLower.contains(c.name.toLowerCase()) || c.name.toLowerCase().contains(noteLower))
      ).firstOrNull;
    }

    // 5. Fallback rule: If no specific category matches, prioritize 'Khác' / 'Other'. If none, leave null!
    matchedCategory ??= userCategories.where((c) =>
      c.type == type && (c.name.toLowerCase().contains('khác') || c.name.toLowerCase().contains('other'))
    ).firstOrNull;

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

    final String generatedId = const Uuid().v4();

    await context.ref.read(transactionProvider.notifier).createTransactions([
      {
        'id': generatedId,
        'categoryId': categoryId,
        'walletId': walletId,
        'amount': amount,
        'note': note,
        'type': type,
        'transactionDate': date,
      }
    ]);

    return {
      'transactionId': generatedId,
      'id': generatedId,
      'amount': amount,
      'type': type,
      'note': note,
      'categoryId': categoryId,
      'walletId': walletId,
      'date': date.toIso8601String(),
    };
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
    var allCategories = context.ref.read(categoryProvider).value ?? [];
    if (allCategories.isEmpty) {
      allCategories = await context.ref.read(categoryRepositoryProvider).getAll();
    }
    final userCategories = allCategories.where((c) => !c.id.startsWith('sys_')).toList();

    var wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }
    final txs = context.ref.read(transactionProvider).value ?? [];
    if (txs.isEmpty) return false;

    // 1. Resolve category
    String? categoryId = input['categoryId'] as String?;
    if (categoryId != null && categoryId.startsWith('sys_')) {
      categoryId = null;
    }
    final categoryName = (input['categoryName'] as String?) ?? (input['category'] as String?);
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      final matched = userCategories.where((c) => c.name.toLowerCase() == categoryName.toLowerCase().trim()).firstOrNull ??
          userCategories.where((c) => c.name.toLowerCase().contains(categoryName.toLowerCase().trim())).firstOrNull;
      if (matched != null) {
        categoryId = matched.id;
      }
    }

    // 2. Resolve wallet
    String? walletId = input['walletId'] as String?;
    final walletName = (input['walletName'] as String?) ?? (input['wallet'] as String?);
    if (walletName != null && walletName.trim().isNotEmpty) {
      final matched = wallets.where((w) => w.name.toLowerCase() == walletName.toLowerCase().trim()).firstOrNull ??
          wallets.where((w) => w.name.toLowerCase().contains(walletName.toLowerCase().trim())).firstOrNull;
      if (matched != null) {
        walletId = matched.id;
      }
    }

    // 3. Resolve target transaction
    final rawTxId = input['transactionId'] as String?;
    final targetNote = (input['note'] as String?)?.toLowerCase().trim();

    Transaction? target;
    if (rawTxId != null && rawTxId.isNotEmpty) {
      target = txs.where((t) => t.id == rawTxId).firstOrNull;
    }

    // Handle placeholder IDs like "transaction_id_of_coffee"
    if (target == null && rawTxId != null && rawTxId.isNotEmpty) {
      final cleanQuery = rawTxId.toLowerCase()
          .replaceAll('transaction_id_of_', '')
          .replaceAll('tx_', '')
          .replaceAll('_', ' ')
          .trim();
      if (cleanQuery.isNotEmpty) {
        target = txs.where((t) {
          final note = (t.note ?? '').toLowerCase();
          return note.contains(cleanQuery) || cleanQuery.contains(note);
        }).firstOrNull;
      }
    }

    // Match by note query
    if (target == null && targetNote != null && targetNote.isNotEmpty) {
      target = txs.where((t) {
        final note = (t.note ?? '').toLowerCase();
        return note.contains(targetNote) || targetNote.contains(note);
      }).firstOrNull;
    }

    // Fallback to most recent transaction
    target ??= txs.first;

    // 4. Safe amount handling (ignore 0)
    final double? rawAmount = (input['amount'] as num?)?.toDouble();
    final double? newAmount = (rawAmount != null && rawAmount > 0) ? rawAmount : null;

    final String? newNote = (input['newNote'] as String?) ??
        (targetNote != null && targetNote.isNotEmpty && targetNote != target.note?.toLowerCase() ? input['note'] as String? : null);
    final String? newType = input['type'] as String?;

    await context.ref.read(transactionProvider.notifier).updateTransaction(
      target.id,
      amount: newAmount,
      note: newNote,
      categoryId: categoryId,
      walletId: walletId,
      type: newType,
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
    final txs = context.ref.read(transactionProvider).value ?? [];
    if (txs.isEmpty) return false;

    final rawTxId = input['transactionId'] as String?;
    final targetNote = (input['note'] as String?)?.toLowerCase().trim();

    Transaction? target;
    if (rawTxId != null && rawTxId.isNotEmpty) {
      target = txs.where((t) => t.id == rawTxId).firstOrNull;
    }

    if (target == null && rawTxId != null && rawTxId.isNotEmpty) {
      final cleanQuery = rawTxId.toLowerCase()
          .replaceAll('transaction_id_of_', '')
          .replaceAll('tx_', '')
          .replaceAll('_', ' ')
          .trim();
      if (cleanQuery.isNotEmpty) {
        target = txs.where((t) {
          final note = (t.note ?? '').toLowerCase();
          return note.contains(cleanQuery) || cleanQuery.contains(note);
        }).firstOrNull;
      }
    }

    if (target == null && targetNote != null && targetNote.isNotEmpty) {
      target = txs.where((t) {
        final note = (t.note ?? '').toLowerCase();
        return note.contains(targetNote) || targetNote.contains(note);
      }).firstOrNull;
    }

    target ??= txs.first;

    await context.ref.read(transactionProvider.notifier).deleteTransactions([target.id]);
    return true;
  }
}
