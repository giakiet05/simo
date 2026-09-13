import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/category_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('CategoryRepository Tests', () {
    late CategoryRepository repo;

    setUp(() {
      repo = CategoryRepository();
    });

    test('deleting a category sets category_id to NULL on all associated transactions', () async {
      final db = await DatabaseHelper.instance.database;

      // 1. Create a category
      final category = await repo.create('Shopping Food', 'expense', icon: 'shopping_bag', color: '#EF4444');
      final catId = category.id;

      // 2. Insert transactions referencing this category
      await db.insert('transactions', {
        'id': 'tx_with_cat_1',
        'amount': 150000.0,
        'type': 'expense',
        'category_id': catId,
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await db.insert('transactions', {
        'id': 'tx_with_cat_2',
        'amount': 50000.0,
        'type': 'expense',
        'category_id': catId,
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Verify transactions have category_id set
      final txBefore = await db.query('transactions', where: 'id = ?', whereArgs: ['tx_with_cat_1']);
      expect(txBefore.first['category_id'], equals(catId));

      // 3. Delete the category
      await repo.delete(catId);

      // Verify category is deleted
      final deletedCat = await repo.getById(catId);
      expect(deletedCat, isNull);

      // 4. Verify transactions still exist and their category_id is now NULL
      final txAfter1 = await db.query('transactions', where: 'id = ?', whereArgs: ['tx_with_cat_1']);
      final txAfter2 = await db.query('transactions', where: 'id = ?', whereArgs: ['tx_with_cat_2']);

      expect(txAfter1, isNotEmpty);
      expect(txAfter1.first['category_id'], isNull);

      expect(txAfter2, isNotEmpty);
      expect(txAfter2.first['category_id'], isNull);
    });
  });
}
