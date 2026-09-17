import '../agent_tool.dart';
import '../../../models/ai_message.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Read tool to query and filter transactions from local database state and format into [TransactionListViewPayload].
class QueryTransactionsTool extends SimoAgentTool<Map<String, dynamic>, TransactionListViewPayload?> {
  @override
  String get name => 'query_transactions';

  @override
  String get description => 'Tra cứu danh sách các giao dịch thu/chi theo khoảng thời gian, danh mục hoặc ví';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'period': {'type': 'string', 'enum': ['today', 'yesterday', 'this_week', 'this_month', 'all']},
      'type': {'type': 'string', 'enum': ['expense', 'income', 'all']},
      'categoryId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'minAmount': {'type': ['number', 'null']},
      'maxAmount': {'type': ['number', 'null']},
    },
  };

  @override
  Future<TransactionListViewPayload?> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final allTxs = context.ref.read(transactionProvider).value ?? [];
    final categories = context.ref.read(categoryProvider).value ?? [];
    final wallets = context.ref.read(walletProvider).value ?? [];

    final period = input['period'] as String? ?? 'today';
    final txType = input['type'] as String? ?? 'all';
    final categoryId = input['categoryId'] as String?;
    final walletId = input['walletId'] as String?;
    final minAmount = (input['minAmount'] as num?)?.toDouble();
    final maxAmount = (input['maxAmount'] as num?)?.toDouble();

    final now = DateTime.now();

    final filtered = allTxs.where((tx) {
      // Filter by type
      if (txType != 'all' && tx.type != txType) return false;

      // Filter by category
      if (categoryId != null && categoryId.isNotEmpty && tx.categoryId != categoryId) {
        return false;
      }

      // Filter by wallet
      if (walletId != null && walletId.isNotEmpty && tx.walletId != walletId) {
        return false;
      }

      // Filter by amount
      if (minAmount != null && tx.amount < minAmount) return false;
      if (maxAmount != null && tx.amount > maxAmount) return false;

      // Filter by period
      final txDate = tx.transactionDate;
      if (period == 'today') {
        return txDate.year == now.year && txDate.month == now.month && txDate.day == now.day;
      } else if (period == 'yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        return txDate.year == yesterday.year && txDate.month == yesterday.month && txDate.day == yesterday.day;
      } else if (period == 'this_week') {
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return txDate.isAfter(startOfDay) || txDate.isAtSameMomentAs(startOfDay);
      } else if (period == 'this_month') {
        return txDate.year == now.year && txDate.month == now.month;
      }

      return true;
    }).toList();

    // Sort newest first
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    double total = 0;
    final items = <TransactionItemViewData>[];

    for (final tx in filtered) {
      total += tx.amount;
      final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull;
      final wallet = wallets.where((w) => w.id == tx.walletId).firstOrNull;

      final displayNote = (tx.note != null && tx.note!.isNotEmpty) ? tx.note! : (cat?.name ?? 'Giao dịch');

      items.add(
        TransactionItemViewData(
          id: tx.id,
          amount: tx.amount,
          type: tx.type,
          note: displayNote,
          categoryName: cat?.name ?? 'Khác',
          categoryIcon: cat?.icon ?? 'receipt',
          categoryColor: cat?.color ?? '#4CAF50',
          walletName: wallet?.name ?? 'Ví mặc định',
          date: tx.transactionDate,
        ),
      );
    }

    String title;
    switch (period) {
      case 'today':
        title = 'Giao dịch hôm nay';
        break;
      case 'yesterday':
        title = 'Giao dịch hôm qua';
        break;
      case 'this_week':
        title = 'Giao dịch tuần này';
        break;
      case 'this_month':
        title = 'Giao dịch tháng này';
        break;
      default:
        title = 'Danh sách giao dịch';
    }

    return TransactionListViewPayload(
      title: title,
      totalAmount: total,
      period: period,
      transactions: items,
    );
  }
}
