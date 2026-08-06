import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/home_screen.dart';
import '../../screens/category_screen.dart';
import '../../screens/recurring_screen.dart';
import '../../screens/statistics_screen.dart';
import 'budget_sheet.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAccessButton(
              context,
              icon: Icons.pie_chart_outline,
              label: l10n.locale == 'vi' ? 'Ngân sách' : 'Budgets',
              color: AppColors.secondary,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const BudgetSheet(),
                );
              },
            ),
            _buildAccessButton(
              context,
              icon: Icons.category_outlined,
              label: l10n.locale == 'vi' ? 'Danh mục' : 'Categories',
              color: AppColors.warning,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
              },
            ),
            _buildAccessButton(
              context,
              icon: Icons.autorenew,
              label: l10n.locale == 'vi' ? 'Định kỳ' : 'Recurring',
              color: AppColors.income,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringScreen()));
              },
            ),
            _buildAccessButton(
              context,
              icon: Icons.insights,
              label: l10n.locale == 'vi' ? 'Thống kê' : 'Insights',
              color: AppColors.info,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccessButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
