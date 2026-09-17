import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ai_message.dart';

/// Card rendering filtered list of transactions inside the AI chat stream.
class AiTransactionListCard extends StatelessWidget {
  final TransactionListViewPayload payload;
  final void Function(String transactionId)? onItemTap;

  const AiTransactionListCard({
    super.key,
    required this.payload,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final timeFormatter = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, size: 16, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              Text(
                payload.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                currencyFormatter.format(payload.totalAmount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Items or Empty State
          if (payload.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'Không có giao dịch nào trong khoảng thời gian này.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payload.transactions.length > 5 ? 5 : payload.transactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final tx = payload.transactions[index];
                final isExpense = tx.type == 'expense';
                final amountColor = isExpense ? Colors.red.shade600 : Colors.green.shade600;
                final sign = isExpense ? '-' : '+';

                return InkWell(
                  onTap: () => onItemTap?.call(tx.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.note,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${tx.categoryName} • ${tx.walletName} • ${timeFormatter.format(tx.date)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$sign${currencyFormatter.format(tx.amount)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          if (payload.transactions.length > 5) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                '+${payload.transactions.length - 5} giao dịch khác',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
