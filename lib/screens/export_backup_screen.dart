import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/export_filter_params.dart';
import '../models/import_inspection.dart';
import '../models/monthly_budget.dart';
import '../providers/category_provider.dart';
import '../providers/export_backup_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/monthly_budget_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/banner_ad_widget.dart';

enum ExportFormat {
  excel,
  pdf,
  csv,
}

class ExportBackupScreen extends ConsumerStatefulWidget {
  const ExportBackupScreen({super.key});

  @override
  ConsumerState<ExportBackupScreen> createState() => _ExportBackupScreenState();
}

class _ExportBackupScreenState extends ConsumerState<ExportBackupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExportDateRange _selectedRange = ExportDateRange.thisMonth;
  ExportFormat _selectedFormat = ExportFormat.excel;
  DateTimeRange? _customDateRange;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ExportFilterParams _buildFilterParams(String currency) {
    return ExportFilterParams(
      rangeType: _selectedRange,
      startDate: _customDateRange?.start,
      endDate: _customDateRange?.end,
      currency: currency,
    );
  }

  Future<void> _handleExport(dynamic l10n, String currency) async {
    switch (_selectedFormat) {
      case ExportFormat.excel:
        await _handleExportExcel(l10n, currency);
        break;
      case ExportFormat.pdf:
        await _handleExportPdf(l10n, currency);
        break;
      case ExportFormat.csv:
        await _handleExportCsv(l10n, currency);
        break;
    }
  }

  Future<void> _handleExportExcel(dynamic l10n, String currency) async {
    setState(() => _isProcessing = true);
    try {
      final exportService = ref.read(exportServiceProvider);
      final transactions = ref.read(transactionProvider).value ?? [];
      final categories = ref.read(categoryProvider).value ?? [];
      final loans = ref.read(loanProvider).value ?? [];
      final recurringConfigs = ref.read(recurringProvider).value ?? [];
      final savingGoals = ref.read(savingGoalProvider).value ?? [];

      // Collect last 6 months budget summaries for multi-sheet
      final now = DateTime.now();
      final List<MonthlyBudgetSummary> summaries = [];
      for (int i = 0; i < 6; i++) {
        final m = DateTime(now.year, now.month - i, 1);
        final summary = ref.read(monthlyBudgetFamily(MonthYearKey(m.year, m.month))).value;
        if (summary != null) {
          summaries.add(summary);
        }
      }

      final filter = _buildFilterParams(currency);
      final file = await exportService.exportToExcel(
        transactions: transactions,
        categories: categories,
        monthlyBudgets: summaries,
        loans: loans,
        recurringConfigs: recurringConfigs,
        savingGoals: savingGoals,
        filter: filter,
        l10n: l10n,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await exportService.shareFile(file, subject: 'SIMO - Financial Export (.xlsx)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExportCsv(dynamic l10n, String currency) async {
    setState(() => _isProcessing = true);
    try {
      final exportService = ref.read(exportServiceProvider);
      final transactions = ref.read(transactionProvider).value ?? [];
      final categories = ref.read(categoryProvider).value ?? [];

      final filter = _buildFilterParams(currency);
      final file = await exportService.exportToCsv(
        transactions: transactions,
        categories: categories,
        filter: filter,
        l10n: l10n,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await exportService.shareFile(file, subject: 'SIMO - Transactions (.csv)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleExportPdf(dynamic l10n, String currency) async {
    setState(() => _isProcessing = true);
    try {
      final exportService = ref.read(exportServiceProvider);
      final transactions = ref.read(transactionProvider).value ?? [];
      final categories = ref.read(categoryProvider).value ?? [];

      final filter = _buildFilterParams(currency);
      final file = await exportService.exportToPdf(
        transactions: transactions,
        categories: categories,
        filter: filter,
        l10n: l10n,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      await exportService.shareFile(file, subject: 'SIMO - Financial Report (.pdf)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCreateBackup(dynamic l10n) async {
    setState(() => _isProcessing = true);
    try {
      final backupNotifier = ref.read(backupProvider.notifier);
      final file = await backupNotifier.createBackup();

      if (file != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupCreated),
              backgroundColor: Colors.teal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        final exportService = ref.read(exportServiceProvider);
        await exportService.shareFile(file, subject: 'SIMO Backup (.json)');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePickAndRestoreBackup(dynamic l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final backupNotifier = ref.read(backupProvider.notifier);

      setState(() => _isProcessing = true);
      final inspection = await backupNotifier.inspectBackup(file);
      setState(() => _isProcessing = false);

      if (inspection == null || !inspection.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(inspection?.errorMessage ?? l10n.importInvalidFile),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (mounted) {
        _showRestoreConfirmationDialog(file, inspection, l10n);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.restoreFailed}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRestoreConfirmationDialog(File file, ImportInspection inspection, dynamic l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actionsOverflowButtonSpacing: 8,
          actionsOverflowDirection: VerticalDirection.down,
          title: Row(
            children: [
              const Icon(Icons.settings_backup_restore, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.importPreviewTitle,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(inspection.exportedAt)}',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildInspectionRow(Icons.category, l10n.totalCategoriesCount, inspection.totalCategories),
              _buildInspectionRow(Icons.receipt_long, l10n.totalTransactionsCount, inspection.totalTransactions),
              _buildInspectionRow(Icons.pie_chart, l10n.totalBudgetsCount, inspection.totalMonthlyBudgets),
              _buildInspectionRow(Icons.account_balance_wallet, l10n.totalLoansCount, inspection.totalLoans),
              _buildInspectionRow(Icons.autorenew, l10n.totalRecurringCount, inspection.totalRecurringConfigs),
              const SizedBox(height: 16),
              Text(
                l10n.locale == 'vi'
                    ? 'Chọn phương thức khôi phục dữ liệu:'
                    : 'Choose restore method:',
                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _executeRestore(file, false, l10n);
              },
              child: Text(l10n.importMerge),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await _executeRestore(file, true, l10n);
              },
              child: Text(l10n.importOverwrite),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInspectionRow(IconData icon, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRestore(File file, bool overwriteMode, dynamic l10n) async {
    setState(() => _isProcessing = true);
    try {
      final backupNotifier = ref.read(backupProvider.notifier);
      final success = await backupNotifier.restoreBackup(file, overwriteMode: overwriteMode);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreSuccess),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreFailed),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settings = ref.watch(settingsProvider).value;
    final currency = settings?.currency ?? 'VND';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportBackup),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.file_upload_outlined), text: l10n.exportReports),
            Tab(icon: const Icon(Icons.cloud_sync_outlined), text: l10n.backupRestore),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExportReportsTab(l10n, currency),
                    _buildBackupRestoreTab(l10n),
                  ],
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Text(l10n.exportingData),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportReportsTab(dynamic l10n, String currency) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Time range filter section
        Text(
          l10n.exportTimeRange,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRangeChip(ExportDateRange.thisMonth, l10n.thisMonth),
            _buildRangeChip(ExportDateRange.lastMonth, l10n.lastMonth),
            _buildRangeChip(ExportDateRange.thisYear, l10n.locale == 'vi' ? 'Năm nay' : 'This Year'),
            _buildRangeChip(ExportDateRange.allTime, l10n.all),
            _buildRangeChip(ExportDateRange.custom, l10n.customRange),
          ],
        ),
        if (_selectedRange == ExportDateRange.custom && _customDateRange != null) ...[
          const SizedBox(height: 8),
          Text(
            '${DateFormat('dd/MM/yyyy').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_customDateRange!.end)}',
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
        const SizedBox(height: 24),

        // 2. Export format selector
        Text(
          l10n.exportFormat,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFormatChip(ExportFormat.excel, l10n.exportExcel, Icons.table_chart_rounded, Colors.green),
            _buildFormatChip(ExportFormat.pdf, l10n.exportPdf, Icons.picture_as_pdf_rounded, Colors.red),
            _buildFormatChip(ExportFormat.csv, l10n.exportCsv, Icons.description_outlined, Colors.blue),
          ],
        ),
        const SizedBox(height: 32),

        // 3. Main Export Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.file_download_outlined),
            label: Text(
              l10n.exportAction,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isProcessing ? null : () => _handleExport(l10n, currency),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeChip(ExportDateRange range, String label) {
    final isSelected = _selectedRange == range;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (!selected) return;
        if (range == ExportDateRange.custom) {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            initialDateRange: _customDateRange ?? DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
          );
          if (picked != null) {
            setState(() {
              _selectedRange = range;
              _customDateRange = picked;
            });
          }
        } else {
          setState(() {
            _selectedRange = range;
          });
        }
      },
    );
  }

  Widget _buildFormatChip(ExportFormat format, String label, IconData icon, Color color) {
    final isSelected = _selectedFormat == format;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFormat = format;
          });
        }
      },
    );
  }

  Widget _buildBackupRestoreTab(dynamic l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActionCard(
          icon: Icons.cloud_upload_outlined,
          color: Colors.teal,
          title: l10n.createBackup,
          subtitle: null,
          onTap: () => _handleCreateBackup(l10n),
        ),
        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.cloud_download_outlined,
          color: Colors.deepOrange,
          title: l10n.restoreBackup,
          subtitle: l10n.restoreBackupHint,
          onTap: () => _handlePickAndRestoreBackup(l10n),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isProcessing ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
