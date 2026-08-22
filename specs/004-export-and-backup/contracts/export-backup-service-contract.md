# Service Contract: Export & Backup Services

## 1. `ExportService` Interface

Provides methods to generate and share export files:

```dart
abstract class IExportService {
  /// Exports transactions and summaries to an Excel (.xlsx) file and triggers native share
  Future<File> exportToExcel({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<MonthlyBudgetSummary> monthlyBudgets,
    required List<LoanContact> loans,
    required List<RecurringConfig> recurringConfigs,
    required ExportFilterParams filter,
    required dynamic l10n,
  });

  /// Exports transactions to a CSV (.csv) file with UTF-8 BOM and triggers native share
  Future<File> exportToCsv({
    required List<Transaction> transactions,
    required List<Category> categories,
    required ExportFilterParams filter,
    required dynamic l10n,
  });

  /// Generates a styled printable PDF (.pdf) financial statement
  Future<File> exportToPdf({
    required List<Transaction> transactions,
    required List<Category> categories,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required ExportFilterParams filter,
    required dynamic l10n,
  });

  /// Shares a generated file using the native OS Share Sheet
  Future<void> shareFile(File file, {String? subject, String? text});
}
```

---

## 2. `BackupService` Interface

Provides snapshot creation, validation, and database restoration:

```dart
abstract class IBackupService {
  /// Creates a full JSON snapshot of the SQLite database and settings
  Future<File> createBackupFile({required String appVersion});

  /// Inspects and validates a selected JSON backup file without mutating the database
  Future<ImportInspection> inspectBackupFile(File file);

  /// Restores the database from a backup file (supports 'overwrite' or 'merge')
  Future<bool> restoreFromBackup(File file, {required bool overwriteMode});
}
```

---

## 3. UI Navigation & Screen Contract

- **Entry Point**: `lib/screens/settings_screen.dart` -> List tile "Xuất & Sao lưu dữ liệu" with icon `Icons.file_download_outlined`.
- **Target Screen**: `lib/screens/export_backup_screen.dart`
  - Tab 1: **Xuất báo cáo** (Time Filter chips/picker, Format cards for Excel, PDF, CSV with one-tap export button).
  - Tab 2: **Sao lưu & Khôi phục** (Nút "Tạo bản sao lưu JSON", Nút "Khôi phục từ file JSON" kèm dialog xem trước và tùy chọn Ghi đè / Gộp).
