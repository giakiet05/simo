import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/ai_message.dart';

void main() {
  group('AiMessage Serialization Tests', () {
    test('serializes and deserializes user message correctly', () {
      final message = AiMessage.user('Chi tiêu 100k', turnId: 'turn-123');
      final map = message.toMap();

      expect(map['id'], equals(message.id));
      expect(map['turn_id'], equals('turn-123'));
      expect(map['role'], equals('user'));
      expect(map['content'], equals('Chi tiêu 100k'));
      expect(map['status'], equals('idle'));
      expect(map['actions_json'], isNull);
      expect(map['view_payload_json'], isNull);

      final restored = AiMessage.fromMap(map);
      expect(restored.id, equals(message.id));
      expect(restored.turnId, equals('turn-123'));
      expect(restored.role, equals(AiMessageRole.user));
      expect(restored.content, equals('Chi tiêu 100k'));
      expect(restored.status, equals(AiMessageStatus.idle));
    });

    test('serializes and deserializes assistant message with actions and TransactionListViewPayload', () {
      final now = DateTime(2026, 9, 30, 10, 0, 0);
      final payload = TransactionListViewPayload(
        title: 'Giao dịch hôm nay',
        totalAmount: 150000.0,
        period: '30/09/2026',
        transactions: [
          TransactionItemViewData(
            id: 'tx-1',
            amount: 50000.0,
            type: 'expense',
            note: 'Cà phê sáng',
            categoryName: 'Ăn uống',
            categoryIcon: 'coffee',
            categoryColor: '#FF5722',
            walletName: 'Ví tiền mặt',
            date: now,
          ),
        ],
      );

      final action = AiExecutedAction(
        actionType: 'transaction_create',
        title: 'Chi tiêu',
        amount: 50000.0,
        subtitle: 'Ăn uống - Ví tiền mặt',
        date: now,
        isSuccess: true,
      );

      final message = AiMessage.assistant(
        content: 'Đã thêm giao dịch',
        turnId: 'turn-999',
        actions: [action],
        viewPayload: payload,
      );

      final map = message.toMap();
      expect(map['turn_id'], equals('turn-999'));
      expect(map['actions_json'], isNotNull);
      expect(map['view_payload_json'], isNotNull);

      final restored = AiMessage.fromMap(map);
      expect(restored.turnId, equals('turn-999'));
      expect(restored.role, equals(AiMessageRole.assistant));
      expect(restored.actions.length, equals(1));
      expect(restored.actions.first.title, equals('Chi tiêu'));
      expect(restored.actions.first.amount, equals(50000.0));

      expect(restored.viewPayload, isA<TransactionListViewPayload>());
      final restoredPayload = restored.viewPayload as TransactionListViewPayload;
      expect(restoredPayload.title, equals('Giao dịch hôm nay'));
      expect(restoredPayload.totalAmount, equals(150000.0));
      expect(restoredPayload.transactions.length, equals(1));
      expect(restoredPayload.transactions.first.note, equals('Cà phê sáng'));
    });

    test('serializes and deserializes WalletSummaryViewPayload', () {
      final payload = WalletSummaryViewPayload(
        totalNetWorth: 25000000.0,
        wallets: [
          WalletItemViewData(
            id: 'w-1',
            name: 'Ví tiền mặt',
            type: 'cash',
            balance: 5000000.0,
            icon: 'wallet',
          ),
          WalletItemViewData(
            id: 'w-2',
            name: 'Techcombank',
            type: 'bank',
            balance: 20000000.0,
            icon: 'account_balance',
          ),
        ],
      );

      final map = payload.toMap();
      final restored = AiViewPayload.fromMap(map) as WalletSummaryViewPayload?;
      expect(restored, isNotNull);
      expect(restored!.totalNetWorth, equals(25000000.0));
      expect(restored.wallets.length, equals(2));
      expect(restored.wallets[1].name, equals('Techcombank'));
    });

    test('serializes and deserializes BudgetProgressViewPayload', () {
      final payload = BudgetProgressViewPayload(
        month: '09/2026',
        totalLimit: 10000000.0,
        totalSpent: 4500000.0,
        totalPercentage: 0.45,
        categories: [
          CategoryBudgetItemViewData(
            categoryId: 'c-1',
            categoryName: 'Ăn uống',
            categoryIcon: 'restaurant',
            limitAmount: 4000000.0,
            spentAmount: 2000000.0,
            percentage: 0.5,
          ),
        ],
      );

      final map = payload.toMap();
      final restored = AiViewPayload.fromMap(map) as BudgetProgressViewPayload?;
      expect(restored, isNotNull);
      expect(restored!.month, equals('09/2026'));
      expect(restored.totalSpent, equals(4500000.0));
      expect(restored.categories.first.categoryName, equals('Ăn uống'));
    });

    test('serializes and deserializes DebtLedgerViewPayload and SavingGoalsViewPayload', () {
      final debtPayload = DebtLedgerViewPayload(
        totalReceivable: 500000.0,
        totalPayable: 200000.0,
        contacts: [
          DebtContactItemViewData(
            id: 'd-1',
            contactName: 'Nam',
            type: 'lent',
            remainingAmount: 500000.0,
          ),
        ],
      );

      final debtRestored = AiViewPayload.fromMap(debtPayload.toMap()) as DebtLedgerViewPayload?;
      expect(debtRestored, isNotNull);
      expect(debtRestored!.totalReceivable, equals(500000.0));
      expect(debtRestored.contacts.first.contactName, equals('Nam'));

      final goalPayload = SavingGoalsViewPayload(
        goals: [
          SavingGoalItemViewData(
            id: 'g-1',
            name: 'Mua xe mới',
            targetAmount: 50000000.0,
            currentAmount: 15000000.0,
            percentage: 0.3,
            targetDate: DateTime(2026, 12, 31),
          ),
        ],
      );

      final goalRestored = AiViewPayload.fromMap(goalPayload.toMap()) as SavingGoalsViewPayload?;
      expect(goalRestored, isNotNull);
      expect(goalRestored!.goals.first.name, equals('Mua xe mới'));
      expect(goalRestored.goals.first.currentAmount, equals(15000000.0));
    });
  });
}
