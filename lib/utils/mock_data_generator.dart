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

    // Tạo categories
    final categories = await _createCategories();
    print('Đã tạo ${categories.length} categories');

    // Tạo transactions từ tháng 10/2025 đến tháng 2/2026
    await _createTransactions(categories);
    print('Đã tạo transactions từ 10/2025 đến 02/2026');

    print('Hoàn thành tạo mock data!');
  }

  Future<Map<String, List<String>>> _createCategories() async {
    final incomeCategories = <String>[];
    final expenseCategories = <String>[];

    // Income categories
    final incomeData = [
      {'name': 'Lương', 'icon': 'work', 'color': '#4CAF50'},
      {'name': 'Thưởng', 'icon': 'card_giftcard', 'color': '#8BC34A'},
      {'name': 'Đầu tư', 'icon': 'trending_up', 'color': '#009688'},
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

    // Expense categories
    final expenseData = [
      {'name': 'Ăn uống', 'icon': 'restaurant', 'color': '#FF5722'},
      {'name': 'Đi lại', 'icon': 'directions_car', 'color': '#F44336'},
      {'name': 'Mua sắm', 'icon': 'shopping_bag', 'color': '#E91E63'},
      {'name': 'Giải trí', 'icon': 'movie', 'color': '#9C27B0'},
      {'name': 'Hóa đơn', 'icon': 'receipt', 'color': '#673AB7'},
      {'name': 'Y tế', 'icon': 'local_hospital', 'color': '#3F51B5'},
      {'name': 'Giáo dục', 'icon': 'school', 'color': '#2196F3'},
      {'name': 'Khác', 'icon': 'more_horiz', 'color': '#9E9E9E'},
    ];

    for (var cat in expenseData) {
      try {
        final category = await _categoryRepo.create(
          cat['name']!,
          'expense',
          icon: cat['icon'],
          color: cat['color'],
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

  Future<void> _createTransactions(Map<String, List<String>> categories) async {
    final db = await DatabaseHelper.instance.database;
    final incomeCategories = categories['income']!;
    final expenseCategories = categories['expense']!;

    // Tạo transactions cho từng tháng từ 10/2025 đến 02/2026
    final months = [
      DateTime(2025, 10),
      DateTime(2025, 11),
      DateTime(2025, 12),
      DateTime(2026, 1),
      DateTime(2026, 2),
    ];

    for (var month in months) {
      // Tạo 1-2 thu nhập mỗi tháng
      final incomeCount = 1 + _random.nextInt(2);
      for (var i = 0; i < incomeCount; i++) {
        final day = 1 + _random.nextInt(28);
        final date = DateTime(month.year, month.month, day);
        final categoryId = incomeCategories[_random.nextInt(incomeCategories.length)];
        final amount = 5000000.0 + _random.nextDouble() * 15000000;

        try {
          await db.insert('transactions', {
            'id': _uuid.v4(),
            'category_id': categoryId,
            'amount': amount,
            'type': 'income',
            'created_at': date.toIso8601String(),
            'updated_at': date.toIso8601String(),
            'synced': 0,
          });
        } catch (e) {
          print('Lỗi tạo income transaction: $e');
        }
      }

      // Tạo 15-25 chi tiêu mỗi tháng
      final expenseCount = 15 + _random.nextInt(11);
      for (var i = 0; i < expenseCount; i++) {
        final day = 1 + _random.nextInt(28);
        final hour = _random.nextInt(24);
        final minute = _random.nextInt(60);
        final date = DateTime(month.year, month.month, day, hour, minute);
        final categoryId = expenseCategories[_random.nextInt(expenseCategories.length)];

        // Các khoản chi tiêu khác nhau
        double amount;
        if (_random.nextDouble() < 0.3) {
          // 30% là chi tiêu nhỏ (10k - 100k)
          amount = 10000.0 + _random.nextDouble() * 90000;
        } else if (_random.nextDouble() < 0.6) {
          // 40% là chi tiêu trung bình (100k - 500k)
          amount = 100000.0 + _random.nextDouble() * 400000;
        } else {
          // 30% là chi tiêu lớn (500k - 5M)
          amount = 500000.0 + _random.nextDouble() * 4500000;
        }

        final notes = _random.nextDouble() < 0.3 ? _getRandomNote() : null;

        try {
          await db.insert('transactions', {
            'id': _uuid.v4(),
            'category_id': categoryId,
            'amount': amount,
            'type': 'expense',
            'note': notes,
            'created_at': date.toIso8601String(),
            'updated_at': date.toIso8601String(),
            'synced': 0,
          });
        } catch (e) {
          print('Lỗi tạo expense transaction: $e');
        }
      }

      print('Đã tạo transactions cho tháng ${month.month}/${month.year}');
    }
  }

  String _getRandomNote() {
    final notes = [
      'Mua sắm cuối tuần',
      'Tiệc sinh nhật',
      'Đi chơi với bạn',
      'Mua đồ công ty',
      'Nạp thẻ điện thoại',
      'Mua quà',
      'Sửa xe',
      'Đóng tiền điện nước',
      'Mua sách',
      'Cafe',
    ];
    return notes[_random.nextInt(notes.length)];
  }
}
