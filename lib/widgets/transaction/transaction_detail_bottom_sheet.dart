import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../providers/category_provider.dart';
import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/currency_service.dart';
import '../category_icon_widget.dart';

/// Modal bottom sheet displaying comprehensive details of a single transaction
/// including category, wallet, amount, formula, note, timestamps, and action buttons.
class TransactionDetailBottomSheet extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionDetailBottomSheet({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  /// Displays the transaction detail bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Transaction transaction,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailBottomSheet(
        transaction: transaction,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  String _formatDayOfWeek(DateTime date, dynamic l10n) {
    if (l10n.locale == 'vi') {
      const weekdays = [
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      return weekdays[date.weekday - 1];
    } else {
      return DateFormat('EEEE').format(date);
    }
  }

  String _getWalletTypeLabel(String type, dynamic l10n) {
    switch (type) {
      case 'bank':
        return l10n.walletBank;
      case 'ewallet':
        return l10n.walletEwallet;
      case 'credit':
        return l10n.walletCredit;
      case 'savings':
        return l10n.walletSavings;
      case 'cash':
        return l10n.walletCash;
      default:
        return l10n.walletOther;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final walletsAsync = ref.watch(walletProvider);

    final currency = settingsAsync.valueOrNull?.currency ?? 'VND';
    final symbol = CurrencyService.getSymbol(currency);
    final isIncome = transaction.type == 'income';
    final formattedAmount =
        NumberFormat('#,###', 'en_US').format(transaction.amount);

    final categories = categoriesAsync.valueOrNull ?? <Category>[];
    Category? category;
    if (transaction.categoryId != null) {
      try {
        category = categories.firstWhere((c) => c.id == transaction.categoryId);
      } catch (_) {
        category = null;
      }
    }

    final categoryName = category != null
        ? l10n.translateCategoryName(category.id, category.name)
        : l10n.noCategory;

    final wallets = walletsAsync.valueOrNull ?? <Wallet>[];
    Wallet? wallet;
    if (transaction.walletId != null) {
      try {
        wallet = wallets.firstWhere((w) => w.id == transaction.walletId);
      } catch (_) {
        wallet = null;
      }
    }

    final cardBgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : Colors.grey.shade50;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Top Bar with Title & Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    l10n.locale == 'vi'
                        ? 'Chi tiết giao dịch'
                        : 'Transaction Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount and Category Overview Hero
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          CategoryIconWidget(
                            category: category,
                            iconName: category == null
                                ? (isIncome ? 'attach_money' : 'shopping_cart')
                                : null,
                            size: 48,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Amount
                          Text(
                            '${isIncome ? '+' : '-'} $formattedAmount $symbol',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.red,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isIncome ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isIncome
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 14,
                                  color: isIncome ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isIncome ? l10n.income : l10n.expense,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Metadata Details Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Note
                          _buildDetailRow(
                            context: context,
                            icon: Icons.notes_rounded,
                            iconColor: Colors.blueAccent,
                            label: l10n.note,
                            value: (transaction.note != null &&
                                    transaction.note!.trim().isNotEmpty)
                                ? transaction.note!
                                : (l10n.locale == 'vi'
                                    ? 'Không có nội dung'
                                    : 'No note'),
                            isDimmed: transaction.note == null ||
                                transaction.note!.trim().isEmpty,
                          ),
                          _buildDivider(isDark),

                          // Formula / Math Operation (if present)
                          if (transaction.formula != null &&
                              transaction.formula!.trim().isNotEmpty &&
                              transaction.formula!.trim() !=
                                  transaction.amount.toString()) ...[
                            _buildDetailRow(
                              context: context,
                              icon: Icons.calculate_outlined,
                              iconColor: Colors.purple,
                              label: l10n.locale == 'vi'
                                  ? 'Phép tính'
                                  : 'Formula',
                              value: transaction.formula!,
                            ),
                            _buildDivider(isDark),
                          ],

                          // Wallet
                          _buildDetailRow(
                            context: context,
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: Colors.teal,
                            label: l10n.wallet,
                            value: wallet?.name ??
                                (l10n.locale == 'vi'
                                    ? 'Ví tiền mặt'
                                    : 'Default cash wallet'),
                            trailing: wallet != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _getWalletTypeLabel(wallet.type, l10n),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          _buildDivider(isDark),

                          // Transaction Date & Time
                          _buildDetailRow(
                            context: context,
                            icon: Icons.calendar_today_outlined,
                            iconColor: Colors.orange,
                            label: l10n.transactionDateLabel,
                            value:
                                '${_formatDayOfWeek(transaction.transactionDate, l10n)}, ${DateFormat('dd/MM/yyyy • HH:mm').format(transaction.transactionDate)}',
                          ),
                          _buildDivider(isDark),

                          // Recurring Indicator (if any)
                          if (transaction.recurringConfigId != null) ...[
                            _buildDetailRow(
                              context: context,
                              icon: Icons.replay_rounded,
                              iconColor: Colors.indigo,
                              label: l10n.locale == 'vi'
                                  ? 'Định kỳ'
                                  : 'Recurring',
                              value: l10n.locale == 'vi'
                                  ? 'Tự động tạo từ cấu hình định kỳ'
                                  : 'Auto-generated from schedule',
                            ),
                            _buildDivider(isDark),
                          ],

                          // Created At
                          _buildDetailRow(
                            context: context,
                            icon: Icons.access_time_rounded,
                            iconColor: Colors.grey,
                            label: l10n.createdAtLabel,
                            value: DateFormat('dd/MM/yyyy HH:mm:ss')
                                .format(transaction.createdAt),
                          ),
                          _buildDivider(isDark),

                          // Updated At
                          _buildDetailRow(
                            context: context,
                            icon: Icons.update_rounded,
                            iconColor: Colors.grey,
                            label: l10n.updatedAtLabel,
                            value: DateFormat('dd/MM/yyyy HH:mm:ss')
                                .format(transaction.updatedAt),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  // Delete Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      label: Text(
                        l10n.delete,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Edit Button (Primary)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: Text(
                        l10n.edit,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit?.call();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 52,
      endIndent: 16,
      color: isDark ? Colors.grey[800] : Colors.grey[200],
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isDimmed = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDimmed
                        ? (isDark ? Colors.grey[500] : Colors.grey[400])
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
