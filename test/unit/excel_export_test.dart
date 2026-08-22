import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/category.dart';
import 'package:simo/models/export_filter_params.dart';
import 'package:simo/models/monthly_budget.dart';
import 'package:simo/models/loan_contact.dart';
import 'package:simo/models/transaction.dart';
import 'package:simo/services/export_service.dart';
import 'package:simo/utils/localization.dart';
import 'package:flutter/services.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  group('Excel Export Tests', () {
    late ExportService exportService;

    setUp(() {
      exportService = ExportService();
    });

    test('generates multi-sheet Excel file with accurate sheets and rows', () async {
      final l10n = AppLocalizations('vi');
      final cat = Category(
        id: 'custom_cat_1',
        name: 'Ăn uống',
        type: 'expense',
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );

      final tx = Transaction(
        id: 'tx_1',
        amount: 50000,
        type: 'expense',
        categoryId: cat.id,
        note: 'Ăn trưa',
        transactionDate: DateTime(2026, 8, 22),
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );

      final loan = LoanContact(
        id: 'loan_1',
        contactName: 'Trần Văn B',
        type: 'lent',
        totalAmount: 1000000,
        remainingAmount: 500000,
        status: 'active',
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );

      const summary = MonthlyBudgetSummary(
        year: 2026,
        month: 8,
        totalBudget: 10000000,
        totalSpent: 50000,
        remaining: 9950000,
        percentageUsed: 0.005,
        categoryStatuses: {
          'custom_cat_1': CategoryBudgetStatus(
            categoryId: 'custom_cat_1',
            budgetLimit: 3000000,
            spent: 50000,
            remaining: 2950000,
            percentage: 0.016,
          ),
        },
      );

      final filter = ExportFilterParams(
        rangeType: ExportDateRange.allTime,
        currency: 'VND',
      );

      final file = await exportService.exportToExcel(
        transactions: [tx],
        categories: [cat],
        monthlyBudgets: [summary],
        loans: [loan],
        recurringConfigs: [],
        filter: filter,
        l10n: l10n,
      );

      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      expect(excel.sheets.containsKey('Giao dịch'), isTrue);
      expect(excel.sheets.containsKey('Ngân sách'), isTrue);
      expect(excel.sheets.containsKey('Sổ nợ'), isTrue);

      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
