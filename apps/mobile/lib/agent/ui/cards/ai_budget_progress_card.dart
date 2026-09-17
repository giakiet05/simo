import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ai_message.dart';

/// Card rendering monthly budget progress and category limits inside the AI chat stream.
class AiBudgetProgressCard extends StatelessWidget {
  final BudgetProgressViewPayload payload;
  final VoidCallback? onBudgetTap;

  const AiBudgetProgressCard({
    super.key,
    required this.payload,
    this.onBudgetTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    Color progressColor;
    if (payload.totalPercentage > 1.0) {
      progressColor = Colors.red.shade600;
    } else if (payload.totalPercentage > 0.8) {
      progressColor = Colors.amber.shade700;
    } else {
      progressColor = Colors.green.shade600;
    }

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
                  color: Colors.purple.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart_outline, size: 16, color: Colors.purple),
              ),
              const SizedBox(width: 8),
              Text(
                'Ngân sách ${payload.month}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(payload.totalPercentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: payload.totalPercentage.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã tiêu: ${currencyFormatter.format(payload.totalSpent)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Text(
                'Hạn mức: ${currencyFormatter.format(payload.totalLimit)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),

          // Category items
          if (payload.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payload.categories.length > 4 ? 4 : payload.categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final cat = payload.categories[index];
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat.categoryName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${currencyFormatter.format(cat.spentAmount)} / ${currencyFormatter.format(cat.limitAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cat.percentage > 1.0 ? Colors.red : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
