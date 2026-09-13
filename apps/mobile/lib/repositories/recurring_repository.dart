import 'package:uuid/uuid.dart';
import '../models/recurring_config.dart';
import 'database_helper.dart';

class RecurringRepository {
  final _uuid = const Uuid();

  Future<List<RecurringConfig>> getAll({bool? isActive}) async {
    final db = await DatabaseHelper.instance.database;

    String? where;
    List<dynamic>? whereArgs;

    if (isActive != null) {
      where = 'is_active = ?';
      whereArgs = [isActive ? 1 : 0];
    }

    final maps = await db.query(
      'recurring_configs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => RecurringConfig.fromMap(map)).toList();
  }

  Future<RecurringConfig?> getById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'recurring_configs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return RecurringConfig.fromMap(maps.first);
  }

  Future<RecurringConfig> create({
    required String? categoryId,
    String? walletId,
    required String name,
    required double amount,
    required String type,
    required String frequency,
    required int interval,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? nextRun,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final effectiveNextRun = nextRun ?? _calculateNextRun(
      frequency: frequency,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
    );

    final config = RecurringConfig(
      id: _uuid.v4(),
      categoryId: categoryId,
      walletId: walletId,
      name: name,
      amount: amount,
      type: type,
      frequency: frequency,
      interval: interval,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      nextRun: effectiveNextRun,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final configMap = config.toMap();
    await db.insert('recurring_configs', configMap);
    return config;
  }

  Future<RecurringConfig> update(
    String id, {
    String? categoryId,
    bool clearCategory = false,
    String? walletId,
    bool clearWallet = false,
    String? name,
    double? amount,
    String? type,
    String? frequency,
    int? interval,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? nextRun,
    bool? isActive,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final config = await getById(id);

    if (config == null) {
      throw Exception('Recurring config not found');
    }

    final updatedFrequency = frequency ?? config.frequency;
    final updatedInterval = interval ?? config.interval;
    final updatedDayOfWeek = dayOfWeek ?? config.dayOfWeek;
    final updatedDayOfMonth = dayOfMonth ?? config.dayOfMonth;

    DateTime updatedNextRun = nextRun ?? config.nextRun;
    if (nextRun == null && (frequency != null || interval != null || dayOfWeek != null || dayOfMonth != null)) {
      updatedNextRun = _calculateNextRun(
        frequency: updatedFrequency,
        interval: updatedInterval,
        dayOfWeek: updatedDayOfWeek,
        dayOfMonth: updatedDayOfMonth,
      );
    }

    final updated = config.copyWith(
      categoryId: clearCategory ? null : (categoryId ?? config.categoryId),
      walletId: clearWallet ? null : (walletId ?? config.walletId),
      name: name ?? config.name,
      amount: amount ?? config.amount,
      type: type ?? config.type,
      frequency: updatedFrequency,
      interval: updatedInterval,
      dayOfWeek: updatedDayOfWeek,
      dayOfMonth: updatedDayOfMonth,
      nextRun: updatedNextRun,
      isActive: isActive ?? config.isActive,
      updatedAt: DateTime.now().toUtc(),
    );

    final map = updated.toMap();
    map['synced'] = 0;
    map['updated_at'] = DateTime.now().toUtc().toIso8601String();

    await db.update(
      'recurring_configs',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );

    return updated;
  }

  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'recurring_configs',
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.insert('pending_deletions', {
        'cloud_id': id,
        'table_name': 'recurring_configs',
        'deleted_at': nowIso,
      });
    });
  }

  Future<void> updateNextRun(String id, DateTime nextRun) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'recurring_configs',
      {
        'next_run': nextRun.toIso8601String(),
        'synced': 0,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  DateTime _calculateNextRun({
    required String frequency,
    required int interval,
    int? dayOfWeek,
    int? dayOfMonth,
  }) {
    final now = DateTime.now();

    switch (frequency) {
      case 'daily':
        return DateTime(now.year, now.month, now.day + interval);

      case 'weekly':
        int daysToAdd = interval * 7;
        if (dayOfWeek != null) {
          final targetDay = dayOfWeek % 7;
          final currentDay = now.weekday % 7;
          daysToAdd = (targetDay - currentDay + 7) % 7;
          if (daysToAdd == 0) daysToAdd = 7 * interval;
        }
        return DateTime(now.year, now.month, now.day + daysToAdd);

      case 'monthly':
        int targetDay = dayOfMonth ?? now.day;
        int targetMonth = now.month + interval;
        int targetYear = now.year;

        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear += 1;
        }

        final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        if (targetDay > daysInMonth) {
          targetDay = daysInMonth;
        }

        return DateTime(targetYear, targetMonth, targetDay);

      default:
        return DateTime(now.year, now.month, now.day + 1);
    }
  }
}
