import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/recurring_config.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/recurring_repository.dart';
import 'package:simo/repositories/transaction_repository.dart';
import 'package:simo/repositories/wallet_repository.dart';
import 'package:simo/utils/recurring_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('RecurringConfig Model Tests', () {
    test('serializes and deserializes walletId and daysOfWeek properly', () {
      final now = DateTime(2026, 5, 11);
      final config = RecurringConfig(
        id: 'rec_1',
        categoryId: 'cat_1',
        walletId: 'wallet_1',
        name: 'Company Lunch',
        amount: 50000.0,
        type: 'expense',
        frequency: 'daily',
        interval: 1,
        daysOfWeek: [5, 1, 3, 2, 4, 1],
        nextRun: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = config.toMap();
      expect(map['wallet_id'], equals('wallet_1'));
      expect(map['name'], equals('Company Lunch'));
      expect(map['amount'], equals(50000.0));
      expect(map['days_of_week'], equals('1,2,3,4,5'));

      final fromMap = RecurringConfig.fromMap(map);
      expect(fromMap.id, equals('rec_1'));
      expect(fromMap.walletId, equals('wallet_1'));
      expect(fromMap.categoryId, equals('cat_1'));
      expect(fromMap.daysOfWeek, equals([1, 2, 3, 4, 5]));
    });

    test('falls back to legacy dayOfWeek when daysOfWeek is null on weekly config', () {
      final now = DateTime(2026, 5, 11);
      final sundayConfig = RecurringConfig(
        id: 'rec_legacy_sun',
        name: 'Sunday Coffee',
        amount: 45000,
        type: 'expense',
        frequency: 'weekly',
        interval: 1,
        dayOfWeek: 0,
        nextRun: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(sundayConfig.effectiveDaysOfWeek, equals([7]));
    });

    test('normalizes UTC next_run timestamps to local time on fromMap', () {
      final localMidnight = DateTime(2026, 5, 15, 0, 0, 0);
      final utcIso = localMidnight.toUtc().toIso8601String();

      final fromMap = RecurringConfig.fromMap({
        'id': 'rec_utc',
        'category_id': null,
        'wallet_id': null,
        'name': 'Rent',
        'amount': 3000000.0,
        'type': 'expense',
        'frequency': 'monthly',
        'interval': 1,
        'day_of_week': null,
        'days_of_week': null,
        'day_of_month': 15,
        'next_run': utcIso,
        'is_active': 1,
        'created_at': utcIso,
        'updated_at': utcIso,
      });

      expect(fromMap.nextRun.isUtc, isFalse);
      expect(fromMap.nextRun.year, equals(2026));
      expect(fromMap.nextRun.month, equals(5));
      expect(fromMap.nextRun.day, equals(15));
    });

    test('copyWith updates walletId, daysOfWeek, and clear flags', () {
      final now = DateTime(2026, 5, 11);
      final config = RecurringConfig(
        id: 'rec_2',
        name: 'Lunch',
        amount: 45000.0,
        type: 'expense',
        frequency: 'daily',
        interval: 1,
        daysOfWeek: [1, 2, 3, 4, 5],
        nextRun: now,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final updated = config.copyWith(
        walletId: 'wallet_abc',
        amount: 55000.0,
        clearDaysOfWeek: true,
      );

      expect(updated.walletId, equals('wallet_abc'));
      expect(updated.amount, equals(55000.0));
      expect(updated.daysOfWeek, isNull);
    });
  });

  group('RecurringService Schedule Calculation Tests', () {
    test('daily weekdays-only skips Saturday and Sunday', () {
      // 2026-05-15 is Friday (weekday = 5)
      final friday = DateTime(2026, 5, 15);
      final next = RecurringService.calculateNextRun(
        from: friday,
        frequency: 'daily',
        interval: 1,
        daysOfWeek: RecurringConfig.weekdaysPreset,
      );

      // Should jump directly to Monday 2026-05-18 (weekday = 1)
      expect(next, equals(DateTime(2026, 5, 18)));
      expect(next.weekday, equals(DateTime.monday));
    });

    test('daily weekends-only runs Saturday then Sunday then jumps to next Saturday', () {
      // 2026-05-16 is Saturday (weekday = 6)
      final saturday = DateTime(2026, 5, 16);
      final next1 = RecurringService.calculateNextRun(
        from: saturday,
        frequency: 'daily',
        interval: 1,
        daysOfWeek: RecurringConfig.weekendsPreset,
      );
      expect(next1, equals(DateTime(2026, 5, 17))); // Sunday

      final next2 = RecurringService.calculateNextRun(
        from: next1,
        frequency: 'daily',
        interval: 1,
        daysOfWeek: RecurringConfig.weekendsPreset,
      );
      expect(next2, equals(DateTime(2026, 5, 23))); // Next Saturday
    });

    test('alignToValidRunDate snaps Saturday candidate to Monday for weekdays-only schedule', () {
      final saturday = DateTime(2026, 5, 16);
      final aligned = RecurringService.alignToValidRunDate(
        candidate: saturday,
        frequency: 'daily',
        daysOfWeek: RecurringConfig.weekdaysPreset,
      );
      expect(aligned, equals(DateTime(2026, 5, 18)));
    });

    test('weekly multi-day schedule respects interval > 1 across weeks', () {
      // 2026-05-11 is Monday (weekday = 1)
      final monday = DateTime(2026, 5, 11);
      final next1 = RecurringService.calculateNextRun(
        from: monday,
        frequency: 'weekly',
        interval: 2,
        daysOfWeek: [1, 3, 5],
      );
      // Same week Wednesday
      expect(next1, equals(DateTime(2026, 5, 13)));

      final next2 = RecurringService.calculateNextRun(
        from: next1,
        frequency: 'weekly',
        interval: 2,
        daysOfWeek: [1, 3, 5],
      );
      // Same week Friday
      expect(next2, equals(DateTime(2026, 5, 15)));

      final next3 = RecurringService.calculateNextRun(
        from: next2,
        frequency: 'weekly',
        interval: 2,
        daysOfWeek: [1, 3, 5],
      );
      // 2 weeks after Monday 2026-05-11 => Monday 2026-05-25
      expect(next3, equals(DateTime(2026, 5, 25)));
    });

    test('monthly schedule clamps day 31 to end of shorter months', () {
      final jan31 = DateTime(2026, 1, 31);
      final feb = RecurringService.calculateNextRun(
        from: jan31,
        frequency: 'monthly',
        interval: 1,
        dayOfMonth: 31,
      );
      expect(feb, equals(DateTime(2026, 2, 28)));

      final mar = RecurringService.calculateNextRun(
        from: feb,
        frequency: 'monthly',
        interval: 1,
        dayOfMonth: 31,
      );
      expect(mar, equals(DateTime(2026, 3, 31)));
    });
  });

  group('RecurringRepository and Execution Engine Tests', () {
    late RecurringRepository repo;
    late TransactionRepository txRepo;
    late WalletRepository walletRepo;
    late RecurringService service;

    setUp(() {
      repo = RecurringRepository();
      txRepo = TransactionRepository();
      walletRepo = WalletRepository();
      service = RecurringService(
        recurringRepo: repo,
        walletRepo: walletRepo,
      );
    });

    test('creates and retrieves recurring config with walletId, daysOfWeek, and date-only nextRun', () async {
      final customNextRun = DateTime(2026, 10, 1, 9, 30);

      final created = await repo.create(
        categoryId: 'cat_test',
        walletId: 'wallet_test',
        name: 'Monthly Salary',
        amount: 20000000.0,
        type: 'income',
        frequency: 'monthly',
        interval: 1,
        dayOfMonth: 1,
        nextRun: customNextRun,
      );

      expect(created.walletId, equals('wallet_test'));
      expect(created.amount, equals(20000000.0));
      expect(created.nextRun, equals(DateTime(2026, 10, 1)));

      final updated = await repo.update(
        created.id,
        walletId: 'wallet_updated',
        amount: 25000000.0,
        frequency: 'daily',
        daysOfWeek: [1, 2, 3, 4, 5],
        clearDayOfMonth: true,
      );

      expect(updated.walletId, equals('wallet_updated'));
      expect(updated.amount, equals(25000000.0));
      expect(updated.daysOfWeek, equals([1, 2, 3, 4, 5]));
      expect(updated.dayOfMonth, isNull);

      final fetched = await repo.getById(created.id);
      expect(fetched, isNotNull);
      expect(fetched!.daysOfWeek, equals([1, 2, 3, 4, 5]));
    });

    test('catches up missed weekdays only, skips weekends, stamps exact dates, updates balance, and is idempotent', () async {
      final now = DateTime.now();
      final wallet = Wallet(
        id: 'wallet_lunch_test',
        name: 'Cash',
        type: 'cash',
        initialBalance: 1000000.0,
        currentBalance: 1000000.0,
        color: '#10B981',
        icon: 'wallet',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(wallet);

      // Schedule starts Thu 2026-05-14, weekdays only (Mon-Fri), 50,000 VND each day.
      final config = await repo.create(
        categoryId: null,
        walletId: wallet.id,
        name: 'Company Lunch',
        amount: 50000.0,
        type: 'expense',
        frequency: 'daily',
        interval: 1,
        daysOfWeek: RecurringConfig.weekdaysPreset,
        nextRun: DateTime(2026, 5, 14),
      );

      // Process as of Tue 2026-05-19 (covers Thu 14, Fri 15, skips Sat 16 & Sun 17, covers Mon 18, Tue 19)
      final generated = await service.processRecurringTransactions(
        referenceNow: DateTime(2026, 5, 19, 14, 30),
      );

      expect(generated, equals(4));

      final txs = await txRepo.getAll(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31),
      );
      expect(txs.length, equals(4));

      final txDates = txs
          .map((t) => DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day))
          .toList()
        ..sort();
      expect(
        txDates,
        equals([
          DateTime(2026, 5, 14),
          DateTime(2026, 5, 15),
          DateTime(2026, 5, 18),
          DateTime(2026, 5, 19),
        ]),
      );
      expect(txs.every((t) => t.note == 'Company Lunch'), isTrue);
      expect(txs.every((t) => t.recurringConfigId == config.id), isTrue);

      // Next run must now be Wed 2026-05-20
      final updatedConfig = await repo.getById(config.id);
      expect(updatedConfig!.nextRun, equals(DateTime(2026, 5, 20)));

      // Wallet balance must reflect 4 x 50,000 = 200,000 deducted from 1,000,000
      final updatedWallet = await walletRepo.getWalletById(wallet.id);
      expect(updatedWallet!.currentBalance, equals(800000.0));

      // Re-running on the same day must be idempotent (0 duplicates)
      final secondRun = await service.processRecurringTransactions(
        referenceNow: DateTime(2026, 5, 19, 22, 0),
      );
      expect(secondRun, equals(0));
    });

    test('does not execute weekdays-only schedule on Saturday or Sunday', () async {
      final now = DateTime.now();
      final wallet = Wallet(
        id: 'wallet_weekend_test',
        name: 'Bank',
        type: 'bank',
        initialBalance: 500000.0,
        currentBalance: 500000.0,
        color: '#3B82F6',
        icon: 'bank',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      );
      await walletRepo.createWallet(wallet);

      // Even if nextRun is passed as Saturday 2026-05-16, repo aligns it to Monday 2026-05-18
      final config = await repo.create(
        categoryId: null,
        walletId: wallet.id,
        name: 'Company Lunch',
        amount: 50000.0,
        type: 'expense',
        frequency: 'daily',
        interval: 1,
        daysOfWeek: RecurringConfig.weekdaysPreset,
        nextRun: DateTime(2026, 5, 16),
      );
      expect(config.nextRun, equals(DateTime(2026, 5, 18)));

      final satRun = await service.processRecurringTransactions(
        referenceNow: DateTime(2026, 5, 16, 12, 0),
      );
      final sunRun = await service.processRecurringTransactions(
        referenceNow: DateTime(2026, 5, 17, 12, 0),
      );
      expect(satRun, equals(0));
      expect(sunRun, equals(0));
    });
  });
}
