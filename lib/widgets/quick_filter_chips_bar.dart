import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter_criteria.dart';
import '../models/wallet.dart';

class QuickFilterChipsBar extends StatelessWidget {
  final TransactionFilterCriteria criteria;
  final List<Wallet> wallets;
  final ValueChanged<TransactionFilterCriteria> onFilterChanged;
  final VoidCallback onOpenFilterSheet;
  final dynamic l10n;

  const QuickFilterChipsBar({
    super.key,
    required this.criteria,
    required this.wallets,
    required this.onFilterChanged,
    required this.onOpenFilterSheet,
    required this.l10n,
  });

  String _getTimeLabel(bool isVi) {
    switch (criteria.timeMode) {
      case TimeFilterMode.all:
        return isVi ? 'Thời gian: Tất cả ▾' : 'Time: All ▾';
      case TimeFilterMode.today:
        return isVi ? 'Hôm nay ▾' : 'Today ▾';
      case TimeFilterMode.thisWeek:
        return isVi ? 'Tuần này ▾' : 'This week ▾';
      case TimeFilterMode.thisMonth:
        return isVi ? 'Tháng này ▾' : 'This month ▾';
      case TimeFilterMode.lastMonth:
        return isVi ? 'Tháng trước ▾' : 'Last month ▾';
      case TimeFilterMode.thisYear:
        return isVi ? 'Năm nay ▾' : 'This year ▾';
      case TimeFilterMode.customMonth:
        if (criteria.customMonth != null) {
          return '${isVi ? "Tháng " : "M "}${DateFormat('MM/yyyy').format(criteria.customMonth!)} ▾';
        }
        return isVi ? 'Chọn tháng ▾' : 'Custom month ▾';
      case TimeFilterMode.customDateRange:
        if (criteria.startDate != null && criteria.endDate != null) {
          return '${DateFormat('dd/MM').format(criteria.startDate!)}-${DateFormat('dd/MM').format(criteria.endDate!)} ▾';
        }
        return isVi ? 'Khoảng ngày ▾' : 'Date range ▾';
    }
  }

  String _getWalletLabel(bool isVi) {
    if (criteria.selectedWalletIds.isEmpty) {
      return isVi ? 'Tất cả ví ▾' : 'All wallets ▾';
    }
    if (criteria.selectedWalletIds.length == 1) {
      final wid = criteria.selectedWalletIds.first;
      final match = wallets.where((w) => w.id == wid).toList();
      if (match.isNotEmpty) {
        return '${match.first.name} ▾';
      }
    }
    return '${criteria.selectedWalletIds.length} ${isVi ? "ví" : "wallets"} ▾';
  }

  String _getTypeLabel(bool isVi) {
    if (criteria.type == 'expense') {
      return '${l10n.expense} ▾';
    } else if (criteria.type == 'income') {
      return '${l10n.income} ▾';
    }
    return '${l10n.allTypes} ▾';
  }

  void _showWalletPicker(BuildContext context, bool isVi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.teal),
                  title: Text(isVi ? 'Tất cả ví' : 'All wallets'),
                  trailing: criteria.selectedWalletIds.isEmpty
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                  onTap: () {
                    onFilterChanged(criteria.copyWith(selectedWalletIds: const {}));
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(),
                ...wallets.map((w) {
                  final isSelected = criteria.selectedWalletIds.contains(w.id);
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(w.name),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
                    onTap: () {
                      onFilterChanged(criteria.copyWith(selectedWalletIds: {w.id}));
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimePicker(BuildContext context, bool isVi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _timeTile(ctx, isVi ? 'Tất cả thời gian' : 'All time', TimeFilterMode.all),
                _timeTile(ctx, isVi ? 'Hôm nay' : 'Today', TimeFilterMode.today),
                _timeTile(ctx, isVi ? 'Tuần này' : 'This week', TimeFilterMode.thisWeek),
                _timeTile(ctx, isVi ? 'Tháng này' : 'This month', TimeFilterMode.thisMonth),
                _timeTile(ctx, isVi ? 'Tháng trước' : 'Last month', TimeFilterMode.lastMonth),
                _timeTile(ctx, isVi ? 'Năm nay' : 'This year', TimeFilterMode.thisYear),
                ListTile(
                  leading: const Icon(Icons.more_horiz, color: Colors.teal),
                  title: Text(isVi ? 'Tùy chọn khác (chọn tháng, khoảng ngày)...' : 'More options...'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onOpenFilterSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _timeTile(BuildContext ctx, String label, TimeFilterMode mode) {
    final isSelected = criteria.timeMode == mode;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      onTap: () {
        onFilterChanged(criteria.copyWith(
          timeMode: mode,
          clearCustomMonth: true,
          clearStartDate: true,
          clearEndDate: true,
        ));
        Navigator.pop(ctx);
      },
    );
  }

  void _showTypePicker(BuildContext context, bool isVi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l10n.allTypes),
                  trailing: criteria.type == null ? const Icon(Icons.check, color: Colors.teal) : null,
                  onTap: () {
                    onFilterChanged(criteria.copyWith(clearType: true));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: Text(l10n.expense),
                  trailing: criteria.type == 'expense' ? const Icon(Icons.check, color: Colors.teal) : null,
                  onTap: () {
                    onFilterChanged(criteria.copyWith(type: 'expense'));
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: Text(l10n.income),
                  trailing: criteria.type == 'income' ? const Icon(Icons.check, color: Colors.teal) : null,
                  onTap: () {
                    onFilterChanged(criteria.copyWith(type: 'income'));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = l10n.locale == 'vi';
    final activeCount = criteria.activeFilterCount;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withAlpha(50),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Nút mở bộ lọc tổng hợp (Tune icon + badge)
          ActionChip(
            avatar: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune, size: 16),
                if (activeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: Text(isVi ? 'Bộ lọc' : 'Filter'),
            backgroundColor: activeCount > 0 ? Colors.teal.withAlpha(40) : null,
            onPressed: onOpenFilterSheet,
          ),
          const SizedBox(width: 8),

          // Chip chọn nhanh Ví
          ActionChip(
            label: Text(_getWalletLabel(isVi)),
            backgroundColor: criteria.selectedWalletIds.isNotEmpty ? Colors.teal.withAlpha(40) : null,
            onPressed: () => _showWalletPicker(context, isVi),
          ),
          const SizedBox(width: 8),

          // Chip chọn nhanh Thời gian
          ActionChip(
            label: Text(_getTimeLabel(isVi)),
            backgroundColor: criteria.timeMode != TimeFilterMode.all ? Colors.teal.withAlpha(40) : null,
            onPressed: () => _showTimePicker(context, isVi),
          ),
          const SizedBox(width: 8),

          // Chip chọn nhanh Loại (Thu / Chi)
          ActionChip(
            label: Text(_getTypeLabel(isVi)),
            backgroundColor: criteria.type != null ? Colors.teal.withAlpha(40) : null,
            onPressed: () => _showTypePicker(context, isVi),
          ),

          // Chip xóa bộ lọc nếu đang có filter hoạt động
          if (activeCount > 0) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.close, size: 14, color: Colors.grey),
              label: Text(isVi ? 'Xóa lọc' : 'Clear'),
              onPressed: () {
                onFilterChanged(
                  criteria.copyWith(
                    selectedWalletIds: const {},
                    selectedCategoryIds: const {},
                    clearType: true,
                    timeMode: TimeFilterMode.all,
                    clearCustomMonth: true,
                    clearStartDate: true,
                    clearEndDate: true,
                    clearMinAmount: true,
                    clearMaxAmount: true,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
