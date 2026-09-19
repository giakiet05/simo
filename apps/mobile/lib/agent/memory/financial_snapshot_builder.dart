import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/category_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/saving_goal_provider.dart';
import '../../providers/transaction_provider.dart';

/// Aggregates live application state from Riverpod providers into a structured financial snapshot.
class FinancialSnapshotBuilder {
  /// Builds a formatted context string capturing all current financial entities.
  static String buildSystemContext(Ref ref) {
    final categories = ref.read(categoryProvider).value ?? [];
    final wallets = ref.read(walletProvider).value ?? [];
    final loans = ref.read(loanProvider).value ?? [];
    final goals = ref.read(savingGoalProvider).value ?? [];
    final transactions = ref.read(transactionProvider).value ?? [];

    final userCategories = categories.where((c) => !c.id.startsWith('sys_')).toList();
    final categoryStr = userCategories.isEmpty
        ? 'Chưa có danh mục'
        : userCategories.map((c) => 'ID: ${c.id}, Tên: ${c.name}, Loại: ${c.type}').join('\n');

    final walletStr = wallets.isEmpty
        ? 'Chưa có ví cụ thể'
        : wallets.map((w) => 'ID: ${w.id}, Tên: ${w.name}, Loại: ${w.type}, Số dư: ${w.currentBalance.toInt()} VND${w.isDefault ? " [VÍ MẶC ĐỊNH]" : ""}').join('\n');

    final loanStr = loans.isEmpty
        ? 'Chưa có liên hệ nợ'
        : loans.map((l) => 'ID: ${l.id}, Tên: ${l.contactName}, Loại: ${l.type}, Dư nợ: ${l.remainingAmount.toInt()} VND').join('\n');

    final goalStr = goals.isEmpty
        ? 'Chưa có mục tiêu'
        : goals.map((g) => 'ID: ${g.id}, Tên: ${g.name}, Đã tích lũy: ${g.currentAmount.toInt()}/${g.targetAmount.toInt()} VND').join('\n');

    final now = DateTime.now();
    final todayTxs = transactions.where((tx) {
      return tx.transactionDate.year == now.year &&
          tx.transactionDate.month == now.month &&
          tx.transactionDate.day == now.day;
    }).toList();

    double todayExpense = 0;
    double todayIncome = 0;
    for (final tx in todayTxs) {
      if (tx.type == 'expense') {
        todayExpense += tx.amount;
      } else {
        todayIncome += tx.amount;
      }
    }

    final summaryStr = 'Tổng chi hôm nay: ${todayExpense.toInt()} VND, Tổng thu hôm nay: ${todayIncome.toInt()} VND, Số giao dịch hôm nay: ${todayTxs.length}.';

    final recentTxs = transactions.take(10).toList();
    final recentTxsStr = recentTxs.isEmpty
        ? 'Chưa có giao dịch gần đây'
        : recentTxs.map((tx) {
            final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull?.name ?? 'Chưa phân loại';
            final wal = wallets.where((w) => w.id == tx.walletId).firstOrNull?.name ?? 'Mặc định';
            final dateStr = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}-${tx.transactionDate.day.toString().padLeft(2, '0')}';
            return 'ID: ${tx.id}, Ghi chú: "${tx.note ?? ''}", Tiền: ${tx.amount.toInt()} VND, Loại: ${tx.type}, Danh mục: $cat (ID: ${tx.categoryId ?? 'null'}), Ví: $wal, Ngày: $dateStr';
          }).join('\n');

    return """
[Danh mục (Categories)]:
$categoryStr

[Ví tiền (Wallets)]:
$walletStr

[Liên hệ nợ (Loans)]:
$loanStr

[Mục tiêu tích lũy (Goals)]:
$goalStr

[Giao dịch gần đây (Recent Transactions)]:
$recentTxsStr

[Tổng quan hôm nay]:
$summaryStr
""";
  }
}
