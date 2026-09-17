import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ai_message.dart';

/// Widget rendering a structured action execution result within the AI message stream.
class AiActionCard extends StatelessWidget {
  final AiExecutedAction action;
  final void Function(AiExecutedAction)? onTap;

  const AiActionCard({
    super.key,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isNegative = (action.actionType == 'transaction' || action.actionType == 'transaction_create') &&
        (action.rawAction?['type'] == 'expense' || action.rawAction?['type'] == null);

    final amountColor = isNegative
        ? Colors.red.shade600
        : (action.actionType.startsWith('transaction') ? Colors.green.shade600 : Colors.blue.shade600);

    final sign = isNegative ? '-' : (action.actionType.startsWith('transaction') ? '+' : '');
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap != null ? () => onTap!(action) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                          Expanded(
                            child: Text(
                              action.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (action.amount > 0) ...[
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
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon() {
    switch (action.actionType) {
      case 'transaction':
      case 'transaction_create':
      case 'transaction_update':
      case 'transaction_delete':
        final isExpense = action.rawAction?['type'] == 'expense' || action.rawAction?['type'] == null;
        return isExpense ? Icons.arrow_downward : Icons.arrow_upward;
      case 'category_create':
      case 'category_update':
      case 'category_delete':
        return Icons.category_outlined;
      case 'wallet_create':
      case 'wallet_adjust_balance':
        return Icons.account_balance_wallet_outlined;
      case 'transfer':
        return Icons.swap_horiz;
      case 'budget_set':
        return Icons.pie_chart_outline;
      case 'loan_create':
      case 'loan_repay':
        return Icons.handshake_outlined;
      case 'goal_create':
      case 'goal_deposit':
      case 'goal_withdraw':
        return Icons.savings_outlined;
      case 'recurring_create':
        return Icons.update;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getActionColor() {
    switch (action.actionType) {
      case 'transaction':
      case 'transaction_create':
      case 'transaction_update':
      case 'transaction_delete':
        final isExpense = action.rawAction?['type'] == 'expense' || action.rawAction?['type'] == null;
        return isExpense ? Colors.orange.shade700 : Colors.green.shade700;
      case 'category_create':
      case 'category_update':
      case 'category_delete':
        return Colors.indigo.shade600;
      case 'wallet_create':
      case 'wallet_adjust_balance':
      case 'transfer':
        return Colors.blue.shade700;
      case 'budget_set':
        return Colors.amber.shade800;
      case 'loan_create':
      case 'loan_repay':
        return Colors.purple.shade700;
      case 'goal_create':
      case 'goal_deposit':
      case 'goal_withdraw':
        return Colors.teal.shade700;
      case 'recurring_create':
        return Colors.deepPurple.shade600;
      default:
        return Colors.blueGrey;
    }
  }
}
