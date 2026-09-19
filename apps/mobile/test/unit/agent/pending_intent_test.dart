import 'package:flutter_test/flutter_test.dart';
import 'package:simo/agent/memory/pending_intent_state.dart';

void main() {
  group('PendingIntent State Machine Tests', () {
    test('initializes incomplete intent with missing fields', () {
      final intent = PendingIntent(
        actionType: 'loan_create',
        extractedSlots: {'amount': 200000, 'loanType': 'lent'},
        missingFields: ['contactName'],
        clarificationQuestion: 'Bạn cho ai mượn 200.000đ vậy?',
        createdAt: DateTime.now(),
      );

      expect(intent.isComplete, isFalse);
      expect(intent.missingFields, contains('contactName'));
      expect(intent.extractedSlots['amount'], equals(200000));
    });

    test('mergeSlots resolves missing fields and marks complete', () {
      final initial = PendingIntent(
        actionType: 'loan_create',
        extractedSlots: {'amount': 200000, 'loanType': 'lent'},
        missingFields: ['contactName'],
        clarificationQuestion: 'Bạn cho ai mượn 200.000đ vậy?',
        createdAt: DateTime.now(),
      );

      final updated = initial.mergeSlots({'contactName': 'Nam'});

      expect(updated.isComplete, isTrue);
      expect(updated.missingFields, isEmpty);
      expect(updated.extractedSlots['contactName'], equals('Nam'));
      expect(updated.extractedSlots['amount'], equals(200000));
    });

    test('isExpired detects stale intent after TTL threshold', () {
      final oldTime = DateTime.now().subtract(const Duration(minutes: 10));
      final intent = PendingIntent(
        actionType: 'loan_create',
        extractedSlots: {'amount': 200000},
        missingFields: ['contactName'],
        clarificationQuestion: 'Ai mượn?',
        createdAt: oldTime,
      );

      expect(intent.isExpired(ttl: const Duration(minutes: 5)), isTrue);
      expect(intent.isExpired(ttl: const Duration(minutes: 15)), isFalse);
    });

    test('toJson and fromJson preserves all slot-filling attributes', () {
      final original = PendingIntent(
        actionType: 'transfer',
        extractedSlots: {'amount': 500000, 'sourceWalletId': 'w_cash'},
        missingFields: ['destinationWalletId'],
        clarificationQuestion: 'Chuyển sang ví nào?',
        createdAt: DateTime(2026, 9, 19, 10, 30),
      );

      final json = original.toJson();
      final restored = PendingIntent.fromJson(json);

      expect(restored.actionType, equals(original.actionType));
      expect(restored.extractedSlots, equals(original.extractedSlots));
      expect(restored.missingFields, equals(original.missingFields));
      expect(restored.clarificationQuestion, equals(original.clarificationQuestion));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.isComplete, isFalse);
    });
  });
}
