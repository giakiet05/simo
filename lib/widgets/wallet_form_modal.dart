import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/localization.dart';

class WalletFormModal extends ConsumerStatefulWidget {
  final Wallet? walletToEdit;

  const WalletFormModal({super.key, this.walletToEdit});

  static Future<void> show(BuildContext context, {Wallet? walletToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WalletFormModal(walletToEdit: walletToEdit),
    );
  }

  @override
  ConsumerState<WalletFormModal> createState() => _WalletFormModalState();
}

class _WalletFormModalState extends ConsumerState<WalletFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _uuid = const Uuid();

  String _selectedType = 'cash';
  String _selectedColor = '#10B981';
  String _selectedIcon = 'wallet';
  bool _isDefault = false;
  bool _excludeFromTotal = false;

  final List<Map<String, String>> _types = [
    {'key': 'cash', 'icon': 'wallet'},
    {'key': 'bank', 'icon': 'account_balance'},
    {'key': 'ewallet', 'icon': 'phone_android'},
    {'key': 'credit', 'icon': 'credit_card'},
    {'key': 'savings', 'icon': 'savings'},
  ];

  final List<String> _colors = [
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#EF4444', // Red
    '#F59E0B', // Amber
    '#14B8A6', // Teal
    '#64748B', // Slate
  ];

  final List<Map<String, dynamic>> _icons = [
    {'name': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'name': 'account_balance', 'icon': Icons.account_balance_rounded},
    {'name': 'phone_android', 'icon': Icons.phone_android_rounded},
    {'name': 'credit_card', 'icon': Icons.credit_card_rounded},
    {'name': 'savings', 'icon': Icons.savings_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.walletToEdit != null) {
      final w = widget.walletToEdit!;
      _nameController.text = w.name;
      if (w.initialBalance > 0) {
        _initialBalanceController.text =
            NumberFormat('#,###').format(w.initialBalance.toInt());
      }
      _selectedType = w.type;
      _selectedColor = w.color;
      _selectedIcon = w.icon;
      _isDefault = w.isDefault;
      _excludeFromTotal = w.excludeFromTotal;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'bank':
        return l10n.walletBank;
      case 'ewallet':
        return l10n.walletEwallet;
      case 'credit':
        return l10n.walletCredit;
      case 'savings':
        return l10n.walletSavings;
      case 'other':
        return l10n.walletOther;
      case 'cash':
      default:
        return l10n.walletCash;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balanceRaw =
        _initialBalanceController.text.replaceAll(',', '').trim();
    final initialBalance = double.tryParse(balanceRaw) ?? 0.0;

    final now = DateTime.now();
    if (widget.walletToEdit != null) {
      final updated = widget.walletToEdit!.copyWith(
        name: name,
        type: _selectedType,
        initialBalance: initialBalance,
        color: _selectedColor,
        icon: _selectedIcon,
        isDefault: _isDefault,
        excludeFromTotal: _excludeFromTotal,
        updatedAt: now,
      );
      await ref.read(walletProvider.notifier).updateWallet(updated);
    } else {
      final newWallet = Wallet(
        id: _uuid.v4(),
        name: name,
        type: _selectedType,
        initialBalance: initialBalance,
        currentBalance: initialBalance,
        color: _selectedColor,
        icon: _selectedIcon,
        isDefault: _isDefault,
        excludeFromTotal: _excludeFromTotal,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(walletProvider.notifier).createWallet(newWallet);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(Localizations.localeOf(context).languageCode);
    final isEdit = widget.walletToEdit != null;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? l10n.editWallet : l10n.addWallet,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.walletName,
                  hintText: 'Ví dụ: Vietcombank, Ví Momo, Tiền mặt...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.walletName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Type Selector
              Text(
                l10n.walletType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _types.map((t) {
                    final isSelected = _selectedType == t['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_getTypeLabel(t['key']!, l10n)),
                        selected: isSelected,
                        selectedColor:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedType = t['key']!;
                              _selectedIcon = t['icon']!;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Initial Balance
              TextFormField(
                controller: _initialBalanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.initialBalance,
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Color Palette Picker
              const Text(
                'Màu đại diện',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((c) {
                  final color = _parseColor(c);
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 2.5,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 20, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Icon Picker
              const Text(
                'Biểu tượng',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: _icons.map((item) {
                  final isSelected = _selectedIcon == item['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIcon = item['name']),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Switches
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.isDefaultWallet),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.excludeFromTotal),
                value: _excludeFromTotal,
                onChanged: (val) => setState(() => _excludeFromTotal = val),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? l10n.saveAll : l10n.addWallet,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
