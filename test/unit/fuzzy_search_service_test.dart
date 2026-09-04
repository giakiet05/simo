import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/category.dart';
import 'package:simo/models/transaction.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/services/fuzzy_search_service.dart';

void main() {
  late FuzzySearchService service;

  setUp(() {
    service = FuzzySearchService();
  });

  group('FuzzySearchService - normalizeVietnamese', () {
    test('converts accented Vietnamese characters to ASCII lowercase', () {
      expect(service.normalizeVietnamese('Ăn uống'), 'an uong');
      expect(service.normalizeVietnamese('Bún bò Huế'), 'bun bo hue');
      expect(service.normalizeVietnamese('Đổ xăng xe máy'), 'do xang xe may');
      expect(service.normalizeVietnamese('Cà phê đá'), 'ca phe da');
      expect(service.normalizeVietnamese('TiỀn ThƯởNg'), 'tien thuong');
    });

    test('handles empty or whitespace strings', () {
      expect(service.normalizeVietnamese(''), '');
      expect(service.normalizeVietnamese('   '), '');
    });
  });

  group('FuzzySearchService - tryParseShorthandAmount', () {
    test('parses k / nghin suffixes correctly', () {
      expect(service.tryParseShorthandAmount('50k'), 50000.0);
      expect(service.tryParseShorthandAmount('50.5k'), 50500.0);
      expect(service.tryParseShorthandAmount('200nghin'), 200000.0);
      expect(service.tryParseShorthandAmount('200 nghìn'), 200000.0);
    });

    test('parses tr / trieu / m suffixes correctly', () {
      expect(service.tryParseShorthandAmount('1.5tr'), 1500000.0);
      expect(service.tryParseShorthandAmount('2tr'), 2000000.0);
      expect(service.tryParseShorthandAmount('1.5m'), 1500000.0);
      expect(service.tryParseShorthandAmount('2 trieu'), 2000000.0);
      expect(service.tryParseShorthandAmount('2 triệu'), 2000000.0);
    });

    test('parses plain numbers correctly', () {
      expect(service.tryParseShorthandAmount('50000'), 50000.0);
      expect(service.tryParseShorthandAmount('50,000'), 50000.0);
      expect(service.tryParseShorthandAmount('50.000'), 50000.0);
    });

    test('returns null for non-amount strings', () {
      expect(service.tryParseShorthandAmount('bun bo'), isNull);
      expect(service.tryParseShorthandAmount('tien luong'), isNull);
      expect(service.tryParseShorthandAmount(''), isNull);
    });
  });

  group('FuzzySearchService - Multi-field search', () {
    final fixedNow = DateTime(2026, 9, 4, 12, 0); // Friday
    final catFood = Category(
      id: 'cat-food',
      name: 'Ăn uống',
      type: 'expense',
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );
    final catSalary = Category(
      id: 'cat-salary',
      name: 'Lương thưởng',
      type: 'income',
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    final walletCash = Wallet(
      id: 'w-cash',
      name: 'Tiền mặt',
      type: 'cash',
      color: '#000000',
      icon: 'wallet',
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );
    final walletBank = Wallet(
      id: 'w-bank',
      name: 'Techcombank',
      type: 'bank',
      color: '#FF0000',
      icon: 'account_balance',
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    final tx1 = Transaction(
      id: 'tx-1',
      categoryId: 'cat-food',
      walletId: 'w-cash',
      amount: 50000.0,
      note: 'Bún bò sáng',
      type: 'expense',
      transactionDate: DateTime(2026, 9, 4, 8, 30), // Today (Friday)
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    final tx2 = Transaction(
      id: 'tx-2',
      categoryId: 'cat-food',
      walletId: 'w-bank',
      amount: 150000.0,
      note: 'Pizza tối',
      type: 'expense',
      transactionDate: DateTime(2026, 9, 3, 19, 0), // Yesterday (Thursday)
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    final tx3 = Transaction(
      id: 'tx-3',
      categoryId: 'cat-salary',
      walletId: 'w-bank',
      amount: 15000000.0,
      note: 'Thưởng quý 3',
      type: 'income',
      transactionDate: DateTime(2026, 8, 15, 10, 0), // Last month
      createdAt: fixedNow,
      updatedAt: fixedNow,
    );

    final transactions = [tx1, tx2, tx3];
    final categoryMap = {'cat-food': catFood, 'cat-salary': catSalary};
    final walletMap = {'w-cash': walletCash, 'w-bank': walletBank};

    test('returns original list when query is empty', () {
      final results = service.search(
        transactions: transactions,
        query: '',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(results, transactions);
    });

    test('finds transactions by unaccented note match', () {
      final results = service.search(
        transactions: transactions,
        query: 'bun bo',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(results.length, 1);
      expect(results.first.id, 'tx-1');
    });

    test('finds transactions by unaccented category name', () {
      final results = service.search(
        transactions: transactions,
        query: 'an uong',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(results.length, 2);
      expect(results.map((e) => e.id), containsAll(['tx-1', 'tx-2']));
    });

    test('finds transactions by unaccented wallet name', () {
      final results = service.search(
        transactions: transactions,
        query: 'tien mat',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(results.length, 1);
      expect(results.first.id, 'tx-1');
    });

    test('finds transactions by shorthand amount', () {
      final results = service.search(
        transactions: transactions,
        query: '50k',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(results.length, 1);
      expect(results.first.id, 'tx-1');

      final resultsMillions = service.search(
        transactions: transactions,
        query: '15tr',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(resultsMillions.length, 1);
      expect(resultsMillions.first.id, 'tx-3');
    });

    test('finds transactions by date formats: 4/9, 04/09, 04/09/2026', () {
      final res1 = service.search(
        transactions: transactions,
        query: '4/9',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(res1.length, 1);
      expect(res1.first.id, 'tx-1');

      final res2 = service.search(
        transactions: transactions,
        query: '04/09/2026',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(res2.length, 1);
      expect(res2.first.id, 'tx-1');
    });

    test('finds transactions by relative date: hom nay, hom qua', () {
      final resToday = service.search(
        transactions: transactions,
        query: 'hom nay',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(resToday.length, 1);
      expect(resToday.first.id, 'tx-1');

      final resYesterday = service.search(
        transactions: transactions,
        query: 'hom qua',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(resYesterday.length, 1);
      expect(resYesterday.first.id, 'tx-2');
    });

    test('finds transactions by day of week: thu sau (Friday)', () {
      final resFriday = service.search(
        transactions: transactions,
        query: 'thu sau',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(resFriday.length, 1);
      expect(resFriday.first.id, 'tx-1');
    });

    test('combines search terms: note + date, amount + relative date, wallet + amount', () {
      // note + date
      final res1 = service.search(
        transactions: transactions,
        query: 'bun bo 4/9',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(res1.length, 1);
      expect(res1.first.id, 'tx-1');

      // amount + relative date
      final res2 = service.search(
        transactions: transactions,
        query: '50k hom nay',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(res2.length, 1);
      expect(res2.first.id, 'tx-1');

      // wallet + amount
      final res3 = service.search(
        transactions: transactions,
        query: 'tien mat 50k',
        categoryMap: categoryMap,
        walletMap: walletMap,
        currentTime: fixedNow,
      );
      expect(res3.length, 1);
      expect(res3.first.id, 'tx-1');
    });
  });
}
