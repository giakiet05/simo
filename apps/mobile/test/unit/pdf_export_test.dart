import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/category.dart';
import 'package:simo/models/export_filter_params.dart';
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

  group('PDF Export Tests', () {
    late ExportService exportService;

    setUp(() {
      exportService = ExportService();
    });

    test('generates valid PDF report document', () async {
      final l10n = AppLocalizations('vi');
      final cat = Category(
        id: 'cat_1',
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
        note: 'Cơm trưa',
        transactionDate: DateTime(2026, 8, 22),
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );

      final filter = ExportFilterParams(
        rangeType: ExportDateRange.allTime,
        currency: 'VND',
      );

      final file = await exportService.exportToPdf(
        transactions: [tx],
        categories: [cat],
        filter: filter,
        l10n: l10n,
      );

      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      // PDF file magic header: %PDF
      final header = String.fromCharCodes(bytes.take(4));
      expect(header, equals('%PDF'));

      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
