import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/localization_provider.dart';
import '../utils/localization.dart';
import '../widgets/banner_ad_widget.dart';
import 'category_budget_screen.dart';
import 'loan_screen.dart';
import 'recurring_screen.dart';
import 'saving_goals_screen.dart';
import 'statistics_screen.dart';
import 'wallets_screen.dart';

class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isVi = l10n.locale == 'vi';

    final items = [
      _FeatureItem(
        title: isVi ? 'Ví tiền' : 'Wallets',
        description: isVi
            ? 'Quản lý danh sách các tài khoản và ví chi tiêu'
            : 'Manage your accounts and expense wallets',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF10B981), // Emerald Green
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletsScreen()),
        ),
      ),
      _FeatureItem(
        title: isVi ? 'Ngân sách' : 'Budgets',
        description: isVi
            ? 'Thiết lập và kiểm soát hạn mức chi tiêu hàng tháng'
            : 'Set and monitor monthly spending limits',
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF3B82F6), // Royal Blue
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoryBudgetScreen()),
        ),
      ),
      _FeatureItem(
        title: isVi ? 'Sổ nợ' : 'Loans',
        description: isVi
            ? 'Theo dõi các khoản tiền vay và cho vay cần thu hồi'
            : 'Track borrowed debts and lent balances to collect',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoanScreen()),
        ),
      ),
      _FeatureItem(
        title: isVi ? 'Mục tiêu' : 'Goals',
        description: isVi
            ? 'Lên kế hoạch và theo dõi tiến độ tích lũy tài chính'
            : 'Plan and track future saving progress',
        icon: Icons.savings_rounded,
        color: const Color(0xFFF59E0B), // Warm Amber
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavingGoalsScreen()),
        ),
      ),
      _FeatureItem(
        title: isVi ? 'Định kỳ' : 'Recurring',
        description: isVi
            ? 'Lập lịch hóa đơn và giao dịch lặp lại tự động'
            : 'Schedule automated bills and recurring transactions',
        icon: Icons.autorenew_rounded,
        color: const Color(0xFFEC4899), // Pink Rose
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecurringScreen()),
        ),
      ),
      _FeatureItem(
        title: isVi ? 'Thống kê' : 'Insights',
        description: isVi
            ? 'Báo cáo chi tiết và biểu đồ phân tích cơ cấu chi tiêu'
            : 'Detailed reports and spending breakdown analytics',
        icon: Icons.insights_rounded,
        color: const Color(0xFF06B6D4), // Cyan
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n is AppLocalizations ? l10n.featuresHub : 'Chức năng',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color
                                  .withValues(alpha: isDark ? 0.22 : 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.65),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const BannerAdWidget(key: ValueKey('features_banner_ad')),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
