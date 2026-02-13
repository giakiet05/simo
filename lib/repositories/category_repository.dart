import 'package:uuid/uuid.dart';
import '../models/category.dart';
import 'database_helper.dart';

class CategoryRepository {
  final _uuid = const Uuid();

  Future<List<Category>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'categories',
      orderBy: "CASE WHEN type = 'income' THEN 0 ELSE 1 END, name ASC",
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

  Future<Category> create(String name, String type, {String? icon, String? color}) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    final category = Category(
      id: _uuid.v4(),
      name: name,
      type: type,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );

    final categoryMap = category.toMap();
    categoryMap['synced'] = 0; // Mark as not synced
    await db.insert('categories', categoryMap);
    return category;
  }

  Future<Category> update(String id, String name, String type, {String? icon, String? color}) async {
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
      updatedAt: DateTime.now(),
    );

    final updatedMap = updated.toMap();
    updatedMap['synced'] = 0; // Mark as not synced
    await db.update(
      'categories',
      updatedMap,
      where: 'id = ?',
      whereArgs: [id],
    );

    return updated;
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    // Get cloud_id before deleting
    final cats = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (cats.isEmpty) {
      throw Exception('Category not found');
    }

    final cloudId = cats.first['cloud_id'] as String?;

    // Delete from local
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to pending_deletions if it has cloud_id
    if (cloudId != null) {
      await db.insert('pending_deletions', {
        'cloud_id': cloudId,
        'table_name': 'categories',
        'deleted_at': now,
      });
    }
  }
}
