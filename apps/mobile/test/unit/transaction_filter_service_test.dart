import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/category.dart';
import 'package:simo/models/transaction.dart';
import 'package:simo/models/transaction_filter_criteria.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/services/transaction_filter_service.dart';

void main() {
  late TransactionFilterService filterService;

  final now = DateTime.now();
  final catFood = Category(
    id: 'cat-food',
    name: 'Ăn uống',
    type: 'expense',
    createdAt: now,
    updatedAt: now,
  );
  final catSalary = Category(
    id: 'cat-salary',
    name: 'Lương thưởng',
    type: 'income',
    createdAt: now,
    updatedAt: now,
  );

  final walletCash = Wallet(
    id: 'w-cash',
    name: 'Tiền mặt',
    type: 'cash',
    color: '#000000',
    icon: 'wallet',
    createdAt: now,
    updatedAt: now,
  );
  final walletBank = Wallet(
    id: 'w-bank',
    name: 'Techcombank',
    type: 'bank',
    color: '#FF0000',
    icon: 'account_balance',
    createdAt: now,
    updatedAt: now,
  );

  final categoryMap = {'cat-food': catFood, 'cat-salary': catSalary};
  final walletMap = {'w-cash': walletCash, 'w-bank': walletBank};

  final tx1 = Transaction(
    id: 'tx-1',
    categoryId: 'cat-food',
    walletId: 'w-cash',
    amount: 50000.0,
    note: 'Bún bò sáng',
    type: 'expense',
    transactionDate: now,
    createdAt: now,
    updatedAt: now,
  );

  final tx2 = Transaction(
    id: 'tx-2',
    categoryId: 'cat-food',
    walletId: 'w-bank',
    amount: 150000.0,
    note: 'Pizza tối',
    type: 'expense',
    transactionDate: now.subtract(const Duration(days: 35)),
    createdAt: now,
    updatedAt: now,
  );

  final tx3 = Transaction(
    id: 'tx-3',
    categoryId: 'cat-salary',
    walletId: 'w-bank',
    amount: 20000000.0,
    note: 'Lương tháng',
    type: 'income',
    transactionDate: now,
    createdAt: now,
    updatedAt: now,
  );

  final allTransactions = [tx1, tx2, tx3];

  setUp(() {
    filterService = TransactionFilterService();
  });

  group('TransactionFilterService - Filter Tests', () {
    test('filters by selectedWalletIds (multi-wallet)', () {
      final criteria = TransactionFilterCriteria(
        selectedWalletIds: {'w-cash'},
      );
      final result = filterService.applyFilter(
        allTransactions: allTransactions,
        criteria: criteria,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
      expect(result.length, 1);
      expect(result.first.id, 'tx-1');
    });

    test('filters by selectedCategoryIds (multi-category)', () {
      final criteria = TransactionFilterCriteria(
        selectedCategoryIds: {'cat-salary'},
      );
      final result = filterService.applyFilter(
        allTransactions: allTransactions,
        criteria: criteria,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
      expect(result.length, 1);
      expect(result.first.id, 'tx-3');
    });

    test('filters by transaction type (income / expense)', () {
      final criteria = TransactionFilterCriteria(type: 'expense');
      final result = filterService.applyFilter(
        allTransactions: allTransactions,
        criteria: criteria,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
      expect(result.length, 2);
      expect(result.map((e) => e.id), containsAll(['tx-1', 'tx-2']));
    });

    test('filters by amount range (minAmount and maxAmount)', () {
      final criteria = TransactionFilterCriteria(
        minAmount: 100000.0,
        maxAmount: 500000.0,
      );
      final result = filterService.applyFilter(
        allTransactions: allTransactions,
        criteria: criteria,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
      expect(result.length, 1);
      expect(result.first.id, 'tx-2');
    });

    test('filters by timeMode (thisMonth)', () {
      final criteria = TransactionFilterCriteria(
        timeMode: TimeFilterMode.thisMonth,
      );
      final result = filterService.applyFilter(
        allTransactions: allTransactions,
        criteria: criteria,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
      expect(result.length, 2);
      expect(result.map((e) => e.id), containsAll(['tx-1', 'tx-3']));
    });

    test('combines filter criteria with search query (search on filtered data)', () {
      // Filter: type = expense, Search query: 'bun bo'
      final criteria = TransactionFilterCriteria(
        type: 'expense',
        searchQuery: 'bun bo',
      );
      final result = filterService.applyFilter(
        allTransactions: allTransactions,
        criteria: criteria,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
      expect(result.length, 1);
      expect(result.first.id, 'tx-1');
    });
  });
}
