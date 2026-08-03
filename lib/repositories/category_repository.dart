import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import 'database_helper.dart';

class CategoryRepository {
  final _uuid = const Uuid();

  Future<void> _ensureSystemCategories(Database db) async {
    final sysCats = [
      {'id': 'sys_loan_borrow', 'name': 'Nợ', 'type': 'income', 'icon': 'account_balance_wallet', 'color': '#FF4CAF50'},
      {'id': 'sys_loan_repay', 'name': 'Trả nợ', 'type': 'expense', 'icon': 'money_off', 'color': '#FFF44336'},
      {'id': 'sys_loan_lend', 'name': 'Cho vay', 'type': 'expense', 'icon': 'account_balance_wallet', 'color': '#FFF44336'},
      {'id': 'sys_loan_collect', 'name': 'Thu tiền vay', 'type': 'income', 'icon': 'attach_money', 'color': '#FF4CAF50'},
    ];
    for (var cat in sysCats) {
      final existing = await db.query('categories', where: 'id = ?', whereArgs: [cat['id']]);
      if (existing.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await db.insert('categories', {
          ...cat,
          'created_at': now,
          'updated_at': now,
        });
      }
    }
  }

  Future<List<Category>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    await _ensureSystemCategories(db);
    
    final maps = await db.query(
      'categories',
      orderBy: "CASE WHEN id LIKE 'sys_%' THEN 0 ELSE 1 END, CASE WHEN type = 'income' THEN 0 ELSE 1 END, name ASC",
    );

    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<Category> create(String name, String type, {String? icon, String? color, double? budgetLimit}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    final category = Category(
      id: _uuid.v4(),
      name: name,
      type: type,
      icon: icon,
      color: color,
      budgetLimit: budgetLimit,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('categories', category.toMap());
    return category;
  }

  Future<Category> update(String id, String name, String type, {String? icon, String? color, double? budgetLimit}) async {
    final db = await DatabaseHelper.instance.database;
    final category = await getById(id);

    if (category == null) {
      throw Exception('Category not found');
    }

    final updated = category.copyWith(
      name: name,
      type: type,
      icon: icon,
      color: color,
      budgetLimit: budgetLimit,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'categories',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );

    return updated;
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;

    final deletedCount = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedCount == 0) {
      throw Exception('Category not found');
    }
  }
}
