import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/category_repository.dart';
import 'package:simo/utils/mock_data_generator.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('MockDataGenerator Tests', () {
    test('generateMockData creates 5 income, 5 expense categories, 100+ transactions, and 6 months of budgets', () async {
      final categoryRepo = CategoryRepository();
      final generator = MockDataGenerator(categoryRepo);

      await generator.generateMockData();

      final db = await DatabaseHelper.instance.database;

      // 1. Verify categories count
      final incomeCategories = await db.query('categories', where: 'type = ?', whereArgs: ['income']);
      final expenseCategories = await db.query('categories', where: 'type = ? AND id NOT LIKE ?', whereArgs: ['expense', 'sys_loan_%']);

      expect(incomeCategories.length, greaterThanOrEqualTo(5));
      expect(expenseCategories.length, 5);

      // 2. Verify transactions count (>= 100)
      final transactions = await db.query('transactions');
      expect(transactions.length, greaterThanOrEqualTo(100));

      // 3. Verify multi-month budgets (6 months: 03/2026 to 08/2026)
      final monthlyBudgets = await db.query('monthly_budgets');
      expect(monthlyBudgets.length, 6);

      final categoryBudgets = await db.query('category_monthly_budgets');
      expect(categoryBudgets.length, 30); // 6 months * 5 expense categories

      // 4. Verify loan contacts and transactions
      final loanContacts = await db.query('loan_contacts');
      final loanTransactions = await db.query('loan_transactions');
      expect(loanContacts.length, 2);
      expect(loanTransactions.length, 4);
    });
  });
}
