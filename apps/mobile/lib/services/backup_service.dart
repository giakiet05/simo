import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/backup_snapshot.dart';
import '../models/import_inspection.dart';
import '../repositories/database_helper.dart';
import 'file_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper;

  BackupService({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Alias for backward compatibility with existing tests
  Future<File> createBackupFile() => createBackupSnapshot();

  /// Generates a full JSON backup snapshot and returns the temporary file
  Future<File> createBackupSnapshot() async {
    final db = await _dbHelper.database;
    const appVersion = '1.0.0';

    // 1. Gather all settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{
      'currency': prefs.getString('currency') ?? 'VND',
      'language': prefs.getString('language') ?? 'vi',
      'theme': prefs.getString('theme_mode') ?? 'system',
      'monthly_budget': prefs.getDouble('monthly_budget'),
    };

    // 2. Gather all database tables
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final monthlyBudgets = await db.query('monthly_budgets');
    final categoryMonthlyBudgets = await db.query('category_monthly_budgets');
    final loanContacts = await db.query('loan_contacts');
    final loanTransactions = await db.query('loan_transactions');
    final recurringConfigs = await db.query('recurring_configs');
    final savingGoals = await db.query('saving_goals');
    final savingGoalLogs = await db.query('saving_goal_logs');
    final wallets = await db.query('wallets');
    final walletTransfers = await db.query('wallet_transfers');

    final snapshot = BackupSnapshot(
      version: 1,
      app: 'simo',
      appVersion: appVersion,
      exportedAt: DateTime.now(),
      settings: settings,
      categories: categories.map((e) => Map<String, dynamic>.from(e)).toList(),
      transactions:
          transactions.map((e) => Map<String, dynamic>.from(e)).toList(),
      monthlyBudgets:
          monthlyBudgets.map((e) => Map<String, dynamic>.from(e)).toList(),
      categoryMonthlyBudgets: categoryMonthlyBudgets
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      loanContacts:
          loanContacts.map((e) => Map<String, dynamic>.from(e)).toList(),
      loanTransactions:
          loanTransactions.map((e) => Map<String, dynamic>.from(e)).toList(),
      recurringConfigs:
          recurringConfigs.map((e) => Map<String, dynamic>.from(e)).toList(),
      savingGoals:
          savingGoals.map((e) => Map<String, dynamic>.from(e)).toList(),
      savingGoalLogs:
          savingGoalLogs.map((e) => Map<String, dynamic>.from(e)).toList(),
      wallets: wallets.map((e) => Map<String, dynamic>.from(e)).toList(),
      walletTransfers:
          walletTransfers.map((e) => Map<String, dynamic>.from(e)).toList(),
    );

    final file = await FileHelper.createTempExportFile(
      prefix: 'simo_backup',
      extension: '.json',
    );

    await file.writeAsString(snapshot.toJsonString(), flush: true);
    return file;
  }

  /// Inspects a selected backup file without modifying the database
  Future<ImportInspection> inspectBackupFile(File file) async {
    try {
      if (!await file.exists()) {
        return ImportInspection.invalid('File không tồn tại');
      }

      final content = await file.readAsString();
      final Map<String, dynamic> jsonMap =
          jsonDecode(content) as Map<String, dynamic>;

      if (!jsonMap.containsKey('version') || !jsonMap.containsKey('data')) {
        return ImportInspection.invalid('Cấu trúc file sao lưu không hợp lệ');
      }

      final snapshot = BackupSnapshot.fromMap(jsonMap);

      return ImportInspection(
        schemaVersion: snapshot.version,
        appVersion: snapshot.appVersion,
        exportedAt: snapshot.exportedAt,
        totalCategories: snapshot.categories.length,
        totalTransactions: snapshot.transactions.length,
        totalMonthlyBudgets: snapshot.monthlyBudgets.length,
        totalCategoryBudgets: snapshot.categoryMonthlyBudgets.length,
        totalLoans: snapshot.loanContacts.length,
        totalLoanTransactions: snapshot.loanTransactions.length,
        totalRecurringConfigs: snapshot.recurringConfigs.length,
        totalSavingGoals: snapshot.savingGoals.length,
        totalSavingGoalLogs: snapshot.savingGoalLogs.length,
        totalWallets: snapshot.wallets.length,
        totalWalletTransfers: snapshot.walletTransfers.length,
        isValid: true,
      );
    } catch (e) {
      return ImportInspection.invalid('Không thể đọc file sao lưu: $e');
    }
  }

  /// Restores data from a backup file inside an atomic SQLite transaction
  Future<bool> restoreFromBackup(
    File file, {
    required bool overwriteMode,
  }) async {
    final inspection = await inspectBackupFile(file);
    if (!inspection.isValid) {
      throw Exception(inspection.errorMessage ?? 'File không hợp lệ');
    }

    final content = await file.readAsString();
    final snapshot = BackupSnapshot.fromJsonString(content);
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      if (overwriteMode) {
        // Clear existing tables in reverse dependency order
        await txn.delete('wallet_transfers');
        await txn.delete('saving_goal_logs');
        await txn.delete('saving_goals');
        await txn.delete('transactions');
        await txn.delete('wallets');
        await txn.delete('category_monthly_budgets');
        await txn.delete('recurring_configs');
        await txn.delete('loan_transactions');
        await txn.delete('loan_contacts');
        await txn.delete('monthly_budgets');
        await txn.delete('categories');
      }

      // 1. Insert Categories
      for (final cat in snapshot.categories) {
        await txn.insert(
          'categories',
          cat,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 2. Insert Monthly Budgets
      for (final mb in snapshot.monthlyBudgets) {
        await txn.insert(
          'monthly_budgets',
          mb,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 3. Insert Category Monthly Budgets
      for (final cmb in snapshot.categoryMonthlyBudgets) {
        await txn.insert(
          'category_monthly_budgets',
          cmb,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 4. Insert Recurring Configs
      for (final rec in snapshot.recurringConfigs) {
        await txn.insert(
          'recurring_configs',
          rec,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 5. Insert Loan Contacts
      for (final lc in snapshot.loanContacts) {
        await txn.insert(
          'loan_contacts',
          lc,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 6. Insert Loan Transactions
      for (final lt in snapshot.loanTransactions) {
        await txn.insert(
          'loan_transactions',
          lt,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 7. Insert Wallets
      for (final w in snapshot.wallets) {
        await txn.insert(
          'wallets',
          w,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 8. Insert Wallet Transfers
      for (final wt in snapshot.walletTransfers) {
        await txn.insert(
          'wallet_transfers',
          wt,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 9. Insert Transactions
      for (final tx in snapshot.transactions) {
        await txn.insert(
          'transactions',
          tx,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 10. Insert Saving Goals
      for (final sg in snapshot.savingGoals) {
        await txn.insert(
          'saving_goals',
          sg,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }

      // 11. Insert Saving Goal Logs
      for (final sgl in snapshot.savingGoalLogs) {
        await txn.insert(
          'saving_goal_logs',
          sgl,
          conflictAlgorithm: overwriteMode
              ? ConflictAlgorithm.replace
              : ConflictAlgorithm.ignore,
        );
      }
    });

    // 12. Restore Settings
    if (snapshot.settings.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      if (snapshot.settings.containsKey('currency')) {
        await prefs.setString(
            'currency', snapshot.settings['currency'].toString());
      }
      if (snapshot.settings.containsKey('language')) {
        await prefs.setString(
            'language', snapshot.settings['language'].toString());
      }
      if (snapshot.settings.containsKey('theme')) {
        await prefs.setString(
            'theme_mode', snapshot.settings['theme'].toString());
      }
      if (snapshot.settings.containsKey('monthly_budget')) {
        final val = snapshot.settings['monthly_budget'];
        if (val is num) {
          await prefs.setDouble('monthly_budget', val.toDouble());
        }
      }
    }

    return true;
  }
}
