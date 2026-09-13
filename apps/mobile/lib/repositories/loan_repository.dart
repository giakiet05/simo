import 'package:sqflite/sqflite.dart';
import '../models/loan_contact.dart';
import '../models/loan_transaction.dart';
import 'database_helper.dart';

class LoanRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<LoanContact>> getLoans() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_contacts',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => LoanContact.fromMap(maps[i]));
  }

  Future<LoanContact> getLoanContact(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return LoanContact.fromMap(maps.first);
    }
    throw Exception('Loan not found');
  }

  Future<void> insertLoanContact(LoanContact loan) async {
    final db = await _dbHelper.database;
    await db.insert(
      'loan_contacts',
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLoanContact(LoanContact loan) async {
    final db = await _dbHelper.database;
    final map = loan.toMap();
    map['synced'] = 0;
    map['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'loan_contacts',
      map,
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<void> deleteLoanContact(String id) async {
    final db = await _dbHelper.database;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      final txs = await txn.query(
        'loan_transactions',
        where: 'loan_id = ?',
        whereArgs: [id],
      );
      for (final tx in txs) {
        await txn.insert('pending_deletions', {
          'cloud_id': tx['id'],
          'table_name': 'loan_transactions',
          'deleted_at': nowIso,
        });
      }
      await txn.delete(
        'loan_transactions',
        where: 'loan_id = ?',
        whereArgs: [id],
      );

      await txn.delete(
        'loan_contacts',
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('pending_deletions', {
        'cloud_id': id,
        'table_name': 'loan_contacts',
        'deleted_at': nowIso,
      });
    });
  }

  Future<List<LoanTransaction>> getLoanTransactions(String loanId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'loan_transactions',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'date DESC, created_at DESC',
    );
    return List.generate(maps.length, (i) => LoanTransaction.fromMap(maps[i]));
  }

  Future<void> insertLoanTransaction(LoanTransaction tx) async {
    final db = await _dbHelper.database;
    await db.insert(
      'loan_transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLoanTransaction(LoanTransaction tx) async {
    final db = await _dbHelper.database;
    final map = tx.toMap();
    map['synced'] = 0;
    map['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'loan_transactions',
      map,
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> deleteLoanTransaction(String id) async {
    final db = await _dbHelper.database;
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await db.transaction((txn) async {
      await txn.delete(
        'loan_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('pending_deletions', {
        'cloud_id': id,
        'table_name': 'loan_transactions',
        'deleted_at': nowIso,
      });
    });
  }
}
