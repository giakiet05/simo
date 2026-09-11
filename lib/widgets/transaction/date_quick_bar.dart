import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/localization_provider.dart';

/// A horizontal scrollable date shortcut selector displaying the calendar picker button
/// and quick date chips ('Today', 'Yesterday', '2 days ago', 'Original Date').
class DateQuickChipsBar extends ConsumerWidget {
  /// The currently active transaction date.
  final DateTime selectedDate;

  /// The original record date if in edit mode (enables rollback).
  final DateTime? originalDate;

  /// Callback when date changes.
  final ValueChanged<DateTime> onDateChanged;

  const DateQuickChipsBar({
    super.key,
    required this.selectedDate,
    this.originalDate,
    required this.onDateChanged,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final isToday = _isSameDay(selectedDate, now);
    final isYesterday = _isSameDay(selectedDate, now.subtract(const Duration(days: 1)));
    final isTwoDaysAgo = _isSameDay(selectedDate, now.subtract(const Duration(days: 2)));
    final isOriginal = originalDate != null && _isSameDay(selectedDate, originalDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.locale == 'vi' ? 'Ngày' : 'Date',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Primary Calendar Picker Chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: Locale(l10n.locale),
                      );
                      if (picked != null) {
                        final updated = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          selectedDate.hour,
                          selectedDate.minute,
                          selectedDate.second,
                        );
                        onDateChanged(updated);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_calendar_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Original Date Button (Edit Mode)
              if (originalDate != null)
                _buildQuickChip(
                  label: '${l10n.originalDate}: ${DateFormat('dd/MM').format(originalDate!)}',
                  isSelected: isOriginal,
                  theme: theme,
                  isDark: isDark,
                  isHighlight: true,
                  onTap: () => onDateChanged(originalDate!),
                ),

              // Today Button
              _buildQuickChip(
                label: l10n.locale == 'vi' ? 'Hôm nay' : 'Today',
                isSelected: isToday,
                theme: theme,
                isDark: isDark,
                onTap: () {
                  final updated = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedDate.hour,
                    selectedDate.minute,
                    selectedDate.second,
                  );
                  onDateChanged(updated);
                },
              ),

              // Yesterday Button
              _buildQuickChip(
                label: l10n.locale == 'vi' ? 'Hôm qua' : 'Yesterday',
                isSelected: isYesterday,
                theme: theme,
                isDark: isDark,
                onTap: () {
                  final yesterday = now.subtract(const Duration(days: 1));
                  final updated = DateTime(
                    yesterday.year,
                    yesterday.month,
                    yesterday.day,
                    selectedDate.hour,
                    selectedDate.minute,
                    selectedDate.second,
                  );
                  onDateChanged(updated);
                },
              ),

              // 2 Days Ago Button
              _buildQuickChip(
                label: l10n.locale == 'vi' ? '2 ngày trước' : '2 days ago',
                isSelected: isTwoDaysAgo,
                theme: theme,
                isDark: isDark,
                onTap: () {
                  final target = now.subtract(const Duration(days: 2));
                  final updated = DateTime(
                    target.year,
                    target.month,
                    target.day,
                    selectedDate.hour,
                    selectedDate.minute,
                    selectedDate.second,
                  );
                  onDateChanged(updated);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required ThemeData theme,
    required bool isDark,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    final activeColor = isHighlight ? Colors.orange : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? Colors.grey[850] : Colors.grey[100]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.grey[750]! : Colors.grey[300]!),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: activeColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : (isHighlight
                            ? Colors.orange.shade800
                            : (isDark ? Colors.grey[200] : Colors.grey[800])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
