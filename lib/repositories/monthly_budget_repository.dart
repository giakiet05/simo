import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/monthly_budget.dart';
import 'database_helper.dart';

class MonthlyBudgetRepository {
  final _uuid = const Uuid();

  Future<MonthlyBudget?> getMonthlyBudget(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'monthly_budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );

    if (maps.isNotEmpty) {
      return MonthlyBudget.fromMap(maps.first);
    }
    return null;
  }

  Future<void> setMonthlyBudget(int year, int month, double amount) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    final existing = await getMonthlyBudget(year, month);
    if (existing != null) {
      await db.update(
        'monthly_budgets',
        {
          'amount': amount,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      await db.insert(
        'monthly_budgets',
        {
          'id': _uuid.v4(),
          'year': year,
          'month': month,
          'amount': amount,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteMonthlyBudget(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'monthly_budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
  }

  Future<Map<String, CategoryMonthlyBudget>> getCategoryMonthlyBudgets(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'category_monthly_budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );

    final result = <String, CategoryMonthlyBudget>{};
    for (final map in maps) {
      final item = CategoryMonthlyBudget.fromMap(map);
      result[item.categoryId] = item;
    }
    return result;
  }

  Future<void> setCategoryMonthlyBudget(String categoryId, int year, int month, double amount) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      'category_monthly_budgets',
      where: 'category_id = ? AND year = ? AND month = ?',
      whereArgs: [categoryId, year, month],
    );

    if (maps.isNotEmpty) {
      final id = maps.first['id'] as String;
      await db.update(
        'category_monthly_budgets',
        {
          'amount': amount,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert(
        'category_monthly_budgets',
        {
          'id': _uuid.v4(),
          'category_id': categoryId,
          'year': year,
          'month': month,
          'amount': amount,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteCategoryMonthlyBudget(String categoryId, int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'category_monthly_budgets',
      where: 'category_id = ? AND year = ? AND month = ?',
      whereArgs: [categoryId, year, month],
    );
  }

  Future<void> copyBudgetsFromMonth({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    final fromTotal = await getMonthlyBudget(fromYear, fromMonth);
    if (fromTotal != null) {
      await setMonthlyBudget(toYear, toMonth, fromTotal.amount);
    }

    final fromCategoryBudgets = await getCategoryMonthlyBudgets(fromYear, fromMonth);
    for (final entry in fromCategoryBudgets.entries) {
      await setCategoryMonthlyBudget(entry.key, toYear, toMonth, entry.value.amount);
    }
  }

  Future<List<MonthlyBudget>> getAllMonthlyBudgets() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('monthly_budgets', orderBy: 'year DESC, month DESC');
    return maps.map((m) => MonthlyBudget.fromMap(m)).toList();
  }

  Future<void> clearAllBudgets() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete('category_monthly_budgets');
      await txn.delete('monthly_budgets');
    });
  }
}
