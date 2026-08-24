import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'database_helper.dart';
import 'wallet_repository.dart';

class TransactionRepository {
  final _uuid = const Uuid();
  final WalletRepository _walletRepo;

  TransactionRepository({WalletRepository? walletRepo})
      : _walletRepo = walletRepo ?? WalletRepository();

  Future<List<Transaction>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? walletId,
    String? type,
    String? keyword,
    double? minAmount,
    double? maxAmount,
  }) async {
    final db = await DatabaseHelper.instance.database;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += ' AND COALESCE(transaction_date, created_at) >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND COALESCE(transaction_date, created_at) <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    if (walletId != null) {
      where += ' AND wallet_id = ?';
      whereArgs.add(walletId);
    }

    if (type != null) {
      where += ' AND type = ?';
      whereArgs.add(type);
    }

    if (keyword != null && keyword.isNotEmpty) {
      where += ' AND (note LIKE ? OR formula LIKE ?)';
      whereArgs.add('%$keyword%');
      whereArgs.add('%$keyword%');
    }

    if (minAmount != null) {
      where += ' AND amount >= ?';
      whereArgs.add(minAmount);
    }

    if (maxAmount != null) {
      where += ' AND amount <= ?';
      whereArgs.add(maxAmount);
    }

    final maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'COALESCE(transaction_date, created_at) DESC, created_at DESC',
    );

    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<Transaction?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<List<Transaction>> createMultiple(
      List<Map<String, dynamic>> transactionData) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final createdTransactions = <Transaction>[];
    final affectedWalletIds = <String>{};

    // If no wallet specified, resolve default wallet
    final defaultWallet = await _walletRepo.getDefaultWallet();

    for (var data in transactionData) {
      final targetWalletId =
          (data['walletId'] as String?) ?? defaultWallet?.id;

      final transaction = Transaction(
        id: _uuid.v4(),
        categoryId: data['categoryId'] as String?,
        recurringConfigId: data['recurringConfigId'] as String?,
        walletId: targetWalletId,
        amount: data['amount'] as double,
        formula: data['formula'] as String?,
        note: data['note'] as String?,
        type: data['type'] as String,
        transactionDate: data['transactionDate'] as DateTime? ?? now,
        createdAt: now,
        updatedAt: now,
      );

      await db.insert('transactions', transaction.toMap());
      createdTransactions.add(transaction);

      if (targetWalletId != null) {
        affectedWalletIds.add(targetWalletId);
      }
    }

    for (final wid in affectedWalletIds) {
      await _walletRepo.recalculateWalletBalance(wid);
    }

    return createdTransactions;
  }

  Future<Transaction> update(
    String id, {
    String? categoryId,
    String? walletId,
    double? amount,
    String? formula,
    String? note,
    String? type,
    DateTime? transactionDate,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final transaction = await getById(id);

    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    final oldWalletId = transaction.walletId;
    final newWalletId = walletId ?? transaction.walletId;

    final updated = transaction.copyWith(
      categoryId: categoryId ?? transaction.categoryId,
      walletId: newWalletId,
      amount: amount ?? transaction.amount,
      formula: formula ?? transaction.formula,
      note: note ?? transaction.note,
      type: type ?? transaction.type,
      transactionDate: transactionDate ?? transaction.transactionDate,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'transactions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    if (oldWalletId != null) {
      await _walletRepo.recalculateWalletBalance(oldWalletId);
    }
    if (newWalletId != null && newWalletId != oldWalletId) {
      await _walletRepo.recalculateWalletBalance(newWalletId);
    }

    return updated;
  }

  Future<void> deleteMultiple(List<String> ids) async {
    final db = await DatabaseHelper.instance.database;
    final affectedWalletIds = <String>{};

    for (var id in ids) {
      final tx = await getById(id);
      if (tx?.walletId != null) {
        affectedWalletIds.add(tx!.walletId!);
      }
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    for (final wid in affectedWalletIds) {
      await _walletRepo.recalculateWalletBalance(wid);
    }
  }
}
