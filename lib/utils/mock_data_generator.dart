import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../repositories/category_repository.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/database_helper.dart';

/// Utility class to generate comprehensive mock data across the entire database.
class MockDataGenerator {
  final CategoryRepository _categoryRepo;
  final WalletRepository _walletRepo;
  final Random _random = Random();
  final _uuid = const Uuid();

  final Map<String, String> _categoryIdsByName = {};

  MockDataGenerator(this._categoryRepo, [WalletRepository? walletRepo])
      : _walletRepo = walletRepo ?? WalletRepository();

  /// Generates mock data for categories, wallets, transactions, multi-month budgets,
  /// loans, saving goals, recurring configs, and transfers.
  Future<void> generateMockData() async {
    debugPrint('Starting mock data generation...');

    // 1. Create categories (income and expense)
    final categories = await _createCategories();

    // 2. Create wallets (Cash, VietinBank, MoMo, Binance)
    await _createWallets();

    // 3. Create transactions spanning March 2026 to today (September 5, 2026)
    await _createTransactions(categories);

    // 4. Create multi-month budgets for 7 months (03/2026 -> 09/2026)
    await _createBudgets(categories);

    // 5. Create inter-wallet transfers
    await _createTransfers();

    // 6. Create loan contacts and loan transactions
    await _createLoanData();

    // 7. Create saving goals and logs
    await _createSavingGoals();

    // 8. Create recurring transaction configs
    await _createRecurringConfigs();

    // 9. Recalculate accurate balances for all wallets
    for (final walletId in [
      'default_cash_wallet',
      'wallet_vietinbank',
      'wallet_momo',
      'wallet_binance',
    ]) {
      await _walletRepo.recalculateWalletBalance(walletId);
    }

    debugPrint('Completed mock data generation successfully.');
  }

  Future<Map<String, List<String>>> _createCategories() async {
    final incomeCategories = <String>[];
    final expenseCategories = <String>[];

    // 5 income categories
    final incomeData = [
      {'name': 'Lương', 'icon': 'work', 'color': '#4CAF50'},
      {'name': 'Thưởng', 'icon': 'card_giftcard', 'color': '#8BC34A'},
      {'name': 'Đầu tư', 'icon': 'trending_up', 'color': '#009688'},
      {'name': 'Kinh doanh', 'icon': 'store', 'color': '#FF9800'},
      {'name': 'Thu nhập khác', 'icon': 'attach_money', 'color': '#00BCD4'},
    ];

    for (var cat in incomeData) {
      try {
        final category = await _categoryRepo.create(
          cat['name']!,
          'income',
          icon: cat['icon'],
          color: cat['color'],
        );
        incomeCategories.add(category.id);
        _categoryIdsByName[cat['name']!] = category.id;
      } catch (e) {
        debugPrint('Error creating category ${cat['name']}: $e');
      }
    }

    // 5 expense categories
    final expenseData = [
      {'name': 'Ăn uống', 'icon': 'restaurant', 'color': '#FF5722', 'budget': 7000000.0},
      {'name': 'Đi lại', 'icon': 'directions_car', 'color': '#F44336', 'budget': 2000000.0},
      {'name': 'Mua sắm', 'icon': 'shopping_bag', 'color': '#E91E63', 'budget': 4000000.0},
      {'name': 'Hóa đơn & Tiện ích', 'icon': 'receipt', 'color': '#673AB7', 'budget': 2500000.0},
      {'name': 'Giải trí & Du lịch', 'icon': 'movie', 'color': '#9C27B0', 'budget': 3000000.0},
    ];

    for (var cat in expenseData) {
      try {
        final category = await _categoryRepo.create(
          cat['name'] as String,
          'expense',
          icon: cat['icon'] as String,
          color: cat['color'] as String,
          budgetLimit: cat['budget'] as double,
        );
        expenseCategories.add(category.id);
        _categoryIdsByName[cat['name'] as String] = category.id;
      } catch (e) {
        debugPrint('Error creating category ${cat['name']}: $e');
      }
    }

    return {
      'income': incomeCategories,
      'expense': expenseCategories,
    };
  }

  /// Creates 4 diverse wallets: Cash, Bank, E-Wallet, and Investment.
  Future<void> _createWallets() async {
    final db = await DatabaseHelper.instance.database;

    final wallets = [
      {
        'id': 'default_cash_wallet',
        'name': 'Ví tiền mặt',
        'type': 'cash',
        'initial_balance': 3000000.0,
        'current_balance': 3000000.0,
        'color': '#10B981',
        'icon': 'wallet',
        'currency': 'VND',
        'is_default': 1,
        'exclude_from_total': 0,
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'wallet_vietinbank',
        'name': 'VietinBank',
        'type': 'bank',
        'initial_balance': 45000000.0,
        'current_balance': 45000000.0,
        'color': '#0055A5',
        'icon': 'account_balance',
        'currency': 'VND',
        'is_default': 0,
        'exclude_from_total': 0,
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'wallet_momo',
        'name': 'Ví MoMo',
        'type': 'ewallet',
        'initial_balance': 10000000.0,
        'current_balance': 10000000.0,
        'color': '#A50064',
        'icon': 'phone_android',
        'currency': 'VND',
        'is_default': 0,
        'exclude_from_total': 0,
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      {
        'id': 'wallet_binance',
        'name': 'Binance',
        'type': 'other',
        'initial_balance': 50000000.0,
        'current_balance': 50000000.0,
        'color': '#F3BA2F',
        'icon': 'savings',
        'currency': 'VND',
        'is_default': 0,
        'exclude_from_total': 0,
        'created_at': DateTime(2026, 3, 1).toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    ];

    for (final w in wallets) {
      await db.insert(
        'wallets',
        w,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _createBudgets(Map<String, List<String>> categories) async {
    final db = await DatabaseHelper.instance.database;
    final expenseCatIds = categories['expense'] ?? [];

    final months = [
      DateTime(2026, 3, 1),
      DateTime(2026, 4, 1),
      DateTime(2026, 5, 1),
      DateTime(2026, 6, 1),
      DateTime(2026, 7, 1),
      DateTime(2026, 8, 1),
      DateTime(2026, 9, 1),
    ];

    final monthlyTotalLimits = [
      25000000.0, // March
      26000000.0, // April
      25000000.0, // May
      28000000.0, // June
      30000000.0, // July
      27000000.0, // August
      28000000.0, // September
    ];

    final categoryBaseLimits = [
      7000000.0, // Food & Dining
      2000000.0, // Transportation
      4000000.0, // Shopping
      2500000.0, // Bills & Utilities
      3000000.0, // Entertainment
    ];

    for (var mIndex = 0; mIndex < months.length; mIndex++) {
      final m = months[mIndex];
      final totalLimit = monthlyTotalLimits[mIndex];
      final now = m.toIso8601String();

      // 1. Insert monthly_budgets
      await db.insert(
        'monthly_budgets',
        {
          'id': _uuid.v4(),
          'year': m.year,
          'month': m.month,
          'amount': totalLimit,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert category_monthly_budgets per category
      for (var cIndex = 0; cIndex < expenseCatIds.length; cIndex++) {
        final catId = expenseCatIds[cIndex];
        final base = cIndex < categoryBaseLimits.length ? categoryBaseLimits[cIndex] : 3000000.0;
        // Slight variation per month for realistic dynamics
        final variation = (mIndex % 2 == 0 ? 500000.0 : 0.0);
        final catAmount = base + variation;

        await db.insert(
          'category_monthly_budgets',
          {
            'id': _uuid.v4(),
            'category_id': catId,
            'year': m.year,
            'month': m.month,
            'amount': catAmount,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> _createTransactions(Map<String, List<String>> categories) async {
    final db = await DatabaseHelper.instance.database;

    final incomeCategories = categories['income']!;
    final expenseCategories = categories['expense']!;

    // 1. Months March to August
    final pastMonths = [
      DateTime(2026, 3, 1),
      DateTime(2026, 4, 1),
      DateTime(2026, 5, 1),
      DateTime(2026, 6, 1),
      DateTime(2026, 7, 1),
      DateTime(2026, 8, 1),
    ];

    for (var month in pastMonths) {
      final maxDay = (month.month == 4 || month.month == 6) ? 30 : 31;

      // Create 2-4 income transactions per month
      final incomeCount = 2 + _random.nextInt(3);
      for (var i = 0; i < incomeCount; i++) {
        final day = 1 + _random.nextInt(maxDay);
        final hour = 8 + _random.nextInt(12);
        final minute = _random.nextInt(60);
        final txDate = DateTime(month.year, month.month, day, hour, minute);

        final categoryId = incomeCategories[_random.nextInt(incomeCategories.length)];
        final amount = (12 + _random.nextInt(24)) * 1000000.0; // 12M - 35M VND
        final note = _getRandomIncomeNote();
        final timestamps = _generateTimestamps(txDate);

        // Wallet distribution: VietinBank (70%), Binance (20%), Cash (10%)
        final randWallet = _random.nextDouble();
        final String walletId = randWallet < 0.70
            ? 'wallet_vietinbank'
            : (randWallet < 0.90 ? 'wallet_binance' : 'default_cash_wallet');

        try {
          await db.insert('transactions', {
            'id': _uuid.v4(),
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': 'income',
            'note': note,
            'transaction_date': timestamps['transaction_date'],
            'created_at': timestamps['created_at'],
            'updated_at': timestamps['updated_at'],
          });
        } catch (e) {
          debugPrint('Error creating income transaction: $e');
        }
      }

      // Create 16-22 expense transactions per month
      final expenseCount = 16 + _random.nextInt(7);
      for (var i = 0; i < expenseCount; i++) {
        final day = 1 + _random.nextInt(maxDay);
        final hour = _random.nextInt(24);
        final minute = _random.nextInt(60);
        final txDate = DateTime(month.year, month.month, day, hour, minute);
        final categoryId = expenseCategories[_random.nextInt(expenseCategories.length)];

        double amount;
        final rand = _random.nextDouble();
        if (rand < 0.45) {
          // 45% daily small expenses (20k - 90k)
          amount = 20000.0 + _random.nextInt(8) * 10000.0;
        } else if (rand < 0.80) {
          // 35% medium expenses (100k - 600k)
          amount = 100000.0 + _random.nextInt(11) * 50000.0;
        } else {
          // 20% major expenses (1M - 4.5M)
          amount = 1000000.0 + _random.nextInt(8) * 500000.0;
        }

        final note = _getRandomExpenseNote();
        final timestamps = _generateTimestamps(txDate);

        // Wallet distribution:
        // Large expenses (>= 1M): 90% VietinBank, 10% Cash
        // Small/medium expenses (< 1M): 55% MoMo, 30% Cash, 15% VietinBank
        final String walletId;
        final randWallet = _random.nextDouble();
        if (amount >= 1000000.0) {
          walletId = randWallet < 0.90 ? 'wallet_vietinbank' : 'default_cash_wallet';
        } else {
          walletId = randWallet < 0.55
              ? 'wallet_momo'
              : (randWallet < 0.85 ? 'default_cash_wallet' : 'wallet_vietinbank');
        }

        try {
          await db.insert('transactions', {
            'id': _uuid.v4(),
            'wallet_id': walletId,
            'category_id': categoryId,
            'amount': amount,
            'type': 'expense',
            'note': note,
            'transaction_date': timestamps['transaction_date'],
            'created_at': timestamps['created_at'],
            'updated_at': timestamps['updated_at'],
          });
        } catch (e) {
          debugPrint('Error creating expense transaction: $e');
        }
      }

      debugPrint('Created transactions for month ${month.month}/${month.year}');
    }

    // 2. September 2026 transactions up to today (September 5, 2026)
    final sepTransactions = [
      // Day 1 (2026-09-01)
      {
        'date': DateTime(2026, 9, 1, 8, 30),
        'type': 'expense',
        'cat': 'Hóa đơn & Tiện ích',
        'wallet': 'wallet_vietinbank',
        'amount': 7000000.0,
        'note': 'Tiền thuê căn hộ tháng 9',
      },
      {
        'date': DateTime(2026, 9, 1, 9, 15),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'wallet_momo',
        'amount': 45000.0,
        'note': 'Cà phê sáng Highlands Coffee',
      },
      {
        'date': DateTime(2026, 9, 1, 12, 10),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'default_cash_wallet',
        'amount': 40000.0,
        'note': 'Cơm trưa văn phòng',
      },

      // Day 2 (2026-09-02)
      {
        'date': DateTime(2026, 9, 2, 8, 0),
        'type': 'expense',
        'cat': 'Đi lại',
        'wallet': 'default_cash_wallet',
        'amount': 80000.0,
        'note': 'Đổ xăng xe máy Petrolimex',
      },
      {
        'date': DateTime(2026, 9, 2, 16, 45),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'wallet_momo',
        'amount': 55000.0,
        'note': 'Trà sữa Phúc Long',
      },
      {
        'date': DateTime(2026, 9, 2, 19, 30),
        'type': 'expense',
        'cat': 'Mua sắm',
        'wallet': 'wallet_vietinbank',
        'amount': 450000.0,
        'note': 'Siêu thị WinMart mua thực phẩm tuần',
      },

      // Day 3 (2026-09-03)
      {
        'date': DateTime(2026, 9, 3, 11, 45),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'wallet_momo',
        'amount': 50000.0,
        'note': 'Ăn trưa bún bò Huế',
      },
      {
        'date': DateTime(2026, 9, 3, 15, 20),
        'type': 'expense',
        'cat': 'Mua sắm',
        'wallet': 'wallet_momo',
        'amount': 185000.0,
        'note': 'Mua sách lập trình IT tại Fahasa',
      },
      {
        'date': DateTime(2026, 9, 3, 20, 15),
        'type': 'expense',
        'cat': 'Giải trí & Du lịch',
        'wallet': 'wallet_momo',
        'amount': 120000.0,
        'note': 'Vé xem phim CGV cuối ngày',
      },

      // Day 4 (2026-09-04 - Yesterday)
      {
        'date': DateTime(2026, 9, 4, 8, 15),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'wallet_momo',
        'amount': 45000.0,
        'note': 'Cà phê The Coffee House',
      },
      {
        'date': DateTime(2026, 9, 4, 18, 30),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'wallet_vietinbank',
        'amount': 550000.0,
        'note': 'Bữa tối liên hoan Haidilao cùng đồng nghiệp',
      },
      {
        'date': DateTime(2026, 9, 4, 21, 0),
        'type': 'expense',
        'cat': 'Đi lại',
        'wallet': 'default_cash_wallet',
        'amount': 20000.0,
        'note': 'Phí gửi xe qua đêm',
      },

      // Day 5 (2026-09-05 - Today)
      {
        'date': DateTime(2026, 9, 5, 8, 30),
        'type': 'income',
        'cat': 'Lương',
        'wallet': 'wallet_vietinbank',
        'amount': 35000000.0,
        'note': 'Lương tháng 8 công ty FPT chuyển khoản',
      },
      {
        'date': DateTime(2026, 9, 5, 9, 0),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'default_cash_wallet',
        'amount': 25000.0,
        'note': 'Cà phê sáng vỉa hè',
      },
      {
        'date': DateTime(2026, 9, 5, 12, 0),
        'type': 'expense',
        'cat': 'Ăn uống',
        'wallet': 'wallet_momo',
        'amount': 45000.0,
        'note': 'Cơm gà xối mỡ trưa',
      },
      {
        'date': DateTime(2026, 9, 5, 14, 20),
        'type': 'expense',
        'cat': 'Mua sắm',
        'wallet': 'wallet_momo',
        'amount': 230000.0,
        'note': 'Đặt đồ gia dụng Shopee',
      },
    ];

    for (final item in sepTransactions) {
      final catName = item['cat'] as String;
      final type = item['type'] as String;
      final categoryId = _categoryIdsByName[catName] ??
          (type == 'income' ? incomeCategories.first : expenseCategories.first);
      final date = item['date'] as DateTime;
      final isoDate = date.toIso8601String();

      try {
        await db.insert('transactions', {
          'id': _uuid.v4(),
          'wallet_id': item['wallet'] as String,
          'category_id': categoryId,
          'amount': item['amount'] as double,
          'type': type,
          'note': item['note'] as String,
          'transaction_date': isoDate,
          'created_at': isoDate,
          'updated_at': isoDate,
        });
      } catch (e) {
        debugPrint('Error creating September transaction: $e');
      }
    }
  }

  Map<String, String> _generateTimestamps(DateTime txDate) {
    final rand = _random.nextDouble();

    if (rand < 0.70) {
      // 70% Exactly at transaction date
      final txIso = txDate.toIso8601String();
      return {
        'transaction_date': txIso,
        'created_at': txIso,
        'updated_at': txIso,
      };
    } else if (rand < 0.85) {
      // 15% Backlogged (created 1-3 days after transaction)
      final createdDate = txDate.add(Duration(
        days: 1 + _random.nextInt(3),
        hours: _random.nextInt(10),
        minutes: _random.nextInt(60),
      ));
      final createdIso = createdDate.toIso8601String();
      return {
        'transaction_date': txDate.toIso8601String(),
        'created_at': createdIso,
        'updated_at': createdIso,
      };
    } else {
      // 15% Edited after creation (updated_at > created_at)
      final createdDate = txDate.add(Duration(hours: _random.nextInt(5)));
      final updatedDate = createdDate.add(Duration(
        days: 1 + _random.nextInt(2),
        hours: 1 + _random.nextInt(8),
      ));
      return {
        'transaction_date': txDate.toIso8601String(),
        'created_at': createdDate.toIso8601String(),
        'updated_at': updatedDate.toIso8601String(),
      };
    }
  }

  /// Creates realistic inter-wallet transfers across months.
  Future<void> _createTransfers() async {
    final db = await DatabaseHelper.instance.database;

    // Monthly regular top-ups from VietinBank to MoMo and Cash
    for (int m = 3; m <= 8; m++) {
      final momoDate = DateTime(2026, m, 5, 10, 0).toIso8601String();
      final cashDate = DateTime(2026, m, 8, 11, 30).toIso8601String();

      await db.insert('wallet_transfers', {
        'id': _uuid.v4(),
        'source_wallet_id': 'wallet_vietinbank',
        'destination_wallet_id': 'wallet_momo',
        'amount': 6000000.0,
        'fee': 0.0,
        'transfer_date': momoDate,
        'note': 'Nạp ví MoMo chi tiêu tháng $m',
        'created_at': momoDate,
      });

      await db.insert('wallet_transfers', {
        'id': _uuid.v4(),
        'source_wallet_id': 'wallet_vietinbank',
        'destination_wallet_id': 'default_cash_wallet',
        'amount': 3000000.0,
        'fee': 0.0,
        'transfer_date': cashDate,
        'note': 'Rút tiền mặt ATM tiêu vặt tháng $m',
        'created_at': cashDate,
      });

      // Bi-monthly investment transfer to Binance
      if (m % 2 == 0) {
        final binanceDate = DateTime(2026, m, 15, 14, 0).toIso8601String();
        await db.insert('wallet_transfers', {
          'id': _uuid.v4(),
          'source_wallet_id': 'wallet_vietinbank',
          'destination_wallet_id': 'wallet_binance',
          'amount': 10000000.0,
          'fee': 0.0,
          'transfer_date': binanceDate,
          'note': 'Chuyển tiền mua USDT đầu tư Binance',
          'created_at': binanceDate,
        });
      }
    }

    // September transfers
    final sepMomoDate = DateTime(2026, 9, 2, 9, 0).toIso8601String();
    final sepCashDate = DateTime(2026, 9, 3, 10, 0).toIso8601String();

    await db.insert('wallet_transfers', {
      'id': _uuid.v4(),
      'source_wallet_id': 'wallet_vietinbank',
      'destination_wallet_id': 'wallet_momo',
      'amount': 4000000.0,
      'fee': 0.0,
      'transfer_date': sepMomoDate,
      'note': 'Nạp ví MoMo đầu tháng 9',
      'created_at': sepMomoDate,
    });

    await db.insert('wallet_transfers', {
      'id': _uuid.v4(),
      'source_wallet_id': 'wallet_vietinbank',
      'destination_wallet_id': 'default_cash_wallet',
      'amount': 2000000.0,
      'fee': 0.0,
      'transfer_date': sepCashDate,
      'note': 'Rút tiền ATM chi tiêu tháng 9',
      'created_at': sepCashDate,
    });
  }

  /// Creates loan data: 4 contacts (2 lent, 2 borrowed) with transaction histories
  /// and synchronizes them with the main transactions ledger and wallets.
  Future<void> _createLoanData() async {
    final db = await DatabaseHelper.instance.database;

    // Ensure system loan categories exist
    final sysCats = [
      {'id': 'sys_loan_borrow', 'name': 'Nợ', 'type': 'income', 'icon': 'account_balance_wallet', 'color': '#FF4CAF50'},
      {'id': 'sys_loan_repay', 'name': 'Trả nợ', 'type': 'expense', 'icon': 'money_off', 'color': '#FFF44336'},
      {'id': 'sys_loan_lend', 'name': 'Cho vay', 'type': 'expense', 'icon': 'account_balance_wallet', 'color': '#FFF44336'},
      {'id': 'sys_loan_collect', 'name': 'Thu tiền vay', 'type': 'income', 'icon': 'attach_money', 'color': '#FF4CAF50'},
    ];
    for (var cat in sysCats) {
      final existing = await db.query('categories', where: 'id = ?', whereArgs: [cat['id']]);
      if (existing.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await db.insert('categories', {
          ...cat,
          'created_at': now,
          'updated_at': now,
        });
      }
    }

    final contact1Id = _uuid.v4();
    final contact2Id = _uuid.v4();
    final contact3Id = _uuid.v4();
    final contact4Id = _uuid.v4();
    final now = DateTime(2026, 9, 5, 10, 0).toIso8601String();

    try {
      // Helper to record corresponding main ledger transaction
      Future<void> addMainTx({
        required String type,
        required double amount,
        required String categoryId,
        required String walletId,
        required String note,
        required DateTime date,
      }) async {
        final iso = date.toIso8601String();
        await db.insert('transactions', {
          'id': _uuid.v4(),
          'amount': amount,
          'type': type,
          'category_id': categoryId,
          'wallet_id': walletId,
          'note': note,
          'transaction_date': iso,
          'created_at': iso,
          'updated_at': iso,
          'synced': 0,
        });
      }

      // 1. Lend to Nguyen Van A: 5M total, 2M collected, 3M remaining
      await db.insert('loan_contacts', {
        'id': contact1Id,
        'contact_name': 'Nguyễn Văn A',
        'type': 'lent',
        'total_amount': 5000000.0,
        'remaining_amount': 3000000.0,
        'status': 'active',
        'created_at': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
        'updated_at': now,
      });

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact1Id,
        'amount': 5000000.0,
        'type': 'lend',
        'date': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
        'due_date': DateTime(2026, 10, 1).toIso8601String(),
        'note': 'Cho A mượn tiền đóng học phí',
        'created_at': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
        'updated_at': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'expense',
        amount: 5000000.0,
        categoryId: 'sys_loan_lend',
        walletId: 'wallet_vietinbank',
        note: 'Cho vay Nguyễn Văn A - Cho A mượn tiền đóng học phí',
        date: DateTime(2026, 6, 1, 9, 0),
      );

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact1Id,
        'amount': 2000000.0,
        'type': 'collect',
        'date': DateTime(2026, 7, 15, 14, 30).toIso8601String(),
        'note': 'A trả bớt đợt 1',
        'created_at': DateTime(2026, 7, 15, 14, 30).toIso8601String(),
        'updated_at': DateTime(2026, 7, 15, 14, 30).toIso8601String(),
      });
      await addMainTx(
        type: 'income',
        amount: 2000000.0,
        categoryId: 'sys_loan_collect',
        walletId: 'wallet_vietinbank',
        note: 'Thu từ Nguyễn Văn A - A trả bớt đợt 1',
        date: DateTime(2026, 7, 15, 14, 30),
      );

      // 2. Borrow from Tran Thi B: 10M total, 5M repaid, 5M remaining
      await db.insert('loan_contacts', {
        'id': contact2Id,
        'contact_name': 'Trần Thị B',
        'type': 'borrowed',
        'total_amount': 10000000.0,
        'remaining_amount': 5000000.0,
        'status': 'active',
        'created_at': DateTime(2026, 5, 10, 15, 0).toIso8601String(),
        'updated_at': now,
      });

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact2Id,
        'amount': 10000000.0,
        'type': 'borrow',
        'date': DateTime(2026, 5, 10, 15, 0).toIso8601String(),
        'due_date': DateTime(2026, 11, 10).toIso8601String(),
        'note': 'Mượn chị B tiền mua laptop mới',
        'created_at': DateTime(2026, 5, 10, 15, 0).toIso8601String(),
        'updated_at': DateTime(2026, 5, 10, 15, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'income',
        amount: 10000000.0,
        categoryId: 'sys_loan_borrow',
        walletId: 'wallet_vietinbank',
        note: 'Vay từ Trần Thị B - Mượn chị B tiền mua laptop mới',
        date: DateTime(2026, 5, 10, 15, 0),
      );

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact2Id,
        'amount': 5000000.0,
        'type': 'repay',
        'date': DateTime(2026, 7, 5, 11, 0).toIso8601String(),
        'note': 'Trả bớt một nửa cho chị B',
        'created_at': DateTime(2026, 7, 5, 11, 0).toIso8601String(),
        'updated_at': DateTime(2026, 7, 5, 11, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'expense',
        amount: 5000000.0,
        categoryId: 'sys_loan_repay',
        walletId: 'wallet_vietinbank',
        note: 'Trả cho Trần Thị B - Trả bớt một nửa cho chị B',
        date: DateTime(2026, 7, 5, 11, 0),
      );

      // 3. Lend to colleague Nam: 2M total, 2M remaining
      await db.insert('loan_contacts', {
        'id': contact3Id,
        'contact_name': 'Anh Nam đồng nghiệp',
        'type': 'lent',
        'total_amount': 2000000.0,
        'remaining_amount': 2000000.0,
        'status': 'active',
        'created_at': DateTime(2026, 8, 28, 17, 0).toIso8601String(),
        'updated_at': now,
      });

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact3Id,
        'amount': 2000000.0,
        'type': 'lend',
        'date': DateTime(2026, 8, 28, 17, 0).toIso8601String(),
        'due_date': DateTime(2026, 9, 15).toIso8601String(),
        'note': 'Cho Nam mượn tiền liên hoan cuối tháng',
        'created_at': DateTime(2026, 8, 28, 17, 0).toIso8601String(),
        'updated_at': DateTime(2026, 8, 28, 17, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'expense',
        amount: 2000000.0,
        categoryId: 'sys_loan_lend',
        walletId: 'default_cash_wallet',
        note: 'Cho vay Anh Nam đồng nghiệp - Cho Nam mượn tiền liên hoan cuối tháng',
        date: DateTime(2026, 8, 28, 17, 0),
      );

      // 4. VPBank Consumer Loan: 20M borrowed, 8M repaid, 12M remaining
      await db.insert('loan_contacts', {
        'id': contact4Id,
        'contact_name': 'VPBank (Vay tiêu dùng)',
        'type': 'borrowed',
        'total_amount': 20000000.0,
        'remaining_amount': 12000000.0,
        'status': 'active',
        'created_at': DateTime(2026, 4, 1, 9, 0).toIso8601String(),
        'updated_at': now,
      });

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact4Id,
        'amount': 20000000.0,
        'type': 'borrow',
        'date': DateTime(2026, 4, 1, 9, 0).toIso8601String(),
        'due_date': DateTime(2027, 4, 1).toIso8601String(),
        'note': 'Vay tín chấp nâng cấp trang thiết bị làm việc',
        'created_at': DateTime(2026, 4, 1, 9, 0).toIso8601String(),
        'updated_at': DateTime(2026, 4, 1, 9, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'income',
        amount: 20000000.0,
        categoryId: 'sys_loan_borrow',
        walletId: 'wallet_vietinbank',
        note: 'Vay từ VPBank (Vay tiêu dùng) - Vay tín chấp nâng cấp trang thiết bị làm việc',
        date: DateTime(2026, 4, 1, 9, 0),
      );

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact4Id,
        'amount': 4000000.0,
        'type': 'repay',
        'date': DateTime(2026, 5, 1, 10, 0).toIso8601String(),
        'note': 'Thanh toán trả góp kỳ 1',
        'created_at': DateTime(2026, 5, 1, 10, 0).toIso8601String(),
        'updated_at': DateTime(2026, 5, 1, 10, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'expense',
        amount: 4000000.0,
        categoryId: 'sys_loan_repay',
        walletId: 'wallet_vietinbank',
        note: 'Trả cho VPBank (Vay tiêu dùng) - Thanh toán trả góp kỳ 1',
        date: DateTime(2026, 5, 1, 10, 0),
      );

      await db.insert('loan_transactions', {
        'id': _uuid.v4(),
        'loan_id': contact4Id,
        'amount': 4000000.0,
        'type': 'repay',
        'date': DateTime(2026, 6, 1, 10, 0).toIso8601String(),
        'note': 'Thanh toán trả góp kỳ 2',
        'created_at': DateTime(2026, 6, 1, 10, 0).toIso8601String(),
        'updated_at': DateTime(2026, 6, 1, 10, 0).toIso8601String(),
      });
      await addMainTx(
        type: 'expense',
        amount: 4000000.0,
        categoryId: 'sys_loan_repay',
        walletId: 'wallet_vietinbank',
        note: 'Trả cho VPBank (Vay tiêu dùng) - Thanh toán trả góp kỳ 2',
        date: DateTime(2026, 6, 1, 10, 0),
      );
    } catch (e) {
      debugPrint('Error creating loan data: $e');
    }
  }

  /// Creates 3 realistic saving goals with deposit logs.
  Future<void> _createSavingGoals() async {
    final db = await DatabaseHelper.instance.database;

    final goal1Id = _uuid.v4();
    final goal2Id = _uuid.v4();
    final goal3Id = _uuid.v4();

    // 1. 6-Month Emergency Fund
    await db.insert('saving_goals', {
      'id': goal1Id,
      'name': 'Quỹ khẩn cấp 6 tháng',
      'target_amount': 100000000.0,
      'current_amount': 60000000.0,
      'target_date': DateTime(2026, 12, 31).toIso8601String(),
      'color': '#10B981',
      'icon': 'savings',
      'note': 'Dự phòng tài chính an toàn 6 tháng chi tiêu',
      'status': 'active',
      'created_at': DateTime(2026, 3, 15).toIso8601String(),
      'updated_at': DateTime(2026, 8, 10).toIso8601String(),
    });

    final goal1Logs = [
      {'amount': 20000000.0, 'date': DateTime(2026, 4, 10), 'note': 'Trích thưởng quý 1'},
      {'amount': 20000000.0, 'date': DateTime(2026, 6, 10), 'note': 'Tiết kiệm lương tháng 6'},
      {'amount': 20000000.0, 'date': DateTime(2026, 8, 10), 'note': 'Tiết kiệm lương tháng 8'},
    ];
    for (final log in goal1Logs) {
      final iso = (log['date'] as DateTime).toIso8601String();
      await db.insert('saving_goal_logs', {
        'id': _uuid.v4(),
        'goal_id': goal1Id,
        'amount': log['amount'] as double,
        'type': 'deposit',
        'log_date': iso,
        'note': log['note'] as String,
        'created_at': iso,
      });
    }

    // 2. iPhone 17 Pro Max
    await db.insert('saving_goals', {
      'id': goal2Id,
      'name': 'iPhone 17 Pro Max',
      'target_amount': 35000000.0,
      'current_amount': 25000000.0,
      'target_date': DateTime(2026, 10, 31).toIso8601String(),
      'color': '#6366F1',
      'icon': 'phone',
      'note': 'Nâng cấp điện thoại mới cuối năm',
      'status': 'active',
      'created_at': DateTime(2026, 6, 20).toIso8601String(),
      'updated_at': DateTime(2026, 8, 1).toIso8601String(),
    });

    final goal2Logs = [
      {'amount': 10000000.0, 'date': DateTime(2026, 7, 1), 'note': 'Khởi tạo quỹ iPhone'},
      {'amount': 15000000.0, 'date': DateTime(2026, 8, 1), 'note': 'Thêm tiền thưởng dự án'},
    ];
    for (final log in goal2Logs) {
      final iso = (log['date'] as DateTime).toIso8601String();
      await db.insert('saving_goal_logs', {
        'id': _uuid.v4(),
        'goal_id': goal2Id,
        'amount': log['amount'] as double,
        'type': 'deposit',
        'log_date': iso,
        'note': log['note'] as String,
        'created_at': iso,
      });
    }

    // 3. Japan Travel (Completed)
    await db.insert('saving_goals', {
      'id': goal3Id,
      'name': 'Du lịch Nhật Bản',
      'target_amount': 45000000.0,
      'current_amount': 45000000.0,
      'target_date': DateTime(2026, 11, 20).toIso8601String(),
      'color': '#EC4899',
      'icon': 'flight',
      'note': 'Chuyến đi ngắm lá vàng Kyoto',
      'status': 'completed',
      'created_at': DateTime(2026, 4, 15).toIso8601String(),
      'updated_at': DateTime(2026, 7, 15).toIso8601String(),
    });

    final goal3Logs = [
      {'amount': 15000000.0, 'date': DateTime(2026, 5, 15), 'note': 'Tiết kiệm đợt 1'},
      {'amount': 15000000.0, 'date': DateTime(2026, 6, 15), 'note': 'Tiết kiệm đợt 2'},
      {'amount': 15000000.0, 'date': DateTime(2026, 7, 15), 'note': 'Hoàn tất mục tiêu chuyến đi'},
    ];
    for (final log in goal3Logs) {
      final iso = (log['date'] as DateTime).toIso8601String();
      await db.insert('saving_goal_logs', {
        'id': _uuid.v4(),
        'goal_id': goal3Id,
        'amount': log['amount'] as double,
        'type': 'deposit',
        'log_date': iso,
        'note': log['note'] as String,
        'created_at': iso,
      });
    }
  }

  /// Creates 5 recurring transactions bound to categories and wallets.
  Future<void> _createRecurringConfigs() async {
    final db = await DatabaseHelper.instance.database;

    final luongId = _categoryIdsByName['Lương'];
    final hoaDonId = _categoryIdsByName['Hóa đơn & Tiện ích'];
    final giaiTriId = _categoryIdsByName['Giải trí & Du lịch'];

    final recurringData = [
      {
        'name': 'Lương hàng tháng FPT',
        'amount': 35000000.0,
        'type': 'income',
        'frequency': 'monthly',
        'interval': 1,
        'day_of_month': 5,
        'wallet_id': 'wallet_vietinbank',
        'category_id': luongId,
        'next_run': DateTime(2026, 10, 5, 8, 0).toIso8601String(),
      },
      {
        'name': 'Tiền thuê căn hộ',
        'amount': 7000000.0,
        'type': 'expense',
        'frequency': 'monthly',
        'interval': 1,
        'day_of_month': 1,
        'wallet_id': 'wallet_vietinbank',
        'category_id': hoaDonId,
        'next_run': DateTime(2026, 10, 1, 9, 0).toIso8601String(),
      },
      {
        'name': 'Gói Netflix Premium',
        'amount': 260000.0,
        'type': 'expense',
        'frequency': 'monthly',
        'interval': 1,
        'day_of_month': 15,
        'wallet_id': 'wallet_momo',
        'category_id': giaiTriId,
        'next_run': DateTime(2026, 9, 15, 12, 0).toIso8601String(),
      },
      {
        'name': 'Thẻ tập Gym California',
        'amount': 800000.0,
        'type': 'expense',
        'frequency': 'monthly',
        'interval': 1,
        'day_of_month': 10,
        'wallet_id': 'wallet_momo',
        'category_id': giaiTriId,
        'next_run': DateTime(2026, 9, 10, 18, 0).toIso8601String(),
      },
      {
        'name': 'Cước Internet cáp quang Viettel',
        'amount': 330000.0,
        'type': 'expense',
        'frequency': 'monthly',
        'interval': 1,
        'day_of_month': 20,
        'wallet_id': 'wallet_vietinbank',
        'category_id': hoaDonId,
        'next_run': DateTime(2026, 9, 20, 10, 0).toIso8601String(),
      },
    ];

    final now = DateTime.now().toIso8601String();
    for (final item in recurringData) {
      await db.insert('recurring_configs', {
        'id': _uuid.v4(),
        'category_id': item['category_id'],
        'wallet_id': item['wallet_id'],
        'name': item['name'],
        'amount': item['amount'],
        'type': item['type'],
        'frequency': item['frequency'],
        'interval': item['interval'],
        'day_of_month': item['day_of_month'],
        'next_run': item['next_run'],
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  String _getRandomIncomeNote() {
    final notes = [
      'Lương tháng này chuyển vào tài khoản',
      'Thưởng KPI quý đạt xuất sắc',
      'Lãi từ danh mục cổ phiếu & trái phiếu',
      'Doanh thu bán hàng online',
      'Thu nhập làm thêm dự án tự do (Freelance)',
      'Tiền cổ tức đợt 1',
      'Hoàn tiền chiết khấu mua sắm',
    ];
    return notes[_random.nextInt(notes.length)];
  }

  String _getRandomExpenseNote() {
    final notes = [
      'Ăn trưa cơm văn phòng',
      'Uống trà sữa GongCha',
      'Cà phê sáng cùng đồng nghiệp Highlands',
      'Đi siêu thị Co.opmart mua thực phẩm tuần',
      'Đổ xăng xe máy đầy bình',
      'Mua áo sơ mi công sở mới',
      'Tiền điện & nước tháng này',
      'Cước Internet Viettel',
      'Đi xem phim cuối tuần cùng bạn',
      'Bữa tối liên hoan công ty',
      'Mua sách chuyên ngành IT',
      'Đặt đồ ăn qua GrabFood',
      'Gửi xe tháng tòa nhà',
      'Mua quà sinh nhật bạn thân',
    ];
    return notes[_random.nextInt(notes.length)];
  }
}
