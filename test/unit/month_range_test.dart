import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/transaction.dart';
import 'package:simo/widgets/month_year_picker_modal.dart';

void main() {
  group('MonthRange Tests', () {
    test('Empty transactions defaults to current month', () {
      final range = MonthRange.fromTransactions([]);
      final now = DateTime.now();

      expect(range.endYear, equals(now.year));
      expect(range.endMonth, equals(now.month));
      expect(range.startYear, equals(now.year));
      expect(range.startMonth, equals(now.month));

      expect(range.canGoPrevious(now.year, now.month), isFalse);
      expect(range.canGoNext(now.year, now.month), isFalse);
    });

    test('Earliest transaction sets start boundary and clamps navigation', () {
      final now = DateTime.now();
      final tx1 = Transaction(
        id: '1',
        amount: 100,
        type: 'expense',
        categoryId: 'cat1',
        transactionDate: DateTime(now.year, 2, 10),
        createdAt: DateTime(now.year, 2, 10),
        updatedAt: DateTime(now.year, 2, 10),
      );
      final tx2 = Transaction(
        id: '2',
        amount: 200,
        type: 'income',
        categoryId: 'cat2',
        transactionDate: DateTime(now.year, 5, 15),
        createdAt: DateTime(now.year, 5, 15),
        updatedAt: DateTime(now.year, 5, 15),
      );

      final range = MonthRange.fromTransactions([tx1, tx2]);

      expect(range.startYear, equals(now.year));
      expect(range.startMonth, equals(2));
      expect(range.endYear, equals(now.year));
      expect(range.endMonth, equals(now.month));

      // Month 2 is the start -> cannot go previous
      expect(range.canGoPrevious(now.year, 2), isFalse);
      expect(range.canGoNext(now.year, 2), now.month > 2);

      // Previous from month 3 goes to month 2
      final prev = range.previous(now.year, 3);
      expect(prev.year, equals(now.year));
      expect(prev.month, equals(2));

      // Clamping past start clamps to start
      final clampedPastStart = range.clamp(now.year - 1, 12);
      expect(clampedPastStart.year, equals(now.year));
      expect(clampedPastStart.month, equals(2));

      // Clamping past end clamps to end
      final clampedPastEnd = range.clamp(now.year + 1, 1);
      expect(clampedPastEnd.year, equals(now.year));
      expect(clampedPastEnd.month, equals(now.month));
    });
  });
}
