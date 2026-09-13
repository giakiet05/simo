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
      updatedAt: DateTime.now().toUtc(),
    );

    final map = updated.toMap();
    map['synced'] = 0;
    map['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'transactions',
      map,
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
    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (var id in ids) {
      final tx = await getById(id);
      if (tx?.walletId != null) {
        affectedWalletIds.add(tx!.walletId!);
      }
    }

    await db.transaction((txn) async {
      for (var id in ids) {
        await txn.delete(
          'transactions',
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.insert(
          'pending_deletions',
          {
            'cloud_id': id,
            'table_name': 'transactions',
            'deleted_at': nowIso,
          },
        );
      }
    });

    for (final wid in affectedWalletIds) {
      await _walletRepo.recalculateWalletBalance(wid);
    }
  }

  /// Bulk updates the wallet for multiple transactions and recalculates balances
  /// for both previous wallets and the destination wallet.
  ///
  /// @param ids List of transaction IDs to update.
  /// @param newWalletId Destination wallet ID to assign.
  Future<void> updateWalletMultiple(List<String> ids, String newWalletId) async {
    if (ids.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final affectedWalletIds = <String>{newWalletId};

    for (final id in ids) {
      final tx = await getById(id);
      if (tx?.walletId != null) {
        affectedWalletIds.add(tx!.walletId!);
      }
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.update(
          'transactions',
          {
            'wallet_id': newWalletId,
            'updated_at': nowIso,
            'synced': 0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });

    for (final wid in affectedWalletIds) {
      await _walletRepo.recalculateWalletBalance(wid);
    }
  }

  /// Bulk updates the category for multiple transactions.
  ///
  /// @param ids List of transaction IDs to update.
  /// @param newCategoryId Category ID to assign (or null to unassign).
  Future<void> updateCategoryMultiple(List<String> ids, String? newCategoryId) async {
    if (ids.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.update(
          'transactions',
          {
            'category_id': newCategoryId,
            'updated_at': nowIso,
            'synced': 0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  /// Bulk updates the transaction date for multiple transactions while preserving
  /// their original hour, minute, and second.
  ///
  /// @param ids List of transaction IDs to update.
  /// @param newDate Target date to apply.
  Future<void> updateDateMultiple(List<String> ids, DateTime newDate) async {
    if (ids.isEmpty) return;

    final targetTransactions = <Transaction>[];
    for (final id in ids) {
      final tx = await getById(id);
      if (tx != null) {
        targetTransactions.add(tx);
      }
    }

    final db = await DatabaseHelper.instance.database;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      for (final tx in targetTransactions) {
        final oldDate = tx.transactionDate;
        final updatedTxDate = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          oldDate.hour,
          oldDate.minute,
          oldDate.second,
          oldDate.millisecond,
        );
        await txn.update(
          'transactions',
          {
            'transaction_date': updatedTxDate.toIso8601String(),
            'updated_at': nowIso,
            'synced': 0,
          },
          where: 'id = ?',
          whereArgs: [tx.id],
        );
      }
    });
  }
}
