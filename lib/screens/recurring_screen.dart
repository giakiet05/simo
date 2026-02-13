import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/recurring_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/recurring_config.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTransactions),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(l10n.add, style: const TextStyle(color: Colors.black)),
              ),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        data: (categories) {
          return recurringAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
            data: (configs) {
              final categoryMap = {
                for (var cat in categories) cat.id: cat
              };

              return Column(
                children: [
                  if (configs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.longPressHint,
                              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.amber[50],
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.noCategoriesWarning,
                              style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: configs.isEmpty
                        ? Center(child: Text(l10n.noRecurring))
                        : ListView.builder(
                      itemCount: configs.length,
                      itemBuilder: (context, index) {
                        final config = configs[index];
                        final category = config.categoryId != null ? categoryMap[config.categoryId] : null;
                        final categoryName = category != null
                            ? l10n.translateCategoryName(category.id, category.name)
                            : l10n.noCategory;

                        // Get icon and color
                        final iconData = category != null
                            ? (CategoryIconData.getIcon(category.icon) ??
                                (config.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward))
                            : (config.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

                        Color backgroundColor;
                        if (category?.color != null && category!.color!.isNotEmpty) {
                          try {
                            backgroundColor = Color(int.parse(category.color!.substring(1), radix: 16) + 0xFF000000);
                          } catch (e) {
                            backgroundColor = config.type == 'income' ? Colors.green : Colors.red;
                          }
                        } else {
                          backgroundColor = config.type == 'income' ? Colors.green : Colors.red;
                        }

                        final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
                            ? Colors.black
                            : Colors.white;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: backgroundColor,
                              child: Icon(
                                iconData,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              config.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(categoryName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(_formatAmount(config.amount), style: const TextStyle(fontSize: 14)),
                                Text(_formatFrequency(ref, config), style: const TextStyle(fontSize: 13)),
                                Text(
                                  '${l10n.nextRun}: ${DateFormat('dd/MM/yyyy').format(config.nextRun)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Switch(
                              value: config.isActive,
                              onChanged: (value) {
                                ref
                                    .read(recurringProvider.notifier)
                                    .toggleActive(config.id, value);
                              },
                            ),
                            onLongPress: () => _showActionMenu(context, ref, config),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showActionMenu(BuildContext context, WidgetRef ref, RecurringConfig config) {
    final l10n = ref.read(localizationProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.green),
              title: Text(l10n.runNow, style: const TextStyle(color: Colors.green)),
              onTap: () {
                Navigator.pop(context);
                _showRunNowDialog(context, ref, config);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, config);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref, config);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRunNowDialog(BuildContext context, WidgetRef ref, RecurringConfig config) {
    final l10n = ref.read(localizationProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.runNow),
        content: Text(l10n.runNowConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await ref
                    .read(recurringProvider.notifier)
                    .triggerRecurringNow(config.id);

                // Refresh transaction provider
                ref.read(transactionProvider.notifier).loadTransactions();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.transactionTriggered)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.runNow),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  String _formatFrequency(WidgetRef ref, RecurringConfig config) {
    final l10n = ref.read(localizationProvider);
    String freq;

    // Get unit with correct plural form
    String unit;
    if (config.frequency == 'daily') {
      unit = config.interval == 1 ? l10n.day : l10n.days;
    } else if (config.frequency == 'weekly') {
      unit = config.interval == 1 ? l10n.week : l10n.weeks;
    } else {
      unit = config.interval == 1 ? l10n.month : l10n.months;
    }

    // Build frequency string
    freq = '${l10n.every} ${config.interval} $unit';

    // Add day/weekday info
    if (config.frequency == 'weekly' && config.dayOfWeek != null) {
      final days = [
        l10n.sunday,
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
      ];
      freq += ' - ${days[config.dayOfWeek! % 7]}';
    } else if (config.frequency == 'monthly' && config.dayOfMonth != null) {
      freq += ' - ${l10n.day} ${config.dayOfMonth}';
    }

    return freq;
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    _showFormDialog(context, ref, null);
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, RecurringConfig config) {
    _showFormDialog(context, ref, config);
  }

  void _showFormDialog(
      BuildContext context, WidgetRef ref, RecurringConfig? config) {
    showDialog(
      context: context,
      builder: (context) => _RecurringFormDialog(config: config),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, RecurringConfig config) {
    final l10n = ref.read(localizationProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecurring),
        content: Text('${l10n.deleteRecurringConfirm} "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(recurringProvider.notifier)
                    .deleteRecurringConfig(config.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.recurringDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _RecurringFormDialog extends ConsumerStatefulWidget {
  final RecurringConfig? config;

  const _RecurringFormDialog({this.config});

  @override
  ConsumerState<_RecurringFormDialog> createState() =>
      _RecurringFormDialogState();
}

class _RecurringFormDialogState extends ConsumerState<_RecurringFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _intervalController;

  String? _selectedCategoryId;
  String _selectedType = 'expense';
  String _selectedFrequency = 'monthly';
  int _interval = 1;
  int? _dayOfWeek;
  int? _dayOfMonth;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');

    // Format amount with comma
    String amountText = '';
    if (widget.config != null) {
      final amount = widget.config!.amount;
      if (amount == amount.toInt()) {
        amountText = NumberFormat('#,###').format(amount.toInt());
      } else {
        amountText = amount.toString();
      }
    }
    _amountController = TextEditingController(text: amountText);

    _intervalController =
        TextEditingController(text: widget.config?.interval.toString() ?? '1');

    if (widget.config != null) {
      _selectedCategoryId = widget.config!.categoryId;
      _selectedType = widget.config!.type;
      _selectedFrequency = widget.config!.frequency;
      _interval = widget.config!.interval;
      _dayOfWeek = widget.config!.dayOfWeek;
      _dayOfMonth = widget.config!.dayOfMonth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  String _formatAmountForDisplay(double amount) {
    if (amount == amount.toInt()) {
      return NumberFormat('#,###').format(amount.toInt());
    }
    return NumberFormat('#,###.##').format(amount);
  }

  void _onAmountChanged(String value) {
    final cleanValue = value.replaceAll(',', '');
    final numValue = double.tryParse(cleanValue);

    if (numValue != null) {
      final formatted = _formatAmountForDisplay(numValue);
      if (formatted != value) {
        final cursorPos = _amountController.selection.baseOffset;
        final oldCommas = value.substring(0, cursorPos).split(',').length - 1;

        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: cursorPos + (formatted.split(',').length - 1 - oldCommas),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 650,
          maxHeight: 620,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Text(
                widget.config == null ? l10n.addRecurring : l10n.editRecurring,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.name,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              onChanged: _onAmountChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.type,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                DropdownMenuItem(value: 'income', child: Text(l10n.income)),
                DropdownMenuItem(value: 'expense', child: Text(l10n.expense)),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('${l10n.error}: $error'),
              data: (categories) {
                // Filter categories based on selected type
                final filteredCategories = categories.where((cat) => cat.type == _selectedType).toList();

                // Check if current categoryId exists in filtered categories, if not set to null
                if (_selectedCategoryId != null &&
                    !filteredCategories.any((cat) => cat.id == _selectedCategoryId)) {
                  _selectedCategoryId = null;
                }

                return DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: l10n.categoryOptional,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.noCategory),
                    ),
                    ...filteredCategories.map((category) {
                      final displayName = l10n.translateCategoryName(category.id, category.name);

                      // Get icon and color
                      final iconData = CategoryIconData.getIcon(category.icon) ??
                          (category.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

                      Color backgroundColor;
                      if (category.color != null && category.color!.isNotEmpty) {
                        try {
                          backgroundColor = Color(int.parse(category.color!.substring(1), radix: 16) + 0xFF000000);
                        } catch (e) {
                          backgroundColor = category.type == 'income' ? Colors.green : Colors.red;
                        }
                      } else {
                        backgroundColor = category.type == 'income' ? Colors.green : Colors.red;
                      }

                      final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
                          ? Colors.black
                          : Colors.white;

                      return DropdownMenuItem(
                        value: category.id,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconData,
                                color: iconColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(displayName),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                labelText: l10n.frequency,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: [
                DropdownMenuItem(value: 'daily', child: Text(l10n.byDay)),
                DropdownMenuItem(value: 'weekly', child: Text(l10n.byWeek)),
                DropdownMenuItem(value: 'monthly', child: Text(l10n.byMonth)),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                  _dayOfWeek = null;
                  _dayOfMonth = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _intervalController,
              decoration: InputDecoration(
                labelText: l10n.interval,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _interval = int.tryParse(value) ?? 1;
              },
            ),
            const SizedBox(height: 16),
            if (_selectedFrequency == 'weekly')
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                decoration: InputDecoration(
                  labelText: l10n.dayOfWeek,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.sunday)),
                  DropdownMenuItem(value: 1, child: Text(l10n.monday)),
                  DropdownMenuItem(value: 2, child: Text(l10n.tuesday)),
                  DropdownMenuItem(value: 3, child: Text(l10n.wednesday)),
                  DropdownMenuItem(value: 4, child: Text(l10n.thursday)),
                  DropdownMenuItem(value: 5, child: Text(l10n.friday)),
                  DropdownMenuItem(value: 6, child: Text(l10n.saturday)),
                ],
                onChanged: (value) {
                  setState(() {
                    _dayOfWeek = value;
                  });
                },
              ),
            if (_selectedFrequency == 'monthly')
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.dayOfMonth,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final day = int.tryParse(value);
                  if (day != null && day >= 1 && day <= 31) {
                    _dayOfMonth = day;
                  }
                },
                controller: TextEditingController(
                  text: _dayOfMonth?.toString() ?? '',
                ),
              ),
          ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final l10n = ref.read(localizationProvider);
                      final name = _nameController.text.trim();
                      final amountText = _amountController.text.trim().replaceAll(',', '');
                      final amount = double.tryParse(amountText);

                      if (name.isEmpty || amount == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.fillAllFields)),
                        );
                        return;
                      }

                      try {
                        if (widget.config == null) {
                          await ref.read(recurringProvider.notifier).createRecurringConfig(
                                categoryId: _selectedCategoryId,
                                name: name,
                                amount: amount,
                                type: _selectedType,
                                frequency: _selectedFrequency,
                                interval: _interval,
                                dayOfWeek: _dayOfWeek,
                                dayOfMonth: _dayOfMonth,
                              );
                        } else {
                          await ref.read(recurringProvider.notifier).updateRecurringConfig(
                                widget.config!.id,
                                categoryId: _selectedCategoryId,
                                name: name,
                                amount: amount,
                                type: _selectedType,
                                frequency: _selectedFrequency,
                                interval: _interval,
                                dayOfWeek: _dayOfWeek,
                                dayOfMonth: _dayOfMonth,
                              );
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.config == null
                                  ? l10n.recurringCreated
                                  : l10n.recurringUpdated),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l10n.error}: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
