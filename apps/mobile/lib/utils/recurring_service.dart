import 'package:uuid/uuid.dart';
import '../models/recurring_config.dart';
import '../repositories/database_helper.dart';
import '../repositories/recurring_repository.dart';
import '../repositories/wallet_repository.dart';

/// Executes due recurring transaction schedules and calculates subsequent run dates.
class RecurringService {
  static const int maxCatchUpRunsPerConfig = 365;
  static bool _isProcessing = false;

  final RecurringRepository _recurringRepo;
  final WalletRepository _walletRepo;
  final DatabaseHelper _dbHelper;
  final Uuid _uuid;

  RecurringService({
    RecurringRepository? recurringRepo,
    WalletRepository? walletRepo,
    DatabaseHelper? dbHelper,
  })  : _recurringRepo = recurringRepo ?? RecurringRepository(),
        _walletRepo = walletRepo ?? WalletRepository(),
        _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _uuid = const Uuid();

  /// Normalizes any local or UTC [DateTime] to midnight on its local calendar date.
  ///
  /// @param dt Input timestamp (local or UTC).
  /// @returns Local [DateTime] at 00:00:00 of the same local calendar day.
  static DateTime dateOnlyLocal(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Aligns a candidate run date forward to the nearest valid active weekday when weekday filtering applies.
  ///
  /// @param candidate Proposed local date.
  /// @param frequency Schedule frequency ('daily', 'weekly', 'monthly', 'yearly').
  /// @param daysOfWeek Optional ISO weekday filter (1=Mon..7=Sun).
  /// @param dayOfWeek Legacy single day-of-week value (0=Sun..6=Sat).
  /// @returns Local midnight date guaranteed to match allowed weekdays.
  static DateTime alignToValidRunDate({
    required DateTime candidate,
    required String frequency,
    List<int>? daysOfWeek,
    int? dayOfWeek,
  }) {
    var d = dateOnlyLocal(candidate);
    List<int>? allowedDays = RecurringConfig.normalizeDaysOfWeek(daysOfWeek);
    if (allowedDays == null && frequency == 'weekly' && dayOfWeek != null) {
      allowedDays = [RecurringConfig.legacyDayOfWeekToIso(dayOfWeek)];
    }

    if ((frequency == 'daily' || frequency == 'weekly') &&
        allowedDays != null &&
        allowedDays.isNotEmpty &&
        allowedDays.length < 7) {
      for (int i = 0; i < 7; i++) {
        if (allowedDays.contains(d.weekday)) {
          return d;
        }
        d = DateTime(d.year, d.month, d.day + 1);
      }
    }

    return d;
  }

  /// Computes the next scheduled local midnight date strictly after [from].
  ///
  /// @param from The date of the run that just executed.
  /// @param frequency Schedule frequency ('daily', 'weekly', 'monthly', 'yearly').
  /// @param interval Positive recurrence interval (>= 1).
  /// @param dayOfWeek Legacy single weekday (0=Sun..6=Sat) used if [daysOfWeek] is empty on weekly schedules.
  /// @param daysOfWeek Optional ISO weekdays (1=Mon..7=Sun) to apply for daily or weekly schedules.
  /// @param dayOfMonth Optional target day of month (1..31) for monthly/yearly schedules.
  /// @returns Local midnight [DateTime] strictly after [from].
  static DateTime calculateNextRun({
    required DateTime from,
    required String frequency,
    required int interval,
    int? dayOfWeek,
    List<int>? daysOfWeek,
    int? dayOfMonth,
  }) {
    final safeInterval = interval < 1 ? 1 : interval;
    final base = dateOnlyLocal(from);
    final allowedDays = RecurringConfig.normalizeDaysOfWeek(daysOfWeek);

    switch (frequency) {
      case 'daily':
        if (allowedDays == null || allowedDays.isEmpty || allowedDays.length == 7) {
          return DateTime(base.year, base.month, base.day + safeInterval);
        }
        var next = DateTime(base.year, base.month, base.day + safeInterval);
        for (int i = 0; i < 7; i++) {
          if (allowedDays.contains(next.weekday)) {
            return next;
          }
          next = DateTime(next.year, next.month, next.day + 1);
        }
        return next;

      case 'weekly':
        final effectiveDays = allowedDays ??
            (dayOfWeek != null
                ? [RecurringConfig.legacyDayOfWeekToIso(dayOfWeek)]
                : [base.weekday]);

        // Check for another active weekday later in the same ISO week (Mon=1..Sun=7).
        final laterInSameWeek = effectiveDays.where((d) => d > base.weekday).toList();
        if (laterInSameWeek.isNotEmpty) {
          return DateTime(base.year, base.month, base.day + (laterInSameWeek.first - base.weekday));
        }

        // Jump forward by safeInterval ISO weeks to the first active weekday.
        final mondayOfBaseWeek = DateTime(base.year, base.month, base.day - (base.weekday - 1));
        final targetMonday = DateTime(
          mondayOfBaseWeek.year,
          mondayOfBaseWeek.month,
          mondayOfBaseWeek.day + (7 * safeInterval),
        );
        return DateTime(
          targetMonday.year,
          targetMonday.month,
          targetMonday.day + (effectiveDays.first - 1),
        );

      case 'monthly':
        final targetDay = dayOfMonth ?? base.day;
        final totalMonths = (base.year * 12 + (base.month - 1)) + safeInterval;
        final targetYear = totalMonths ~/ 12;
        final targetMonth = (totalMonths % 12) + 1;
        final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final clampedDay = targetDay.clamp(1, daysInMonth);
        return DateTime(targetYear, targetMonth, clampedDay);

      case 'yearly':
        final targetYear = base.year + safeInterval;
        final daysInMonth = DateTime(targetYear, base.month + 1, 0).day;
        final targetDay = (dayOfMonth ?? base.day).clamp(1, daysInMonth);
        return DateTime(targetYear, base.month, targetDay);

      default:
        return DateTime(base.year, base.month, base.day + safeInterval);
    }
  }

  /// Processes all active recurring configurations due on or before [referenceNow] (defaults to local today).
  /// Catches up all missed occurrences atomically per config and stamps each transaction with its actual
  /// scheduled calendar date.
  ///
  /// @param referenceNow Optional override for current time (used in unit tests).
  /// @returns Total number of auto-generated transactions created during this run.
  Future<int> processRecurringTransactions({DateTime? referenceNow}) async {
    if (_isProcessing) return 0;
    _isProcessing = true;

    int totalGenerated = 0;
    final affectedWalletIds = <String>{};

    try {
      final configs = await _recurringRepo.getAll(isActive: true);
      if (configs.isEmpty) return 0;

      final today = dateOnlyLocal(referenceNow ?? DateTime.now());
      final db = await _dbHelper.database;
      final defaultWallet = await _walletRepo.getDefaultWallet();

      for (final config in configs) {
        final rawScheduled = dateOnlyLocal(config.nextRun);
        var scheduled = alignToValidRunDate(
          candidate: rawScheduled,
          frequency: config.frequency,
          daysOfWeek: config.daysOfWeek,
          dayOfWeek: config.dayOfWeek,
        );

        if (scheduled.isAfter(today)) {
          // Persist snapped date if an existing config's nextRun landed on an excluded weekday.
          if (scheduled != rawScheduled) {
            await _recurringRepo.updateNextRun(config.id, scheduled);
          }
          continue;
        }

        final dueDates = <DateTime>[];
        while (!scheduled.isAfter(today) && dueDates.length < maxCatchUpRunsPerConfig) {
          dueDates.add(scheduled);
          scheduled = calculateNextRun(
            from: scheduled,
            frequency: config.frequency,
            interval: config.interval,
            dayOfWeek: config.dayOfWeek,
            daysOfWeek: config.daysOfWeek,
            dayOfMonth: config.dayOfMonth,
          );
        }

        if (dueDates.isEmpty) continue;

        final targetWalletId = config.walletId ?? defaultWallet?.id;
        final nowUtcIso = DateTime.now().toUtc().toIso8601String();

        // Atomically insert all caught-up transactions and advance next_run so partial crashes
        // can never generate duplicate transactions.
        await db.transaction((txn) async {
          for (final dueDate in dueDates) {
            await txn.insert('transactions', {
              'id': _uuid.v4(),
              'category_id': config.categoryId,
              'recurring_config_id': config.id,
              'wallet_id': targetWalletId,
              'amount': config.amount,
              'formula': null,
              'note': config.name,
              'type': config.type,
              'transaction_date': dueDate.toIso8601String(),
              'synced': 0,
              'created_at': nowUtcIso,
              'updated_at': nowUtcIso,
            });
          }

          await txn.update(
            'recurring_configs',
            {
              'next_run': scheduled.toIso8601String(),
              'synced': 0,
              'updated_at': nowUtcIso,
            },
            where: 'id = ?',
            whereArgs: [config.id],
          );
        });

        totalGenerated += dueDates.length;
        if (targetWalletId != null) {
          affectedWalletIds.add(targetWalletId);
        }
      }

      for (final walletId in affectedWalletIds) {
        await _walletRepo.recalculateWalletBalance(walletId);
      }

      return totalGenerated;
    } finally {
      _isProcessing = false;
    }
  }
}
