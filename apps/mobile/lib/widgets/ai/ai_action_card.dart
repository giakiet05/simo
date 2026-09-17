import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ai_message.dart';

/// Widget rendering a structured action execution result within the AI message stream.
class AiActionCard extends StatelessWidget {
  final AiExecutedAction action;

  const AiActionCard({
    super.key,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isNegative = action.actionType == 'transaction' &&
        (action.rawAction?['type'] == 'expense' || action.rawAction?['type'] == null);

    final amountColor = isNegative
        ? Colors.red.shade600
        : (action.actionType == 'transaction' ? Colors.green.shade600 : Colors.blue.shade600);

    final sign = isNegative ? '-' : (action.actionType == 'transaction' ? '+' : '');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActionColor().withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActionIcon(),
              size: 20,
              color: _getActionColor(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 3),
                          Text(
                            'Đã lưu',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$sign${currencyFormatter.format(action.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    switch (action.actionType) {
      case 'transaction':
        final isExpense = action.rawAction?['type'] == 'expense' || action.rawAction?['type'] == null;
        return isExpense ? Icons.arrow_downward : Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'loan_create':
      case 'loan_repay':
        return Icons.handshake_outlined;
      case 'goal_deposit':
      case 'goal_withdraw':
        return Icons.savings_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getActionColor() {
    switch (action.actionType) {
      case 'transaction':
        final isExpense = action.rawAction?['type'] == 'expense' || action.rawAction?['type'] == null;
        return isExpense ? Colors.orange.shade700 : Colors.green.shade700;
      case 'transfer':
        return Colors.blue.shade700;
      case 'loan_create':
      case 'loan_repay':
        return Colors.purple.shade700;
      case 'goal_deposit':
      case 'goal_withdraw':
        return Colors.teal.shade700;
      default:
        return Colors.blueGrey;
    }
  }
}
