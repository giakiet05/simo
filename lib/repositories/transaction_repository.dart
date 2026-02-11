import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'database_helper.dart';

class TransactionRepository {
  final _uuid = const Uuid();

  Future<List<Transaction>> getAll({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
    String? keyword,
    double? minAmount,
    double? maxAmount,
  }) async {
    final db = await DatabaseHelper.instance.database;

    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
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
      orderBy: 'created_at DESC',
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

    for (var data in transactionData) {
      final transaction = Transaction(
        id: _uuid.v4(),
        categoryId: data['categoryId'] as String?,
        recurringConfigId: data['recurringConfigId'] as String?,
        amount: data['amount'] as double,
        formula: data['formula'] as String?,
        note: data['note'] as String?,
        type: data['type'] as String,
        createdAt: now,
        updatedAt: now,
      );

      await db.insert('transactions', transaction.toMap());
      createdTransactions.add(transaction);
    }

    return createdTransactions;
  }

  Future<Transaction> update(
    String id, {
    String? categoryId,
    double? amount,
    String? formula,
    String? note,
    String? type,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final transaction = await getById(id);

    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    final updated = transaction.copyWith(
      categoryId: categoryId ?? transaction.categoryId,
      amount: amount ?? transaction.amount,
      formula: formula ?? transaction.formula,
      note: note ?? transaction.note,
      type: type ?? transaction.type,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'transactions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    return updated;
  }

  Future<void> deleteMultiple(List<String> ids) async {
    final db = await DatabaseHelper.instance.database;

    for (var id in ids) {
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
