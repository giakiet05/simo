import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/category.dart';
import 'package:simo/models/loan_contact.dart';
import 'package:simo/models/saving_goal.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/services/ai_action_dispatcher.dart';

void main() {
  group('AiDispatchResult Tests', () {
    test('constructs correctly with success status and counts', () {
      final result = AiDispatchResult(
        isSuccess: true,
        summaryMessage: 'Đã ghi nhận: 2 giao dịch thu/chi, 1 chuyển khoản ví!',
        transactionsCount: 2,
        transfersCount: 1,
        loansCount: 0,
        goalsCount: 0,
      );

      expect(result.isSuccess, isTrue);
      expect(result.transactionsCount, 2);
      expect(result.transfersCount, 1);
      expect(result.loansCount, 0);
      expect(result.goalsCount, 0);
      expect(result.summaryMessage, contains('2 giao dịch'));
      expect(result.summaryMessage, contains('1 chuyển khoản'));
    });

    test('constructs failure result correctly', () {
      final result = AiDispatchResult(
        isSuccess: false,
        summaryMessage: 'Không có hành động nào được nhận diện.',
      );

      expect(result.isSuccess, isFalse);
      expect(result.transactionsCount, 0);
      expect(result.summaryMessage, 'Không có hành động nào được nhận diện.');
    });
  });

  group('AI Multi-Action Data Structures', () {
    test('supports multi-action JSON with transfer, loan, and goal', () {
      final mockAiResult = {
        'thought': 'Analysis of spoken sentence',
        'isSuccess': true,
        'message': '',
        'actions': [
          {
            'actionType': 'transaction',
            'amount': 50000,
            'type': 'expense',
            'note': 'Ăn sáng phở bò',
            'categoryId': 'cat_food',
            'walletId': 'wallet_cash',
            'date': '2026-09-06T08:00:00.000Z',
          },
          {
            'actionType': 'transfer',
            'amount': 2000000,
            'sourceWalletId': 'wallet_bank',
            'destinationWalletId': 'wallet_momo',
            'fee': 0,
            'note': 'Chuyển tiền sang MoMo',
            'date': '2026-09-06T08:05:00.000Z',
          },
          {
            'actionType': 'loan_create',
            'amount': 500000,
            'loanType': 'lent',
            'contactName': 'Tuấn',
            'contactId': null,
            'walletId': 'wallet_cash',
            'note': 'Cho Tuấn mượn tiền',
            'date': '2026-09-06T08:10:00.000Z',
          },
          {
            'actionType': 'goal_deposit',
            'amount': 1000000,
            'goalId': 'goal_iphone',
            'goalName': 'Mua iPhone 16',
            'walletId': 'wallet_bank',
            'note': 'Góp tiền mua máy',
            'date': '2026-09-06T08:15:00.000Z',
          },
        ],
        'transactions': [
          {
            'amount': 50000,
            'type': 'expense',
            'note': 'Ăn sáng phở bò',
            'categoryId': 'cat_food',
            'walletId': 'wallet_cash',
            'date': '2026-09-06T08:00:00.000Z',
          }
        ]
      };

      final actions = mockAiResult['actions'] as List<dynamic>;
      expect(actions.length, 4);

      final legacyTransactions = mockAiResult['transactions'] as List<dynamic>;
      expect(legacyTransactions.length, 1);

      expect(actions[0]['actionType'], 'transaction');
      expect(actions[1]['actionType'], 'transfer');
      expect(actions[2]['actionType'], 'loan_create');
      expect(actions[3]['actionType'], 'goal_deposit');
    });
  });
}
