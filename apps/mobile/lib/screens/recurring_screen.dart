import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/recurring_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/recurring_config.dart';
import '../models/wallet.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/category_icon_widget.dart';
import '../utils/app_constants.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final walletsAsync = ref.watch(walletProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTransactions),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.add,
            onPressed: () => _showAddDialog(context, ref),
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
              final walletMap = {
                for (var w in walletsAsync.value ?? <Wallet>[]) w.id: w
              };

              return Column(
                children: [
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
                        final wallet = config.walletId != null ? walletMap[config.walletId] : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CategoryIconWidget(
                              category: category,
                              iconName: category == null ? (config.type == 'income' ? 'attach_money' : 'shopping_cart') : null,
                            ),
                            title: Text(
                              config.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: settingsAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                              data: (settings) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          categoryName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      if (wallet != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.account_balance_wallet_outlined, size: 12, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 4),
                                              ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 120),
                                                child: Text(
                                                  wallet.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${config.type == 'income' ? '+' : '-'} ${_formatAmount(config.amount, settings.currency)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: config.type == 'income' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  Text(_formatFrequency(ref, config), style: const TextStyle(fontSize: 13)),
                                  Text(
                                    '${l10n.nextRun}: ${DateFormat('dd/MM/yyyy').format(config.nextRun)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Switch(
                              value: config.isActive,
                              onChanged: (value) {
                                ref
                                    .read(recurringProvider.notifier)
                                    .toggleActive(config.id, value);
                              },
                            ),
                            onTap: () => _showActionMenu(context, ref, config),
                          ),
                        );
                      },
                    ),
                  ),
                  const BannerAdWidget(key: ValueKey('recurring_banner_ad')),
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

  String _formatAmount(double amount, String currency) {
    final symbol = CurrencyService.getSymbol(currency);
    return '${NumberFormat('#,###').format(amount)} $symbol';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecurringFormModal(config: config),
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

class _RecurringFormModal extends ConsumerStatefulWidget {
  final RecurringConfig? config;

  const _RecurringFormModal({this.config});

  @override
  ConsumerState<_RecurringFormModal> createState() =>
      _RecurringFormModalState();
}

class _RecurringFormModalState extends ConsumerState<_RecurringFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _intervalController;

  String? _selectedCategoryId;
  String? _selectedWalletId;
  String _selectedType = 'expense';
  String _selectedFrequency = 'monthly';
  int _interval = 1;
  int? _dayOfWeek;
  int? _dayOfMonth;
  late DateTime _nextRun;
  bool _isActive = true;
  bool _walletInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.config?.name ?? '');

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
      _selectedWalletId = widget.config!.walletId;
      _selectedType = widget.config!.type;
      _selectedFrequency = widget.config!.frequency;
      _interval = widget.config!.interval;
      _dayOfWeek = widget.config!.dayOfWeek;
      _dayOfMonth = widget.config!.dayOfMonth;
      _nextRun = widget.config!.nextRun;
      _isActive = widget.config!.isActive;
      _walletInitialized = true;
    } else {
      _nextRun = DateTime.now();
      _dayOfWeek = DateTime.now().weekday % 7;
      _dayOfMonth = DateTime.now().day;
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
      if (numValue > AppConstants.maxAmount) {
        final l10n = ref.read(localizationProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppConstants.maxAmountError(l10n))),
        );
        return;
      }
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

  Widget _buildWeekdaySelector(dynamic l10n) {
    final weekdays = [
      {'val': 1, 'label': l10n.locale == 'vi' ? 'T2' : 'Mon'},
      {'val': 2, 'label': l10n.locale == 'vi' ? 'T3' : 'Tue'},
      {'val': 3, 'label': l10n.locale == 'vi' ? 'T4' : 'Wed'},
      {'val': 4, 'label': l10n.locale == 'vi' ? 'T5' : 'Thu'},
      {'val': 5, 'label': l10n.locale == 'vi' ? 'T6' : 'Fri'},
      {'val': 6, 'label': l10n.locale == 'vi' ? 'T7' : 'Sat'},
      {'val': 0, 'label': l10n.locale == 'vi' ? 'CN' : 'Sun'},
    ];

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekdays.map((item) {
        final val = item['val'] as int;
        final label = item['label'] as String;
        final isSelected = _dayOfWeek == val;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _dayOfWeek = val;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveConfig() async {
    final l10n = ref.read(localizationProvider);
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (name.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    if (amount > AppConstants.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppConstants.maxAmountError(l10n))),
      );
      return;
    }

    try {
      if (widget.config == null) {
        await ref.read(recurringProvider.notifier).createRecurringConfig(
              categoryId: _selectedCategoryId,
              walletId: _selectedWalletId,
              name: name,
              amount: amount,
              type: _selectedType,
              frequency: _selectedFrequency,
              interval: _interval,
              dayOfWeek: _selectedFrequency == 'weekly' ? _dayOfWeek : null,
              dayOfMonth: _selectedFrequency == 'monthly' ? _dayOfMonth : null,
              nextRun: _nextRun,
            );
      } else {
        await ref.read(recurringProvider.notifier).updateRecurringConfig(
              widget.config!.id,
              categoryId: _selectedCategoryId,
              clearCategory: _selectedCategoryId == null,
              walletId: _selectedWalletId,
              clearWallet: _selectedWalletId == null,
              name: name,
              amount: amount,
              type: _selectedType,
              frequency: _selectedFrequency,
              interval: _interval,
              dayOfWeek: _selectedFrequency == 'weekly' ? _dayOfWeek : null,
              dayOfMonth: _selectedFrequency == 'monthly' ? _dayOfMonth : null,
              nextRun: _nextRun,
              isActive: _isActive,
            );
      }

      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final walletsAsync = ref.watch(walletProvider);
    final defaultWallet = ref.watch(defaultWalletProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationProvider);

    final currency = settingsAsync.value?.currency ?? 'VND';
    final currencySymbol = CurrencyService.getSymbol(currency);
    final wallets = walletsAsync.value ?? <Wallet>[];

    if (!_walletInitialized && wallets.isNotEmpty) {
      _selectedWalletId = defaultWallet?.id ?? wallets.first.id;
      _walletInitialized = true;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.config == null ? l10n.addRecurring : l10n.editRecurring,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Type selector (Expense / Income)
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'expense',
                              label: Text(l10n.expense),
                              icon: const Icon(Icons.arrow_upward, color: Colors.red),
                            ),
                            ButtonSegment(
                              value: 'income',
                              label: Text(l10n.income),
                              icon: const Icon(Icons.arrow_downward, color: Colors.green),
                            ),
                          ],
                          selected: {_selectedType},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _selectedType = selection.first;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.name,
                          hintText: l10n.locale == 'vi'
                              ? 'VD: Tiền phòng, Netflix, Lương...'
                              : 'e.g. Rent, Netflix, Salary...',
                          prefixIcon: const Icon(Icons.bookmark_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _onAmountChanged,
                        decoration: InputDecoration(
                          labelText: l10n.amount,
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: currencySymbol,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Wallet selector
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedWalletId,
                        decoration: InputDecoration(
                          labelText: l10n.wallet,
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: [
                          ...wallets.map((w) {
                            Color walletColor;
                            try {
                              walletColor = Color(int.parse(w.color.replaceFirst('#', '0xFF')));
                            } catch (_) {
                              walletColor = Colors.teal;
                            }
                            return DropdownMenuItem<String?>(
                              value: w.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: walletColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(w.name),
                                  if (w.isDefault) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${l10n.locale == 'vi' ? 'Mặc định' : 'Default'})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedWalletId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // 5. Category selector
                      categoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('${l10n.error}: $e'),
                        data: (categories) {
                          final filteredCats =
                              categories.where((c) => c.type == _selectedType).toList();
                          if (_selectedCategoryId != null &&
                              !filteredCats.any((c) => c.id == _selectedCategoryId)) {
                            _selectedCategoryId = null;
                          }

                          return DropdownButtonFormField<String?>(
                            key: ValueKey('${_selectedType}_$_selectedCategoryId'),
                            initialValue: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: l10n.categoryOptional,
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Row(
                                  children: [
                                    const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Text(l10n.noCategory),
                                  ],
                                ),
                              ),
                              ...filteredCats.map((cat) {
                                return DropdownMenuItem<String?>(
                                  value: cat.id,
                                  child: Row(
                                    children: [
                                      CategoryIconWidget(
                                        category: cat,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(l10n.translateCategoryName(cat.id, cat.name)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 6. Frequency selector
                      Text(
                        l10n.frequency,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'daily',
                              label: Text(l10n.byDay),
                              icon: const Icon(Icons.view_day_outlined),
                            ),
                            ButtonSegment(
                              value: 'weekly',
                              label: Text(l10n.byWeek),
                              icon: const Icon(Icons.view_week_outlined),
                            ),
                            ButtonSegment(
                              value: 'monthly',
                              label: Text(l10n.byMonth),
                              icon: const Icon(Icons.calendar_month_outlined),
                            ),
                          ],
                          selected: {_selectedFrequency},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _selectedFrequency = selection.first;
                              if (_selectedFrequency == 'weekly' && _dayOfWeek == null) {
                                _dayOfWeek = DateTime.now().weekday % 7;
                              }
                              if (_selectedFrequency == 'monthly' && _dayOfMonth == null) {
                                _dayOfMonth = DateTime.now().day;
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 7. Interval row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.interval,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: TextFormField(
                              controller: _intervalController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                prefixText: '${l10n.every} ',
                                suffixText: _selectedFrequency == 'daily'
                                    ? (_interval == 1 ? l10n.day : l10n.days)
                                    : _selectedFrequency == 'weekly'
                                        ? (_interval == 1 ? l10n.week : l10n.weeks)
                                        : (_interval == 1 ? l10n.month : l10n.months),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null && parsed > 0) {
                                  setState(() {
                                    _interval = parsed;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 8. Details for weekly or monthly
                      if (_selectedFrequency == 'weekly') ...[
                        Text(
                          l10n.dayOfWeek,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        _buildWeekdaySelector(l10n),
                        const SizedBox(height: 14),
                      ] else if (_selectedFrequency == 'monthly') ...[
                        DropdownButtonFormField<int>(
                          initialValue: _dayOfMonth ?? DateTime.now().day,
                          decoration: InputDecoration(
                            labelText: l10n.dayOfMonth,
                            prefixIcon: const Icon(Icons.calendar_month_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: List.generate(31, (index) {
                            final day = index + 1;
                            return DropdownMenuItem<int>(
                              value: day,
                              child: Text('${l10n.day} $day'),
                            );
                          }),
                          onChanged: (val) {
                            setState(() {
                              _dayOfMonth = val;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 9. Start Date / Next Run Date
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _nextRun,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _nextRun = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.nextRun,
                            prefixIcon: const Icon(Icons.event_outlined),
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_nextRun),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),

                      // 10. Active switch (if edit mode)
                      if (widget.config != null) ...[
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.locale == 'vi' ? 'Kích hoạt' : 'Active'),
                          subtitle: Text(
                            l10n.locale == 'vi'
                                ? 'Tự động tạo giao dịch khi tới hạn'
                                : 'Automatically create transactions when due',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _isActive,
                          onChanged: (val) {
                            setState(() {
                              _isActive = val;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveConfig,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
