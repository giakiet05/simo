import 'dart:math';
import 'package:uuid/uuid.dart';
import '../repositories/category_repository.dart';
import '../repositories/database_helper.dart';

class MockDataGenerator {
  final CategoryRepository _categoryRepo;
  final Random _random = Random();
  final _uuid = const Uuid();

  MockDataGenerator(this._categoryRepo);

  Future<void> generateMockData() async {
    print('Bắt đầu tạo mock data...');

    // 1. Tạo 5 categories thu nhập và 5 categories chi tiêu
    final categories = await _createCategories();
    print('Đã tạo ${categories['income']!.length} thu nhập và ${categories['expense']!.length} chi tiêu');

    // 2. Tạo 100+ transactions từ tháng 3/2026 đến tháng 8/2026
    await _createTransactions(categories);
    print('Đã tạo 100+ transactions từ 03/2026 đến 08/2026');

    // 3. Tạo ngân sách đa tháng cho 6 tháng (03/2026 -> 08/2026)
    await _createBudgets(categories);
    print('Đã tạo ngân sách tổng và ngân sách danh mục cho 6 tháng');

    // 4. Tạo dữ liệu vay nợ
    await _createLoanData();
    print('Đã tạo dữ liệu vay nợ');

    print('Hoàn thành tạo mock data!');
  }

  Future<Map<String, List<String>>> _createCategories() async {
    final incomeCategories = <String>[];
    final expenseCategories = <String>[];

    // Đúng 5 danh mục Thu nhập (Income)
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
      } catch (e) {
        print('Lỗi tạo category ${cat['name']}: $e');
      }
    }

    // Đúng 5 danh mục Chi tiêu (Expense)
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
      } catch (e) {
        print('Lỗi tạo category ${cat['name']}: $e');
      }
    }

    return {
      'income': incomeCategories,
      'expense': expenseCategories,
    };
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
    ];

    final monthlyTotalLimits = [
      25000000.0, // Tháng 3
      26000000.0, // Tháng 4
      25000000.0, // Tháng 5
      28000000.0, // Tháng 6 (ngân sách hè)
      30000000.0, // Tháng 7 (du lịch)
      27000000.0, // Tháng 8
    ];

    final categoryBaseLimits = [
      7000000.0, // Ăn uống
      2000000.0, // Đi lại
      4000000.0, // Mua sắm
      2500000.0, // Hóa đơn
      3000000.0, // Giải trí
    ];

    for (var mIndex = 0; mIndex < months.length; mIndex++) {
      final m = months[mIndex];
      final totalLimit = monthlyTotalLimits[mIndex];
      final now = m.toIso8601String();

      // 1. Tạo monthly_budgets
      await db.insert('monthly_budgets', {
        'id': _uuid.v4(),
        'year': m.year,
        'month': m.month,
        'amount': totalLimit,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Tạo category_monthly_budgets cho từng danh mục
      for (var cIndex = 0; cIndex < expenseCatIds.length; cIndex++) {
        final catId = expenseCatIds[cIndex];
        final base = cIndex < categoryBaseLimits.length ? categoryBaseLimits[cIndex] : 3000000.0;
        // Biến thiên nhẹ theo tháng để sinh động
        final variation = (mIndex % 2 == 0 ? 500000.0 : 0.0);
        final catAmount = base + variation;

        await db.insert('category_monthly_budgets', {
          'id': _uuid.v4(),
          'category_id': catId,
          'year': m.year,
          'month': m.month,
          'amount': catAmount,
          'created_at': now,
          'updated_at': now,
        });
      }
    }
  }

  Future<void> _createTransactions(Map<String, List<String>> categories) async {
    final db = await DatabaseHelper.instance.database;

    final incomeCategories = categories['income']!;
    final expenseCategories = categories['expense']!;

    final months = [
      DateTime(2026, 3, 1),
      DateTime(2026, 4, 1),
      DateTime(2026, 5, 1),
      DateTime(2026, 6, 1),
      DateTime(2026, 7, 1),
      DateTime(2026, 8, 1),
    ];

    for (var month in months) {
      final maxDay = month.month == 8 ? 20 : (month.month == 4 || month.month == 6 ? 30 : 31);

      // --- 1. Tạo 2-4 Income transactions mỗi tháng ---
      final incomeCount = 2 + _random.nextInt(3);
      for (var i = 0; i < incomeCount; i++) {
        final day = 1 + _random.nextInt(maxDay);
        final hour = 8 + _random.nextInt(12);
        final minute = _random.nextInt(60);
        final txDate = DateTime(month.year, month.month, day, hour, minute);

        final categoryId = incomeCategories[_random.nextInt(incomeCategories.length)];
        final amount = (10 + _random.nextInt(25)) * 1000000.0; // 10M - 35M VND
        final note = _getRandomIncomeNote();
        final timestamps = _generateTimestamps(txDate);

        try {
          await db.insert('transactions', {
            'id': _uuid.v4(),
            'category_id': categoryId,
            'amount': amount,
            'type': 'income',
            'note': note,
            'transaction_date': timestamps['transaction_date'],
            'created_at': timestamps['created_at'],
            'updated_at': timestamps['updated_at'],
          });
        } catch (e) {
          print('Lỗi tạo income transaction: $e');
        }
      }

      // --- 2. Tạo 16-22 Expense transactions mỗi tháng ---
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
          // 45% chi tiêu nhỏ hàng ngày (20k - 90k)
          amount = 20000.0 + _random.nextInt(8) * 10000.0;
        } else if (rand < 0.80) {
          // 35% chi tiêu trung bình (100k - 600k)
          amount = 100000.0 + _random.nextInt(11) * 50000.0;
        } else {
          // 20% chi tiêu lớn (hóa đơn, đồ công nghệ, du lịch: 1M - 4.5M)
          amount = 1000000.0 + _random.nextInt(8) * 500000.0;
        }

        final note = _getRandomExpenseNote();
        final timestamps = _generateTimestamps(txDate);

        try {
          await db.insert('transactions', {
            'id': _uuid.v4(),
            'category_id': categoryId,
            'amount': amount,
            'type': 'expense',
            'note': note,
            'transaction_date': timestamps['transaction_date'],
            'created_at': timestamps['created_at'],
            'updated_at': timestamps['updated_at'],
          });
        } catch (e) {
          print('Lỗi tạo expense transaction: $e');
        }
      }

      print('Đã tạo transactions cho tháng ${month.month}/${month.year}');
    }
  }

  Map<String, String> _generateTimestamps(DateTime txDate) {
    final rand = _random.nextDouble();

    if (rand < 0.70) {
      // 70% Tạo đúng thời điểm giao dịch
      final txIso = txDate.toIso8601String();
      return {
        'transaction_date': txIso,
        'created_at': txIso,
        'updated_at': txIso,
      };
    } else if (rand < 0.85) {
      // 15% Ghi chép bù (created_at sau transaction_date 1-3 ngày)
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
      // 15% Đã từng chỉnh sửa (updated_at sau created_at)
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

  Future<void> _createLoanData() async {
    final db = await DatabaseHelper.instance.database;

    final contact1Id = _uuid.v4();
    final contact2Id = _uuid.v4();
    final now = DateTime(2026, 8, 20, 10, 0).toIso8601String();

    try {
      // 1. Cho Nguyễn Văn A vay 5,000,000 (Đã trả 2,000,000 còn 3,000,000)
      await db.insert('loan_contacts', {
        'id': contact1Id,
        'contact_name': 'Nguyễn Văn A',
        'type': 'lend',
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
        'due_date': DateTime(2026, 9, 1).toIso8601String(),
        'note': 'Cho A mượn tiền đóng học phí',
        'created_at': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
        'updated_at': DateTime(2026, 6, 1, 9, 0).toIso8601String(),
      });

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

      // 2. Vay Trần Thị B 10,000,000 (Đã trả 5,000,000 còn 5,000,000)
      await db.insert('loan_contacts', {
        'id': contact2Id,
        'contact_name': 'Trần Thị B',
        'type': 'borrow',
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
        'due_date': DateTime(2026, 10, 10).toIso8601String(),
        'note': 'Mượn chị B tiền mua laptop mới',
        'created_at': DateTime(2026, 5, 10, 15, 0).toIso8601String(),
        'updated_at': DateTime(2026, 5, 10, 15, 0).toIso8601String(),
      });

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
    } catch (e) {
      print('Lỗi tạo loan data: $e');
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
