import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/saving_goal.dart';
import '../services/currency_service.dart';

class SavingGoalCard extends StatelessWidget {
  final SavingGoal goal;
  final String currency;
  final dynamic l10n;
  final VoidCallback onTap;

  const SavingGoalCard({
    super.key,
    required this.goal,
    required this.currency,
    required this.l10n,
    required this.onTap,
  });

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.teal;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.teal;
    }
  }

  IconData _getIconData(String? iconKey) {
    switch (iconKey) {
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'vacation':
        return Icons.beach_access_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'savings':
      default:
        return Icons.savings_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyService.getSymbol(currency);
    final numberFormat = NumberFormat('#,###');
    final color = _parseColor(goal.color);
    final iconData = _getIconData(goal.icon);

    final percent = (goal.progressPercentage * 100).toStringAsFixed(1);
    final isCompleted = goal.isCompleted;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Name + Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (goal.targetDate != null)
                          Text(
                            goal.isOverdue
                                ? (l10n.locale == 'vi' ? 'Quá hạn chót' : 'Overdue')
                                : '${l10n.targetDate}: ${DateFormat('dd/MM/yyyy').format(goal.targetDate!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: goal.isOverdue ? Colors.red : Colors.grey[600],
                              fontWeight: goal.isOverdue ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            l10n.goalCompleted,
                            style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progressPercentage,
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.currentSaved,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '${numberFormat.format(goal.currentAmount)} $currencySymbol',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.targetAmount,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '${numberFormat.format(goal.targetAmount)} $currencySymbol',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Recommended monthly pace hint
              if (!isCompleted && goal.recommendedMonthlyPace != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.locale == 'vi'
                              ? 'Cần ~${numberFormat.format(goal.recommendedMonthlyPace!)} $currencySymbol/tháng để kịp hạn'
                              : 'Need ~${numberFormat.format(goal.recommendedMonthlyPace!)} $currencySymbol/mo to finish on time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
