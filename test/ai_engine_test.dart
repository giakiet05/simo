import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:simo/models/category.dart';
import 'package:simo/services/ai_transaction_service.dart';

// Fake categories for testing
final mockCategories = [
  Category(id: '1', name: 'Ăn uống', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '2', name: 'Di chuyển', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '3', name: 'Giải trí', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '4', name: 'Nhà cửa', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '5', name: 'Khác', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '6', name: 'Lương', type: 'income', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '7', name: 'Thu nhập khác', type: 'income', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '8', name: 'Hoá đơn', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '9', name: 'Học tập', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '10', name: 'Sức khoẻ', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '11', name: 'Cá nhân', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '12', name: 'Thú cưng', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
  Category(id: '13', name: 'Mua sắm', type: 'expense', icon: '', color: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
];

void main() async {
  // Load .env
  await dotenv.load(fileName: ".env");

  // Load test cases
  final file = File('test/ai_test_cases.json');
  final jsonString = await file.readAsString();
  final List<dynamic> testCases = jsonDecode(jsonString);

  final service = AiTransactionService();

  int passed = 0;
  int failed = 0;

  for (int i = 0; i < testCases.length; i++) {
    final testCase = testCases[i];
    final input = testCase['input'];
    final expectedSuccess = testCase['expected_success'];
    
    print('=====================================');
    print('Test \$i: "\$input"');

    try {
      final result = await service.parseTransaction(input, mockCategories);
      
      if (result == null) {
        if (!expectedSuccess) {
          print('✅ PASSED (Result is null as expected)');
          passed++;
        } else {
          print('❌ FAILED (Expected success but got null)');
          failed++;
        }
        continue;
      }

      final isSuccess = result['isSuccess'] as bool? ?? true;
      
      if (isSuccess != expectedSuccess) {
        print('❌ FAILED (Expected isSuccess: \$expectedSuccess, Got: \$isSuccess)');
        failed++;
        continue;
      }

      if (isSuccess) {
        final transactions = result['transactions'] as List<dynamic>? ?? [];
        if (transactions.isEmpty) {
          print('❌ FAILED (Expected transactions but got empty array)');
          failed++;
          continue;
        }

        final tx = transactions[0];
        final amount = tx['amount'];
        
        // Find category name based on returned ID
        final categoryId = tx['categoryId'];
        String? catName;
        if (categoryId != null) {
           final cat = mockCategories.firstWhere((c) => c.id == categoryId, orElse: () => mockCategories.first);
           catName = cat.name;
        }

        bool passAmount = true;
        bool passCat = true;

        if (testCase.containsKey('expected_amount') && amount != testCase['expected_amount']) {
          print('❌ FAILED Amount (Expected: ${testCase["expected_amount"]}, Got: $amount)');
          passAmount = false;
        }

        if (testCase.containsKey('expected_category_semantic') && catName != testCase['expected_category_semantic']) {
          print('❌ FAILED Category (Expected: ${testCase["expected_category_semantic"]}, Got: $catName)');
          passCat = false;
        }

        if (passAmount && passCat) {
          print('✅ PASSED (Amount: $amount, Category: $catName, Thought: ${result["thought"]})');
          passed++;
        } else {
          failed++;
        }
      } else {
        print('✅ PASSED (Rejected properly. Thought: ${result["thought"]}, Message: ${result["message"]})');
        passed++;
      }
    } catch (e) {
      print('❌ ERROR: \$e');
      failed++;
    }

    // Add a small delay to avoid rate limiting on Groq API
    await Future.delayed(Duration(seconds: 1));
  }

  print('=====================================');
  print('TEST RESULTS: \$passed PASSED, \$failed FAILED');
}
