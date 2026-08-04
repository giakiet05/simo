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
    await db.update(
      'loan_contacts',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<void> deleteLoanContact(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
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
    await db.update(
      'loan_transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> deleteLoanTransaction(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'loan_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
