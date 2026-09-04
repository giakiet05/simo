import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/category_budget_screen.dart';
import '../../screens/loan_screen.dart';
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
        const SizedBox(height: 14),

        // Row 1: Ví tiền | Ngân sách | Sổ nợ
        Row(
          children: [
            Expanded(
              child: _buildAccessButton(
                context,
                icon: Icons.account_balance_wallet_rounded,
                label: l10n.locale == 'vi' ? 'Ví tiền' : 'Wallets',
                color: const Color(0xFF10B981), // Emerald Green
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccessButton(
                context,
                icon: Icons.pie_chart_rounded,
                label: l10n.locale == 'vi' ? 'Ngân sách' : 'Budgets',
                color: const Color(0xFF3B82F6), // Royal Blue
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryBudgetScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccessButton(
                context,
                icon: Icons.receipt_long_rounded,
                label: l10n.locale == 'vi' ? 'Sổ nợ' : 'Loans',
                color: const Color(0xFF8B5CF6), // Purple
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoanScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Mục tiêu | Định kỳ | Thống kê
        Row(
          children: [
            Expanded(
              child: _buildAccessButton(
                context,
                icon: Icons.savings_rounded,
                label: l10n.locale == 'vi' ? 'Mục tiêu' : 'Goals',
                color: const Color(0xFFF59E0B), // Warm Amber
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavingGoalsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccessButton(
                context,
                icon: Icons.autorenew_rounded,
                label: l10n.locale == 'vi' ? 'Định kỳ' : 'Recurring',
                color: const Color(0xFFEC4899), // Pink Rose
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecurringScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildAccessButton(
                context,
                icon: Icons.insights_rounded,
                label: l10n.locale == 'vi' ? 'Thống kê' : 'Insights',
                color: const Color(0xFF06B6D4), // Cyan
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: color.withValues(alpha: isDark ? 0.14 : 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
