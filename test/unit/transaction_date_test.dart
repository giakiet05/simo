import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/transaction.dart';

void main() {
  group('Transaction Date and Timestamp Tests', () {
    test('fromMap uses transaction_date if provided', () {
      final map = {
        'id': 'tx-1',
        'category_id': 'cat-1',
        'amount': 100000.0,
        'type': 'expense',
        'transaction_date': '2026-03-15T10:00:00.000',
        'created_at': '2026-07-20T14:30:00.000',
        'updated_at': '2026-08-20T09:15:00.000',
      };

      final tx = Transaction.fromMap(map);

      expect(tx.transactionDate, DateTime.parse('2026-03-15T10:00:00.000'));
      expect(tx.createdAt, DateTime.parse('2026-07-20T14:30:00.000'));
      expect(tx.updatedAt, DateTime.parse('2026-08-20T09:15:00.000'));
    });

    test('fromMap falls back to created_at when transaction_date or updated_at is null (legacy data)', () {
      final legacyMap = {
        'id': 'tx-legacy',
        'category_id': 'cat-1',
        'amount': 50000.0,
        'type': 'expense',
        'created_at': '2026-03-10T08:00:00.000',
      };

      final tx = Transaction.fromMap(legacyMap);

      expect(tx.transactionDate, DateTime.parse('2026-03-10T08:00:00.000'));
      expect(tx.createdAt, DateTime.parse('2026-03-10T08:00:00.000'));
      expect(tx.updatedAt, DateTime.parse('2026-03-10T08:00:00.000'));
    });

    test('toMap serializes all 3 timestamps correctly', () {
      final tx = Transaction(
        id: 'tx-2',
        amount: 200000.0,
        type: 'income',
        transactionDate: DateTime(2026, 3, 1),
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 8, 1),
      );

      final map = tx.toMap();

      expect(map['transaction_date'], tx.transactionDate.toIso8601String());
      expect(map['created_at'], tx.createdAt.toIso8601String());
      expect(map['updated_at'], tx.updatedAt.toIso8601String());
    });

    test('Sorting by transactionDate descending places newer transaction dates first', () {
      final txMarch = Transaction(
        id: 'tx-march',
        amount: 100.0,
        type: 'expense',
        transactionDate: DateTime(2026, 3, 15),
        createdAt: DateTime(2026, 8, 1), // Created in August
        updatedAt: DateTime(2026, 8, 1),
      );

      final txMay = Transaction(
        id: 'tx-may',
        amount: 200.0,
        type: 'expense',
        transactionDate: DateTime(2026, 5, 20),
        createdAt: DateTime(2026, 5, 20),
        updatedAt: DateTime(2026, 5, 20),
      );

      final list = [txMarch, txMay];
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      expect(list.first.id, 'tx-may');
      expect(list.last.id, 'tx-march');
    });
  });
}
