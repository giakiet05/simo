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
    test('generateMockData creates full database: categories, wallets, transactions, budgets, loans, goals, recurring, and transfers', () async {
      final categoryRepo = CategoryRepository();
      final generator = MockDataGenerator(categoryRepo);

      await generator.generateMockData();

      final db = await DatabaseHelper.instance.database;

      // 1. Verify categories count
      final incomeCategories = await db.query('categories', where: 'type = ?', whereArgs: ['income']);
      final expenseCategories = await db.query('categories', where: 'type = ? AND id NOT LIKE ?', whereArgs: ['expense', 'sys_loan_%']);

      expect(incomeCategories.length, greaterThanOrEqualTo(5));
      expect(expenseCategories.length, 5);

      // 2. Verify wallets count (4 wallets) and recalculated balances (> 0)
      final wallets = await db.query('wallets');
      expect(wallets.length, 4);
      for (final w in wallets) {
        final currentBalance = (w['current_balance'] as num).toDouble();
        expect(currentBalance, greaterThan(0.0), reason: 'Wallet ${w['name']} balance should be positive');
      }

      // 3. Verify transactions count (>= 120) and all have valid wallet_id
      final transactions = await db.query('transactions');
      expect(transactions.length, greaterThanOrEqualTo(120));
      for (final tx in transactions) {
        expect(tx['wallet_id'], isNotNull, reason: 'Transaction ${tx['id']} should have a wallet_id');
        expect(tx['category_id'], isNotNull, reason: 'Transaction ${tx['id']} should have a category_id');
      }

      // Verify September 2026 transactions exist
      final sepTransactions = await db.query(
        'transactions',
        where: "transaction_date LIKE '2026-09-%'",
      );
      expect(sepTransactions.length, greaterThanOrEqualTo(10));

      // 4. Verify multi-month budgets (7 months: 03/2026 to 09/2026)
      final monthlyBudgets = await db.query('monthly_budgets');
      expect(monthlyBudgets.length, 7);

      final categoryBudgets = await db.query('category_monthly_budgets');
      expect(categoryBudgets.length, 35); // 7 months * 5 expense categories

      // 5. Verify loan contacts and transactions (4 contacts, 8 transactions)
      final loanContacts = await db.query('loan_contacts');
      final loanTransactions = await db.query('loan_transactions');
      expect(loanContacts.length, 4);
      expect(loanTransactions.length, 8);

      // 6. Verify saving goals and logs (3 goals, 8 logs)
      final savingGoals = await db.query('saving_goals');
      final savingGoalLogs = await db.query('saving_goal_logs');
      expect(savingGoals.length, 3);
      expect(savingGoalLogs.length, 8);

      // 7. Verify recurring configs (5 configs)
      final recurringConfigs = await db.query('recurring_configs');
      expect(recurringConfigs.length, 5);
      for (final r in recurringConfigs) {
        expect(r['wallet_id'], isNotNull);
        expect(r['category_id'], isNotNull);
      }

      // 8. Verify wallet transfers (17 transfers)
      final transfers = await db.query('wallet_transfers');
      expect(transfers.length, greaterThanOrEqualTo(10));
    });
  });
}
