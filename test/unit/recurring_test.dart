import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/recurring_config.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/recurring_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('RecurringConfig Model Tests', () {
    test('serializes and deserializes walletId properly', () {
      final now = DateTime.now();
      final config = RecurringConfig(
        id: 'rec_1',
        categoryId: 'cat_1',
        walletId: 'wallet_1',
        name: 'Tiền mạng',
        amount: 250000.0,
        type: 'expense',
        frequency: 'monthly',
        interval: 1,
        dayOfMonth: 15,
        nextRun: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = config.toMap();
      expect(map['wallet_id'], equals('wallet_1'));
      expect(map['name'], equals('Tiền mạng'));
      expect(map['amount'], equals(250000.0));

      final fromMap = RecurringConfig.fromMap(map);
      expect(fromMap.id, equals('rec_1'));
      expect(fromMap.walletId, equals('wallet_1'));
      expect(fromMap.categoryId, equals('cat_1'));
      expect(fromMap.dayOfMonth, equals(15));
    });

    test('copyWith updates walletId and nextRun', () {
      final now = DateTime.now();
      final config = RecurringConfig(
        id: 'rec_2',
        name: 'Tiền nhà',
        amount: 3000000.0,
        type: 'expense',
        frequency: 'monthly',
        interval: 1,
        nextRun: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final updated = config.copyWith(
        walletId: 'wallet_abc',
        amount: 3500000.0,
      );

      expect(updated.walletId, equals('wallet_abc'));
      expect(updated.amount, equals(3500000.0));
      expect(updated.name, equals('Tiền nhà'));
    });
  });

  group('RecurringRepository Database Tests', () {
    late RecurringRepository repo;

    setUp(() {
      repo = RecurringRepository();
    });

    test('creates and retrieves recurring config with walletId and nextRun', () async {
      final customNextRun = DateTime(2026, 10, 1, 9, 0);

      final created = await repo.create(
        categoryId: 'cat_test',
        walletId: 'wallet_test',
        name: 'Lương cố định',
        amount: 20000000.0,
        type: 'income',
        frequency: 'monthly',
        interval: 1,
        dayOfMonth: 1,
        nextRun: customNextRun,
      );

      expect(created.walletId, equals('wallet_test'));
      expect(created.amount, equals(20000000.0));
      expect(created.nextRun, equals(customNextRun));

      final fetched = await repo.getById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.walletId, equals('wallet_test'));
      expect(fetched.name, equals('Lương cố định'));
      expect(fetched.type, equals('income'));

      // Update walletId
      final updated = await repo.update(
        created.id,
        walletId: 'wallet_updated',
        amount: 25000000.0,
      );

      expect(updated.walletId, equals('wallet_updated'));
      expect(updated.amount, equals(25000000.0));

      final fetchedAfterUpdate = await repo.getById(created.id);
      expect(fetchedAfterUpdate!.walletId, equals('wallet_updated'));
      expect(fetchedAfterUpdate.amount, equals(25000000.0));
    });
  });
}
