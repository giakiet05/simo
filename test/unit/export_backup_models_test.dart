import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/export_filter_params.dart';
import 'package:simo/models/backup_snapshot.dart';
import 'package:simo/models/import_inspection.dart';

void main() {
  group('ExportFilterParams Tests', () {
    test('isDateInRange filters thisMonth correctly', () {
      final now = DateTime.now();
      final filter = ExportFilterParams(
        rangeType: ExportDateRange.thisMonth,
        currency: 'VND',
      );

      expect(filter.isDateInRange(DateTime(now.year, now.month, 15)), isTrue);
      expect(filter.isDateInRange(DateTime(now.year, now.month == 1 ? 12 : now.month - 1, 15)), isFalse);
    });

    test('isDateInRange filters custom range correctly', () {
      final filter = ExportFilterParams(
        rangeType: ExportDateRange.custom,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31),
        currency: 'VND',
      );

      expect(filter.isDateInRange(DateTime(2026, 5, 10)), isTrue);
      expect(filter.isDateInRange(DateTime(2026, 4, 30)), isFalse);
      expect(filter.isDateInRange(DateTime(2026, 6, 1)), isFalse);
    });
  });

  group('BackupSnapshot Tests', () {
    test('serializes and deserializes snapshot accurately', () {
      final snapshot = BackupSnapshot(
        version: 1,
        app: 'simo',
        appVersion: '1.3.0',
        exportedAt: DateTime(2026, 8, 22, 10, 0, 0),
        settings: {'currency': 'VND', 'language': 'vi'},
        categories: [
          {'id': 'cat_1', 'name': 'Ăn uống', 'type': 'expense'}
        ],
        transactions: [
          {'id': 'tx_1', 'amount': 50000.0, 'note': 'Cà phê sáng', 'type': 'expense'}
        ],
        monthlyBudgets: [
          {'id': 'mb_1', 'year': 2026, 'month': 8, 'amount': 10000000.0}
        ],
        categoryMonthlyBudgets: [
          {'id': 'cmb_1', 'category_id': 'cat_1', 'year': 2026, 'month': 8, 'amount': 3000000.0}
        ],
        loanContacts: [
          {'id': 'loan_1', 'contact_name': 'Nguyễn Văn A', 'type': 'borrowed', 'remaining_amount': 500000.0}
        ],
        loanTransactions: [
          {'id': 'ltx_1', 'loan_id': 'loan_1', 'amount': 500000.0, 'type': 'borrowed'}
        ],
        recurringConfigs: [
          {'id': 'rec_1', 'name': 'Tiền mạng', 'amount': 250000.0, 'type': 'expense'}
        ],
        wallets: [
          {'id': 'w_1', 'name': 'Vietcombank', 'type': 'bank', 'initial_balance': 5000000.0, 'current_balance': 5000000.0, 'color': '#0055FF', 'icon': 'account_balance'}
        ],
        walletTransfers: [
          {'id': 'wt_1', 'source_wallet_id': 'w_1', 'destination_wallet_id': 'w_2', 'amount': 1000000.0, 'fee': 1100.0, 'transfer_date': '2026-08-22T10:00:00.000'}
        ],
      );

      final jsonStr = snapshot.toJsonString();
      final restored = BackupSnapshot.fromJsonString(jsonStr);

      expect(restored.version, equals(1));
      expect(restored.app, equals('simo'));
      expect(restored.categories.length, equals(1));
      expect(restored.categories.first['name'], equals('Ăn uống'));
      expect(restored.transactions.length, equals(1));
      expect(restored.transactions.first['note'], equals('Cà phê sáng'));
      expect(restored.monthlyBudgets.length, equals(1));
      expect(restored.loanContacts.length, equals(1));
      expect(restored.recurringConfigs.length, equals(1));
      expect(restored.wallets.length, equals(1));
      expect(restored.wallets.first['name'], equals('Vietcombank'));
      expect(restored.walletTransfers.length, equals(1));
    });
  });

  group('ImportInspection Tests', () {
    test('creates valid and invalid inspections', () {
      final valid = ImportInspection(
        schemaVersion: 1,
        appVersion: '1.3.0',
        exportedAt: DateTime(2026, 8, 22),
        totalCategories: 10,
        totalTransactions: 50,
        totalMonthlyBudgets: 6,
        totalCategoryBudgets: 20,
        totalLoans: 3,
        totalLoanTransactions: 5,
        totalRecurringConfigs: 2,
      );

      final invalid = ImportInspection.invalid('Corrupted JSON structure');

      expect(valid.isValid, isTrue);
      expect(valid.totalTransactions, equals(50));
      expect(invalid.isValid, isFalse);
      expect(invalid.errorMessage, contains('Corrupted'));
    });
  });
}
