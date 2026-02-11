import '../repositories/recurring_repository.dart';
import '../repositories/transaction_repository.dart';

class RecurringService {
  final RecurringRepository _recurringRepo = RecurringRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  Future<void> processRecurringTransactions() async {
    final configs = await _recurringRepo.getAll(isActive: true);
    final now = DateTime.now();

    for (var config in configs) {
      if (config.nextRun.isBefore(now) ||
          config.nextRun.isAtSameMomentAs(now)) {
        await _transactionRepo.createMultiple([
          {
            'categoryId': config.categoryId,
            'recurringConfigId': config.id,
            'amount': config.amount,
            'formula': null,
            'note': 'Auto-generated from: ${config.name}',
            'type': config.type,
          }
        ]);

        final nextRun = _calculateNextRun(
          from: config.nextRun,
          frequency: config.frequency,
          interval: config.interval,
          dayOfWeek: config.dayOfWeek,
          dayOfMonth: config.dayOfMonth,
        );

        await _recurringRepo.updateNextRun(config.id, nextRun);
      }
    }
  }

  DateTime _calculateNextRun({
    required DateTime from,
    required String frequency,
    required int interval,
    int? dayOfWeek,
    int? dayOfMonth,
  }) {
    switch (frequency) {
      case 'daily':
        return DateTime(from.year, from.month, from.day + interval);

      case 'weekly':
        int daysToAdd = interval * 7;
        if (dayOfWeek != null) {
          final targetDay = dayOfWeek % 7;
          final currentDay = from.weekday % 7;
          daysToAdd = (targetDay - currentDay + 7) % 7;
          if (daysToAdd == 0) daysToAdd = 7 * interval;
        }
        return DateTime(from.year, from.month, from.day + daysToAdd);

      case 'monthly':
        int targetDay = dayOfMonth ?? from.day;
        int targetMonth = from.month + interval;
        int targetYear = from.year;

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
        return DateTime(from.year, from.month, from.day + 1);
    }
  }
}
