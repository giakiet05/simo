import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/repositories/category_repository.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/transaction_repository.dart';
import 'package:simo/repositories/wallet_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('Transaction Bulk Actions Tests', () {
    late TransactionRepository txRepo;
    late WalletRepository walletRepo;
    late CategoryRepository catRepo;

    setUp(() {
      walletRepo = WalletRepository();
      txRepo = TransactionRepository(walletRepo: walletRepo);
      catRepo = CategoryRepository();
    });

    test('updateWalletMultiple moves transactions and recalculates wallet balances correctly', () async {
      // 1. Create two wallets
      final walletA = Wallet(
        id: 'wallet-a',
        name: 'Tien Mat',
        type: 'cash',
        initialBalance: 1000000.0,
        color: '#10B981',
        icon: 'wallet',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final walletB = Wallet(
        id: 'wallet-b',
        name: 'MoMo',
        type: 'ewallet',
        initialBalance: 500000.0,
        color: '#E91E63',
        icon: 'phone_android',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await walletRepo.createWallet(walletA);
      await walletRepo.createWallet(walletB);

      // 2. Create transactions on Wallet A
      final created = await txRepo.createMultiple([
        {
          'amount': 100000.0,
          'type': 'expense',
          'walletId': 'wallet-a',
          'note': 'Khoan 1',
          'transactionDate': DateTime(2026, 9, 1, 10, 0),
        },
        {
          'amount': 200000.0,
          'type': 'expense',
          'walletId': 'wallet-a',
          'note': 'Khoan 2',
          'transactionDate': DateTime(2026, 9, 2, 11, 0),
        },
        {
          'amount': 300000.0,
          'type': 'expense',
          'walletId': 'wallet-a',
          'note': 'Khoan 3',
          'transactionDate': DateTime(2026, 9, 3, 12, 0),
        },
      ]);

      final tx1 = created[0];
      final tx2 = created[1];
      final tx3 = created[2];

      // Verify initial balances
      final initialA = await walletRepo.getWalletById('wallet-a');
      final initialB = await walletRepo.getWalletById('wallet-b');
      expect(initialA?.currentBalance, 400000.0); // 1M - 600k
      expect(initialB?.currentBalance, 500000.0);

      // 3. Move tx1 and tx2 from Wallet A to Wallet B
      await txRepo.updateWalletMultiple([tx1.id, tx2.id], 'wallet-b');

      // 4. Verify transactions updated
      final updatedTx1 = await txRepo.getById(tx1.id);
      final updatedTx2 = await txRepo.getById(tx2.id);
      final updatedTx3 = await txRepo.getById(tx3.id);

      expect(updatedTx1?.walletId, 'wallet-b');
      expect(updatedTx2?.walletId, 'wallet-b');
      expect(updatedTx3?.walletId, 'wallet-a');

      // 5. Verify recalculated balances
      final finalA = await walletRepo.getWalletById('wallet-a');
      final finalB = await walletRepo.getWalletById('wallet-b');

      // Wallet A now only has tx3 (300k): 1M - 300k = 700k
      expect(finalA?.currentBalance, 700000.0);
      // Wallet B now has tx1 (100k) and tx2 (200k): 500k - 300k = 200k
      expect(finalB?.currentBalance, 200000.0);
    });

    test('updateCategoryMultiple updates categories for all selected transactions', () async {
      final cat1 = await catRepo.create('An uong', 'expense', icon: 'restaurant', color: '#FF5722');
      final cat2 = await catRepo.create('Mua sam', 'expense', icon: 'shopping_cart', color: '#9C27B0');

      final created = await txRepo.createMultiple([
        {
          'amount': 50000.0,
          'type': 'expense',
          'categoryId': cat1.id,
          'transactionDate': DateTime.now(),
        },
        {
          'amount': 80000.0,
          'type': 'expense',
          'categoryId': cat1.id,
          'transactionDate': DateTime.now(),
        },
      ]);

      final tx1 = created[0];
      final tx2 = created[1];

      expect((await txRepo.getById(tx1.id))?.categoryId, cat1.id);
      expect((await txRepo.getById(tx2.id))?.categoryId, cat1.id);

      // Bulk change to cat2
      await txRepo.updateCategoryMultiple([tx1.id, tx2.id], cat2.id);

      expect((await txRepo.getById(tx1.id))?.categoryId, cat2.id);
      expect((await txRepo.getById(tx2.id))?.categoryId, cat2.id);
    });

    test('updateDateMultiple shifts date while preserving original time components', () async {
      final initialDate1 = DateTime(2026, 9, 1, 8, 15, 30);
      final initialDate2 = DateTime(2026, 9, 2, 18, 45, 12);

      final created = await txRepo.createMultiple([
        {
          'amount': 50000.0,
          'type': 'expense',
          'transactionDate': initialDate1,
        },
        {
          'amount': 80000.0,
          'type': 'expense',
          'transactionDate': initialDate2,
        },
      ]);

      final tx1 = created[0];
      final tx2 = created[1];

      final targetDate = DateTime(2026, 10, 20);
      await txRepo.updateDateMultiple([tx1.id, tx2.id], targetDate);

      final updatedTx1 = await txRepo.getById(tx1.id);
      final updatedTx2 = await txRepo.getById(tx2.id);

      // Dates should be 2026-10-20, hours and minutes preserved
      expect(updatedTx1?.transactionDate.year, 2026);
      expect(updatedTx1?.transactionDate.month, 10);
      expect(updatedTx1?.transactionDate.day, 20);
      expect(updatedTx1?.transactionDate.hour, 8);
      expect(updatedTx1?.transactionDate.minute, 15);
      expect(updatedTx1?.transactionDate.second, 30);

      expect(updatedTx2?.transactionDate.year, 2026);
      expect(updatedTx2?.transactionDate.month, 10);
      expect(updatedTx2?.transactionDate.day, 20);
      expect(updatedTx2?.transactionDate.hour, 18);
      expect(updatedTx2?.transactionDate.minute, 45);
      expect(updatedTx2?.transactionDate.second, 12);
    });
  });
}
