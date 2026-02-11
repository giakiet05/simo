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

  Future<Category> create(String name, String type) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    final category = Category(
      id: _uuid.v4(),
      name: name,
      type: type,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('categories', category.toMap());
    return category;
  }

  Future<Category> update(String id, String name, String type) async {
    final db = await DatabaseHelper.instance.database;
    final category = await getById(id);

    if (category == null) {
      throw Exception('Category not found');
    }

    final updated = category.copyWith(
      name: name,
      type: type,
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
    final category = await getById(id);

    if (category == null) {
      throw Exception('Category not found');
    }

    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
