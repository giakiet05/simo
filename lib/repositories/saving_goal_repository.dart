import 'package:sqflite/sqflite.dart';
import '../models/saving_goal.dart';
import '../models/saving_goal_log.dart';
import 'database_helper.dart';

class SavingGoalRepository {
  final DatabaseHelper _dbHelper;

  SavingGoalRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<SavingGoal>> getAll({String? status}) async {
    final db = await _dbHelper.database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (status != null && status.isNotEmpty) {
      where += ' AND status = ?';
      whereArgs.add(status);
    }

    final maps = await db.query(
      'saving_goals',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => SavingGoal.fromMap(m)).toList();
  }

  Future<SavingGoal?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saving_goals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SavingGoal.fromMap(maps.first);
  }

  Future<SavingGoal> create(SavingGoal goal) async {
    final db = await _dbHelper.database;
    await db.insert('saving_goals', goal.toMap());
    return goal;
  }

  Future<SavingGoal> update(SavingGoal goal) async {
    final db = await _dbHelper.database;
    final updated = goal.copyWith(updatedAt: DateTime.now());
    await db.update(
      'saving_goals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    return updated;
  }

  Future<bool> delete(String id) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'saving_goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  Future<SavingGoalLog> addLog({
    required String goalId,
    required double amount,
    required String type,
    required DateTime logDate,
    String? note,
  }) async {
    final db = await _dbHelper.database;
    final log = SavingGoalLog(
      goalId: goalId,
      amount: amount,
      type: type,
      logDate: logDate,
      note: note,
    );

    await db.transaction((txn) async {
      // 1. Insert log
      await txn.insert('saving_goal_logs', log.toMap());

      // 2. Fetch current goal
      final goalMaps = await txn.query(
        'saving_goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );

      if (goalMaps.isNotEmpty) {
        final goal = SavingGoal.fromMap(goalMaps.first);
        double newAmount = goal.currentAmount;

        if (type == 'deposit') {
          newAmount += amount;
        } else if (type == 'withdraw') {
          newAmount = (newAmount - amount).clamp(0.0, double.infinity);
        }

        String newStatus = goal.status;
        if (newAmount >= goal.targetAmount) {
          newStatus = 'completed';
        } else if (goal.status == 'completed' && newAmount < goal.targetAmount) {
          newStatus = 'active';
        }

        await txn.update(
          'saving_goals',
          {
            'current_amount': newAmount,
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [goalId],
        );
      }
    });

    return log;
  }

  Future<bool> deleteLog(String logId) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      final logMaps = await txn.query(
        'saving_goal_logs',
        where: 'id = ?',
        whereArgs: [logId],
      );

      if (logMaps.isEmpty) return false;
      final log = SavingGoalLog.fromMap(logMaps.first);

      // Delete log
      await txn.delete(
        'saving_goal_logs',
        where: 'id = ?',
        whereArgs: [logId],
      );

      // Recalculate goal balance from remaining logs
      final remainingLogs = await txn.query(
        'saving_goal_logs',
        where: 'goal_id = ?',
        whereArgs: [log.goalId],
      );

      double calculatedAmount = 0.0;
      for (final m in remainingLogs) {
        final l = SavingGoalLog.fromMap(m);
        if (l.type == 'deposit') {
          calculatedAmount += l.amount;
        } else if (l.type == 'withdraw') {
          calculatedAmount = (calculatedAmount - l.amount).clamp(0.0, double.infinity);
        }
      }

      final goalMaps = await txn.query(
        'saving_goals',
        where: 'id = ?',
        whereArgs: [log.goalId],
      );

      if (goalMaps.isNotEmpty) {
        final goal = SavingGoal.fromMap(goalMaps.first);
        String newStatus = goal.status;
        if (calculatedAmount >= goal.targetAmount) {
          newStatus = 'completed';
        } else if (goal.status == 'completed' && calculatedAmount < goal.targetAmount) {
          newStatus = 'active';
        }

        await txn.update(
          'saving_goals',
          {
            'current_amount': calculatedAmount,
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [log.goalId],
        );
      }

      return true;
    });
  }

  Future<List<SavingGoalLog>> getLogs(String goalId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'saving_goal_logs',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'log_date DESC, created_at DESC',
    );

    return maps.map((m) => SavingGoalLog.fromMap(m)).toList();
  }
}
