import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/recurring_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/recurring_config.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTransactions),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton.icon(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(l10n.add, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        data: (configs) {
          if (configs.isEmpty) {
            return Center(
              child: Text(l10n.noRecurring),
            );
          }

          return Column(
            children: [
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
              Expanded(
                child: ListView.builder(
                  itemCount: configs.length,
                  itemBuilder: (context, index) {
                    final config = configs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          config.type == 'income'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: config.type == 'income' ? Colors.green : Colors.red,
                        ),
                        title: Text(config.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatAmount(config.amount)} - ${_formatFrequency(ref, config)}',
                            ),
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

  String _formatAmount(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  String _formatFrequency(WidgetRef ref, RecurringConfig config) {
    final l10n = ref.read(localizationProvider);
    String freq = config.frequency;

    String freqTranslated;
    if (config.frequency == 'daily') {
      freqTranslated = l10n.daily;
    } else if (config.frequency == 'weekly') {
      freqTranslated = l10n.weekly;
    } else {
      freqTranslated = l10n.monthly;
    }

    if (config.interval > 1) {
      freq = '${l10n.every} ${config.interval} $freqTranslated';
    } else {
      freq = '${l10n.every} $freqTranslated';
    }

    if (config.frequency == 'weekly' && config.dayOfWeek != null) {
      final days = [
        l10n.sunday.substring(0, 3),
        l10n.monday.substring(0, 3),
        l10n.tuesday.substring(0, 3),
        l10n.wednesday.substring(0, 3),
        l10n.thursday.substring(0, 3),
        l10n.friday.substring(0, 3),
        l10n.saturday.substring(0, 3),
      ];
      freq += ' ${l10n.on} ${days[config.dayOfWeek! % 7]}';
    } else if (config.frequency == 'monthly' && config.dayOfMonth != null) {
      freq += ' ${l10n.on} ${l10n.day} ${config.dayOfMonth}';
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
    _amountController =
        TextEditingController(text: widget.config?.amount.toString() ?? '');
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return AlertDialog(
      title: Text(
          widget.config == null ? l10n.addRecurring : l10n.editRecurring),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.amount,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.type,
                border: const OutlineInputBorder(),
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
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.noCategory),
                    ),
                    ...filteredCategories.map((category) {
                      final displayName = l10n.translateCategoryName(category.id, category.name);
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(displayName),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                labelText: l10n.frequency,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'daily', child: Text(l10n.daily)),
                DropdownMenuItem(value: 'weekly', child: Text(l10n.weekly)),
                DropdownMenuItem(value: 'monthly', child: Text(l10n.monthly)),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            final l10n = ref.read(localizationProvider);
            final name = _nameController.text.trim();
            final amount = double.tryParse(_amountController.text.trim());

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
    );
  }
}
