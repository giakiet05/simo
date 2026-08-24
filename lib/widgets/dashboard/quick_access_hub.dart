import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/category_budget_screen.dart';
import '../../screens/recurring_screen.dart';
import '../../screens/saving_goals_screen.dart';
import '../../screens/statistics_screen.dart';
import '../../screens/wallets_screen.dart';

class QuickAccessHub extends StatelessWidget {
  final dynamic l10n;

  const QuickAccessHub({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.locale == 'vi' ? 'Truy cập nhanh' : 'Quick Access',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildAccessButton(
                context,
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.locale == 'vi' ? 'Ví tiền' : 'Wallets',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildAccessButton(
                context,
                icon: Icons.pie_chart_outline,
                label: l10n.locale == 'vi' ? 'Ngân sách' : 'Budgets',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryBudgetScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildAccessButton(
                context,
                icon: Icons.savings_outlined,
                label: l10n.locale == 'vi' ? 'Mục tiêu' : 'Goals',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavingGoalsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildAccessButton(
                context,
                icon: Icons.autorenew,
                label: l10n.locale == 'vi' ? 'Định kỳ' : 'Recurring',
                color: AppColors.income,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecurringScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildAccessButton(
                context,
                icon: Icons.insights,
                label: l10n.locale == 'vi' ? 'Thống kê' : 'Insights',
                color: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Material(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
