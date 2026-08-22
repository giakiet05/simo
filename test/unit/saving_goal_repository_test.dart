import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/saving_goal.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/saving_goal_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('SavingGoalRepository Tests', () {
    late SavingGoalRepository repo;

    setUp(() {
      repo = SavingGoalRepository();
    });

    test('creates, updates, retrieves, and deletes saving goals', () async {
      final goal = SavingGoal(
        name: 'Mua Xe Máy',
        targetAmount: 40000000,
        color: '#2196F3',
        icon: 'motorcycle',
        targetDate: DateTime(2026, 12, 31),
      );

      final created = await repo.create(goal);
      expect(created.id, equals(goal.id));

      final fetched = await repo.getById(goal.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Mua Xe Máy'));
      expect(fetched.targetAmount, equals(40000000));
      expect(fetched.currentAmount, equals(0));
      expect(fetched.isCompleted, isFalse);

      final updated = await repo.update(fetched.copyWith(name: 'Mua Xe SH'));
      expect(updated.name, equals('Mua Xe SH'));

      final all = await repo.getAll();
      expect(all.length, equals(1));

      final deleted = await repo.delete(goal.id);
      expect(deleted, isTrue);

      final empty = await repo.getAll();
      expect(empty.isEmpty, isTrue);
    });

    test('deposits and withdraws funds with atomic current_amount updates and auto-completion', () async {
      final goal = SavingGoal(
        name: 'Quỹ Du Lịch Nhật Bản',
        targetAmount: 50000000,
      );
      await repo.create(goal);

      // 1. Deposit 20,000,000
      await repo.addLog(
        goalId: goal.id,
        amount: 20000000,
        type: 'deposit',
        logDate: DateTime(2026, 8, 22),
        note: 'Tiền thưởng dự án',
      );

      var updatedGoal = await repo.getById(goal.id);
      expect(updatedGoal!.currentAmount, equals(20000000));
      expect(updatedGoal.remainingAmount, equals(30000000));
      expect(updatedGoal.progressPercentage, equals(0.4));
      expect(updatedGoal.status, equals('active'));

      // 2. Deposit remaining 30,000,000 to reach 100%
      await repo.addLog(
        goalId: goal.id,
        amount: 30000000,
        type: 'deposit',
        logDate: DateTime(2026, 8, 25),
        note: 'Lương tháng 8',
      );

      updatedGoal = await repo.getById(goal.id);
      expect(updatedGoal!.currentAmount, equals(50000000));
      expect(updatedGoal.isCompleted, isTrue);
      expect(updatedGoal.status, equals('completed'));

      // 3. Withdraw 10,000,000
      await repo.addLog(
        goalId: goal.id,
        amount: 10000000,
        type: 'withdraw',
        logDate: DateTime(2026, 9, 1),
        note: 'Đặt cọc vé máy bay',
      );

      updatedGoal = await repo.getById(goal.id);
      expect(updatedGoal!.currentAmount, equals(40000000));
      expect(updatedGoal.isCompleted, isFalse);
      expect(updatedGoal.status, equals('active'));

      // 4. Verify logs
      final logs = await repo.getLogs(goal.id);
      expect(logs.length, equals(3));
      expect(logs.first.type, equals('withdraw'));
      expect(logs.first.amount, equals(10000000));
    });
  });
}
