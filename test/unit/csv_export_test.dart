import 'dart:convert';
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

  group('CSV Export Tests', () {
    late ExportService exportService;

    setUp(() {
      exportService = ExportService();
    });

    test('exports transactions with UTF-8 BOM and correct headers', () async {
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
        amount: 35000,
        type: 'expense',
        categoryId: cat.id,
        note: 'Cà phê sáng, "Đặc biệt"',
        transactionDate: DateTime(2026, 8, 22, 7, 30),
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );

      final filter = ExportFilterParams(
        rangeType: ExportDateRange.allTime,
        currency: 'VND',
      );

      final file = await exportService.exportToCsv(
        transactions: [tx],
        categories: [cat],
        filter: filter,
        l10n: l10n,
      );

      expect(await file.exists(), isTrue);

      final bytes = await file.readAsBytes();
      // Check for UTF-8 BOM: 0xEF, 0xBB, 0xBF
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);

      final content = utf8.decode(bytes.sublist(3));
      expect(content, contains('Ngày,Giờ,Loại,Danh mục,Số tiền (VND),Ghi chú,Công thức'));
      expect(content, contains('Ăn uống'));
      expect(content, contains('35000.0'));

      if (await file.exists()) {
        await file.delete();
      }
    });
  });
}
