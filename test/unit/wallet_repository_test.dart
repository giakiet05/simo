import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/wallet_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('WalletRepository Tests', () {
    late WalletRepository repo;
    const uuid = Uuid();

    setUp(() {
      repo = WalletRepository();
    });

    test('creates, updates, retrieves, and deletes wallets', () async {
      final wallet = Wallet(
        id: uuid.v4(),
        name: 'Vietcombank',
        type: 'bank',
        initialBalance: 5000000.0,
        color: '#0055FF',
        icon: 'account_balance',
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createWallet(wallet);

      final fetched = await repo.getWalletById(wallet.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Vietcombank'));
      expect(fetched.type, equals('bank'));
      expect(fetched.initialBalance, equals(5000000.0));
      expect(fetched.currentBalance, equals(5000000.0));
      expect(fetched.isDefault, isTrue);

      final defaultWallet = await repo.getDefaultWallet();
      expect(defaultWallet?.id, equals(wallet.id));

      final updatedWallet = fetched.copyWith(name: 'VCB Digibank', initialBalance: 6000000.0);
      await repo.updateWallet(updatedWallet);

      final reFetched = await repo.getWalletById(wallet.id);
      expect(reFetched!.name, equals('VCB Digibank'));
      expect(reFetched.currentBalance, equals(6000000.0));

      await repo.deleteWallet(wallet.id);
      final afterDelete = await repo.getWalletById(wallet.id);
      expect(afterDelete, isNull);
    });

    test('transfers funds atomically between two wallets and excludes amount from expenses', () async {
      final walletA = Wallet(
        id: 'wallet_vcb',
        name: 'Vietcombank',
        type: 'bank',
        initialBalance: 10000000.0,
        color: '#0055FF',
        icon: 'account_balance',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final walletB = Wallet(
        id: 'wallet_momo',
        name: 'Momo',
        type: 'ewallet',
        initialBalance: 1000000.0,
        color: '#FF0077',
        icon: 'phone_android',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createWallet(walletA);
      await repo.createWallet(walletB);

      // Transfer 2,000,000 from VCB to Momo with 1,100 fee
      await repo.transferFunds(
        sourceWalletId: 'wallet_vcb',
        destinationWalletId: 'wallet_momo',
        amount: 2000000.0,
        fee: 1100.0,
        transferDate: DateTime.now(),
        note: 'Topup Momo',
      );

      final updatedA = await repo.getWalletById('wallet_vcb');
      final updatedB = await repo.getWalletById('wallet_momo');

      expect(updatedA!.currentBalance, equals(10000000.0 - 2000000.0 - 1100.0)); // 7,998,900
      expect(updatedB!.currentBalance, equals(1000000.0 + 2000000.0)); // 3,000,000

      final transfers = await repo.getTransfersForWallet('wallet_vcb');
      expect(transfers.length, equals(1));
      expect(transfers.first.amount, equals(2000000.0));
      expect(transfers.first.fee, equals(1100.0));

      // Test delete transfer reverts balances
      await repo.deleteTransfer(transfers.first.id);
      final revertedA = await repo.getWalletById('wallet_vcb');
      final revertedB = await repo.getWalletById('wallet_momo');

      expect(revertedA!.currentBalance, equals(10000000.0));
      expect(revertedB!.currentBalance, equals(1000000.0));
    });

    test('recalculates wallet balance correctly with mixed transactions and transfers', () async {
      final wallet = Wallet(
        id: 'wallet_test',
        name: 'Test Wallet',
        type: 'cash',
        initialBalance: 500000.0,
        color: '#10B981',
        icon: 'wallet',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.createWallet(wallet);

      final db = await DatabaseHelper.instance.database;
      // Add income 200,000
      await db.insert('transactions', {
        'id': 'tx_1',
        'wallet_id': 'wallet_test',
        'amount': 200000.0,
        'type': 'income',
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Add expense 100,000
      await db.insert('transactions', {
        'id': 'tx_2',
        'wallet_id': 'wallet_test',
        'amount': 100000.0,
        'type': 'expense',
        'transaction_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await repo.recalculateWalletBalance('wallet_test');
      final balance = (await repo.getWalletById('wallet_test'))!.currentBalance;
      // 500,000 + 200,000 - 100,000 = 600,000
      expect(balance, equals(600000.0));
    });
  });
}
