import 'package:uuid/uuid.dart';
import '../models/recurring_config.dart';
import '../utils/recurring_service.dart';
import 'database_helper.dart';

/// Data access repository for managing [RecurringConfig] rows in local SQLite.
class RecurringRepository {
  final _uuid = const Uuid();

  /// Retrieves all recurring configurations, optionally filtered by active status.
  ///
  /// @param isActive Optional boolean filter for active/paused schedules.
  /// @returns List of [RecurringConfig] ordered newest first.
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

  /// Retrieves a single recurring configuration by its UUID.
  ///
  /// @param id UUID of the recurring configuration.
  /// @returns [RecurringConfig] or null if not found.
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

  /// Creates and persists a new recurring configuration, aligning its initial [nextRun]
  /// to the configured weekday filter when applicable.
  Future<RecurringConfig> create({
    required String? categoryId,
    String? walletId,
    required String name,
    required double amount,
    required String type,
    required String frequency,
    required int interval,
    int? dayOfWeek,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    DateTime? nextRun,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final normalizedDays = RecurringConfig.normalizeDaysOfWeek(daysOfWeek);

    final DateTime effectiveNextRun;
    if (nextRun != null) {
      effectiveNextRun = RecurringService.alignToValidRunDate(
        candidate: nextRun,
        frequency: frequency,
        daysOfWeek: normalizedDays,
        dayOfWeek: dayOfWeek,
      );
    } else {
      effectiveNextRun = RecurringService.calculateNextRun(
        from: now,
        frequency: frequency,
        interval: interval,
        dayOfWeek: dayOfWeek,
        daysOfWeek: normalizedDays,
        dayOfMonth: dayOfMonth,
      );
    }

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
      daysOfWeek: normalizedDays,
      dayOfMonth: dayOfMonth,
      nextRun: effectiveNextRun,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final configMap = config.toMap();
    configMap['synced'] = 0;
    await db.insert('recurring_configs', configMap);
    return config;
  }

  /// Updates an existing recurring configuration and marks it unsynced.
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
    bool clearDayOfWeek = false,
    List<int>? daysOfWeek,
    bool clearDaysOfWeek = false,
    int? dayOfMonth,
    bool clearDayOfMonth = false,
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
    final updatedDayOfWeek = clearDayOfWeek ? null : (dayOfWeek ?? config.dayOfWeek);
    final updatedDaysOfWeek = clearDaysOfWeek
        ? null
        : (daysOfWeek != null
            ? RecurringConfig.normalizeDaysOfWeek(daysOfWeek)
            : config.daysOfWeek);
    final updatedDayOfMonth = clearDayOfMonth ? null : (dayOfMonth ?? config.dayOfMonth);

    final scheduleChanged = frequency != null ||
        interval != null ||
        dayOfWeek != null ||
        clearDayOfWeek ||
        daysOfWeek != null ||
        clearDaysOfWeek ||
        dayOfMonth != null ||
        clearDayOfMonth;

    DateTime updatedNextRun;
    if (nextRun != null) {
      updatedNextRun = RecurringService.alignToValidRunDate(
        candidate: nextRun,
        frequency: updatedFrequency,
        daysOfWeek: updatedDaysOfWeek,
        dayOfWeek: updatedDayOfWeek,
      );
    } else if (scheduleChanged) {
      updatedNextRun = RecurringService.alignToValidRunDate(
        candidate: config.nextRun,
        frequency: updatedFrequency,
        daysOfWeek: updatedDaysOfWeek,
        dayOfWeek: updatedDayOfWeek,
      );
    } else {
      updatedNextRun = config.nextRun;
    }

    final nowUtc = DateTime.now().toUtc();
    final updated = config.copyWith(
      categoryId: categoryId,
      clearCategoryId: clearCategory,
      walletId: walletId,
      clearWalletId: clearWallet,
      name: name ?? config.name,
      amount: amount ?? config.amount,
      type: type ?? config.type,
      frequency: updatedFrequency,
      interval: updatedInterval,
      dayOfWeek: updatedDayOfWeek,
      clearDayOfWeek: clearDayOfWeek,
      daysOfWeek: updatedDaysOfWeek,
      clearDaysOfWeek: clearDaysOfWeek || updatedDaysOfWeek == null,
      dayOfMonth: updatedDayOfMonth,
      clearDayOfMonth: clearDayOfMonth,
      nextRun: updatedNextRun,
      isActive: isActive ?? config.isActive,
      updatedAt: nowUtc,
    );

    final map = updated.toMap();
    map['synced'] = 0;
    map['updated_at'] = nowUtc.toIso8601String();

    await db.update(
      'recurring_configs',
      map,
      where: 'id = ?',
      whereArgs: [id],
    );

    return updated;
  }

  /// Deletes a recurring configuration, unlinks associated transactions, and records a sync tombstone.
  ///
  /// @param id UUID of the recurring configuration to delete.
  Future<void> delete(String id) async {
    final db = await DatabaseHelper.instance.database;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      // Nullify recurring_config_id on associated transactions
      await txn.update(
        'transactions',
        {'recurring_config_id': null, 'synced': 0, 'updated_at': nowIso},
        where: 'recurring_config_id = ?',
        whereArgs: [id],
      );

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

  /// Advances the [nextRun] date of a recurring configuration and marks it unsynced.
  ///
  /// @param id UUID of the recurring configuration.
  /// @param nextRun Next local scheduled run date.
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
}
