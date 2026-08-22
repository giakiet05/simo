import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/export_filter_params.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/loan_contact.dart';
import '../models/recurring_config.dart';
import '../models/monthly_budget.dart';
import '../models/saving_goal.dart';
import '../services/currency_service.dart';
import 'file_helper.dart';

class ExportService {
  /// Exports transactions, budgets, and loans to a multi-sheet Excel (.xlsx) workbook
  Future<File> exportToExcel({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<MonthlyBudgetSummary> monthlyBudgets,
    required List<LoanContact> loans,
    required List<RecurringConfig> recurringConfigs,
    List<SavingGoal> savingGoals = const [],
    required ExportFilterParams filter,
    required dynamic l10n,
  }) async {
    final excel = Excel.createExcel();

    // Default sheet name in package excel is 'Sheet1'
    final txSheetName = l10n.locale == 'vi' ? 'Giao dịch' : 'Transactions';
    excel.rename('Sheet1', txSheetName);
    final Sheet txSheet = excel[txSheetName];

    final filteredTxs = transactions.where((tx) => filter.isDateInRange(tx.transactionDate)).toList();

    // 1. Transactions Sheet Headers
    final txHeaders = [
      l10n.locale == 'vi' ? 'Ngày' : 'Date',
      l10n.locale == 'vi' ? 'Giờ' : 'Time',
      l10n.locale == 'vi' ? 'Loại' : 'Type',
      l10n.locale == 'vi' ? 'Danh mục' : 'Category',
      l10n.locale == 'vi' ? 'Số tiền (${filter.currency})' : 'Amount (${filter.currency})',
      l10n.locale == 'vi' ? 'Ghi chú' : 'Note',
      l10n.locale == 'vi' ? 'Công thức' : 'Formula',
    ];

    txSheet.appendRow(txHeaders.map((h) => TextCellValue(h)).toList());

    final categoryMap = {for (var c in categories) c.id: c};

    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in filteredTxs) {
      final isIncome = tx.type == 'income';
      if (isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }

      final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
      final catName = cat != null ? l10n.translateCategoryName(cat.id, cat.name) : (l10n.locale == 'vi' ? 'Khác' : 'Other');

      txSheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(tx.transactionDate)),
        TextCellValue(DateFormat('HH:mm:ss').format(tx.transactionDate)),
        TextCellValue(isIncome ? (l10n.locale == 'vi' ? 'Thu nhập' : 'Income') : (l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense')),
        TextCellValue(catName),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.note ?? ''),
        TextCellValue(tx.formula ?? ''),
      ]);
    }

    // Summary row in Transactions sheet
    txSheet.appendRow([
      TextCellValue('---'),
      TextCellValue('---'),
      TextCellValue('---'),
      TextCellValue(l10n.locale == 'vi' ? 'TỔNG CỘNG' : 'TOTAL'),
      DoubleCellValue(totalIncome - totalExpense),
      TextCellValue('Thu: $totalIncome, Chi: $totalExpense'),
      TextCellValue(''),
    ]);

    // 2. Budgets Sheet
    final budgetSheetName = l10n.locale == 'vi' ? 'Ngân sách' : 'Budgets';
    final Sheet budgetSheet = excel[budgetSheetName];
    final budgetHeaders = [
      l10n.locale == 'vi' ? 'Tháng/Năm' : 'Month/Year',
      l10n.locale == 'vi' ? 'Danh mục' : 'Category',
      l10n.locale == 'vi' ? 'Hạn mức (${filter.currency})' : 'Limit (${filter.currency})',
      l10n.locale == 'vi' ? 'Đã chi (${filter.currency})' : 'Spent (${filter.currency})',
      l10n.locale == 'vi' ? 'Tỷ lệ' : 'Percentage',
    ];
    budgetSheet.appendRow(budgetHeaders.map((h) => TextCellValue(h)).toList());

    for (final summary in monthlyBudgets) {
      final monthLabel = 'T${summary.month}/${summary.year}';
      budgetSheet.appendRow([
        TextCellValue(monthLabel),
        TextCellValue(l10n.locale == 'vi' ? 'Tổng ngân sách tháng' : 'Total Monthly Budget'),
        DoubleCellValue(summary.totalBudget),
        DoubleCellValue(summary.totalSpent),
        TextCellValue('${(summary.percentageUsed * 100).toStringAsFixed(1)}%'),
      ]);

      for (final catStatus in summary.categoryStatuses.values) {
        if (!catStatus.hasBudget) continue;
        final cat = categoryMap[catStatus.categoryId];
        final catName = cat != null ? l10n.translateCategoryName(cat.id, cat.name) : catStatus.categoryId;
        budgetSheet.appendRow([
          TextCellValue(monthLabel),
          TextCellValue(catName),
          DoubleCellValue(catStatus.budgetLimit),
          DoubleCellValue(catStatus.spent),
          TextCellValue('${(catStatus.percentage * 100).toStringAsFixed(1)}%'),
        ]);
      }
    }

    // 3. Loans Sheet
    final loanSheetName = l10n.locale == 'vi' ? 'Sổ nợ' : 'Loans';
    final Sheet loanSheet = excel[loanSheetName];
    final loanHeaders = [
      l10n.locale == 'vi' ? 'Người liên hệ' : 'Contact Name',
      l10n.locale == 'vi' ? 'Loại' : 'Type',
      l10n.locale == 'vi' ? 'Tổng số tiền (${filter.currency})' : 'Total Amount (${filter.currency})',
      l10n.locale == 'vi' ? 'Còn lại (${filter.currency})' : 'Remaining (${filter.currency})',
      l10n.locale == 'vi' ? 'Trạng thái' : 'Status',
    ];
    loanSheet.appendRow(loanHeaders.map((h) => TextCellValue(h)).toList());

    for (final loan in loans) {
      loanSheet.appendRow([
        TextCellValue(loan.contactName),
        TextCellValue(loan.type == 'borrowed' ? (l10n.locale == 'vi' ? 'Đi vay (Nợ)' : 'Borrowed') : (l10n.locale == 'vi' ? 'Cho vay' : 'Lent')),
        DoubleCellValue(loan.totalAmount),
        DoubleCellValue(loan.remainingAmount),
        TextCellValue(loan.status),
      ]);
    }

    // 4. Saving Goals Sheet
    if (savingGoals.isNotEmpty) {
      final goalsSheetName = l10n.locale == 'vi' ? 'Mục tiêu tiết kiệm' : 'Saving Goals';
      final Sheet goalsSheet = excel[goalsSheetName];
      final goalHeaders = [
        l10n.locale == 'vi' ? 'Tên mục tiêu' : 'Goal Name',
        l10n.locale == 'vi' ? 'Mục tiêu (${filter.currency})' : 'Target (${filter.currency})',
        l10n.locale == 'vi' ? 'Đã gom (${filter.currency})' : 'Saved (${filter.currency})',
        l10n.locale == 'vi' ? 'Còn thiếu (${filter.currency})' : 'Remaining (${filter.currency})',
        l10n.locale == 'vi' ? 'Tỷ lệ' : 'Percentage',
        l10n.locale == 'vi' ? 'Hạn chót' : 'Deadline',
        l10n.locale == 'vi' ? 'Trạng thái' : 'Status',
      ];
      goalsSheet.appendRow(goalHeaders.map((h) => TextCellValue(h)).toList());

      for (final goal in savingGoals) {
        goalsSheet.appendRow([
          TextCellValue(goal.name),
          DoubleCellValue(goal.targetAmount),
          DoubleCellValue(goal.currentAmount),
          DoubleCellValue(goal.remainingAmount),
          TextCellValue('${(goal.progressPercentage * 100).toStringAsFixed(1)}%'),
          TextCellValue(goal.targetDate != null ? DateFormat('yyyy-MM-dd').format(goal.targetDate!) : ''),
          TextCellValue(goal.isCompleted ? (l10n.locale == 'vi' ? 'Đã hoàn thành' : 'Completed') : (l10n.locale == 'vi' ? 'Đang tích lũy' : 'In Progress')),
        ]);
      }
    }

    final file = await FileHelper.createTempExportFile(
      prefix: 'simo_export',
      extension: '.xlsx',
    );

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes, flush: true);
    }
    return file;
  }

  /// Exports transactions to a CSV file encoded in UTF-8 with BOM
  Future<File> exportToCsv({
    required List<Transaction> transactions,
    required List<Category> categories,
    required ExportFilterParams filter,
    required dynamic l10n,
  }) async {
    final filteredTxs = transactions.where((tx) => filter.isDateInRange(tx.transactionDate)).toList();
    final categoryMap = {for (var c in categories) c.id: c};

    final headers = [
      l10n.locale == 'vi' ? 'Ngày' : 'Date',
      l10n.locale == 'vi' ? 'Giờ' : 'Time',
      l10n.locale == 'vi' ? 'Loại' : 'Type',
      l10n.locale == 'vi' ? 'Danh mục' : 'Category',
      l10n.locale == 'vi' ? 'Số tiền (${filter.currency})' : 'Amount (${filter.currency})',
      l10n.locale == 'vi' ? 'Ghi chú' : 'Note',
      l10n.locale == 'vi' ? 'Công thức' : 'Formula',
    ];

    final List<List<dynamic>> rows = [headers];

    for (final tx in filteredTxs) {
      final isIncome = tx.type == 'income';
      final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
      final catName = cat != null ? l10n.translateCategoryName(cat.id, cat.name) : (l10n.locale == 'vi' ? 'Khác' : 'Other');

      rows.add([
        DateFormat('yyyy-MM-dd').format(tx.transactionDate),
        DateFormat('HH:mm:ss').format(tx.transactionDate),
        isIncome ? (l10n.locale == 'vi' ? 'Thu nhập' : 'Income') : (l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense'),
        catName,
        tx.amount,
        tx.note ?? '',
        tx.formula ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    final bytes = FileHelper.encodeUtf8WithBom(csvString);

    final file = await FileHelper.createTempExportFile(
      prefix: 'simo_transactions',
      extension: '.csv',
    );

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Generates a printable PDF financial statement
  Future<File> exportToPdf({
    required List<Transaction> transactions,
    required List<Category> categories,
    required ExportFilterParams filter,
    required dynamic l10n,
  }) async {
    final filteredTxs = transactions.where((tx) => filter.isDateInRange(tx.transactionDate)).toList();
    final categoryMap = {for (var c in categories) c.id: c};

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categorySpending = {};

    for (final tx in filteredTxs) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        final catId = tx.categoryId ?? 'other';
        categorySpending[catId] = (categorySpending[catId] ?? 0) + tx.amount;
      }
    }

    final netBalance = totalIncome - totalExpense;

    final pdf = pw.Document();
    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final currencySymbol = CurrencyService.getSymbol(filter.currency);
    final numberFormat = NumberFormat('#,###');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SIMO - BÁO CÁO TÀI CHÍNH', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                  pw.Text('Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.teal),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (context) => [
          // KPI Summary Cards
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.green200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(l10n.locale == 'vi' ? 'Tổng Thu nhập' : 'Total Income', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
                      pw.SizedBox(height: 4),
                      pw.Text('+${numberFormat.format(totalIncome)} $currencySymbol', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.red200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(l10n.locale == 'vi' ? 'Tổng Chi tiêu' : 'Total Expense', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red800)),
                      pw.SizedBox(height: 4),
                      pw.Text('-${numberFormat.format(totalExpense)} $currencySymbol', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: netBalance >= 0 ? PdfColors.teal50 : PdfColors.orange50,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: netBalance >= 0 ? PdfColors.teal200 : PdfColors.orange200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(l10n.locale == 'vi' ? 'Số dư ròng' : 'Net Balance', style: pw.TextStyle(fontSize: 10, color: netBalance >= 0 ? PdfColors.teal800 : PdfColors.orange800)),
                      pw.SizedBox(height: 4),
                      pw.Text('${netBalance >= 0 ? '+' : ''}${numberFormat.format(netBalance)} $currencySymbol', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: netBalance >= 0 ? PdfColors.teal900 : PdfColors.orange900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Category Breakdown Table
          pw.Text(l10n.locale == 'vi' ? 'Phân bổ chi tiêu theo danh mục' : 'Expense by Category', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(l10n.locale == 'vi' ? 'Danh mục' : 'Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(l10n.locale == 'vi' ? 'Số tiền' : 'Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(l10n.locale == 'vi' ? 'Tỷ lệ' : 'Percent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                ],
              ),
              ...categorySpending.entries.map((entry) {
                final cat = categoryMap[entry.key];
                final name = cat != null ? l10n.translateCategoryName(cat.id, cat.name) : (l10n.locale == 'vi' ? 'Khác' : 'Other');
                final percent = totalExpense > 0 ? (entry.value / totalExpense * 100).toStringAsFixed(1) : '0.0';
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(name, style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${numberFormat.format(entry.value)} $currencySymbol', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('$percent%', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),

          // Transaction Ledger Table
          pw.Text(l10n.locale == 'vi' ? 'Nhật ký giao dịch' : 'Transaction Log', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.8),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(l10n.locale == 'vi' ? 'Ngày' : 'Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(l10n.locale == 'vi' ? 'Loại' : 'Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(l10n.locale == 'vi' ? 'Danh mục' : 'Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(l10n.locale == 'vi' ? 'Số tiền' : 'Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(l10n.locale == 'vi' ? 'Ghi chú' : 'Note', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              ...filteredTxs.map((tx) {
                final isIncome = tx.type == 'income';
                final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
                final catName = cat != null ? l10n.translateCategoryName(cat.id, cat.name) : (l10n.locale == 'vi' ? 'Khác' : 'Other');
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('dd/MM/yyyy').format(tx.transactionDate), style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(isIncome ? (l10n.locale == 'vi' ? 'Thu' : 'Inc') : (l10n.locale == 'vi' ? 'Chi' : 'Exp'), style: pw.TextStyle(fontSize: 8, color: isIncome ? PdfColors.green800 : PdfColors.red800))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(catName, style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${isIncome ? '+' : '-'}${numberFormat.format(tx.amount)} $currencySymbol', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: isIncome ? PdfColors.green900 : PdfColors.red900), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(tx.note ?? '', style: const pw.TextStyle(fontSize: 8))),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final file = await FileHelper.createTempExportFile(
      prefix: 'simo_report',
      extension: '.pdf',
    );

    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  /// Triggers the native OS share sheet for a generated file
  Future<void> shareFile(File file, {String? subject, String? text}) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      subject: subject,
      text: text,
    );
  }
}
