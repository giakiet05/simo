import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/localization.dart';

class WalletTransferModal extends ConsumerStatefulWidget {
  final String? initialSourceWalletId;
  final String? initialDestinationWalletId;

  const WalletTransferModal({
    super.key,
    this.initialSourceWalletId,
    this.initialDestinationWalletId,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialSourceWalletId,
    String? initialDestinationWalletId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WalletTransferModal(
        initialSourceWalletId: initialSourceWalletId,
        initialDestinationWalletId: initialDestinationWalletId,
      ),
    );
  }

  @override
  ConsumerState<WalletTransferModal> createState() =>
      _WalletTransferModalState();
}

class _WalletTransferModalState extends ConsumerState<WalletTransferModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController();
  final _noteController = TextEditingController();

  String? _sourceWalletId;
  String? _destinationWalletId;
  DateTime _transferDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sourceWalletId = widget.initialSourceWalletId;
    _destinationWalletId = widget.initialDestinationWalletId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount, String currency) {
    final symbol = currency == 'VND' ? '₫' : currency;
    final isNegative = amount < 0;
    final absFormatted = NumberFormat('#,###', 'en_US').format(amount.abs());
    return '${isNegative ? '-' : ''}$absFormatted $symbol';
  }

  void _swapWallets() {
    setState(() {
      final temp = _sourceWalletId;
      _sourceWalletId = _destinationWalletId;
      _destinationWalletId = temp;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_transferDate),
      );
      if (mounted) {
        setState(() {
          _transferDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time?.hour ?? _transferDate.hour,
            time?.minute ?? _transferDate.minute,
          );
        });
      }
    }
  }

  Future<void> _submit(List<Wallet> wallets, AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    if (_sourceWalletId == null || _destinationWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectWallet)),
      );
      return;
    }

    if (_sourceWalletId == _destinationWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferErrorSameWallet)),
      );
      return;
    }

    final amountRaw = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(amountRaw) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    final feeRaw = _feeController.text.replaceAll(',', '').trim();
    final fee = double.tryParse(feeRaw) ?? 0.0;

    // Check if source wallet will overdraft
    final sourceWallet = wallets.firstWhere(
      (w) => w.id == _sourceWalletId,
      orElse: () => wallets.first,
    );
    final totalDeduction = amount + fee;
    if (sourceWallet.currentBalance < totalDeduction) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.overdraftWarningTitle)),
            ],
          ),
          content: Text(l10n.overdraftWarningMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.proceedTransfer),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await ref.read(walletProvider.notifier).transferFunds(
          sourceWalletId: _sourceWalletId!,
          destinationWalletId: _destinationWalletId!,
          amount: amount,
          fee: fee,
          transferDate: _transferDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transferSuccess),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final walletsAsync = ref.watch(walletProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.value?.currency ?? 'VND';
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: walletsAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (wallets) {
          if (wallets.length < 2) {
            return SizedBox(
              height: 200,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.noWalletsDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            );
          }

          // Set default wallets if null
          _sourceWalletId ??= wallets.first.id;
          _destinationWalletId ??=
              wallets.length > 1 ? wallets[1].id : wallets.first.id;

          return SingleChildScrollView(
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
                        l10n.transferFunds,
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

                  // Source & Destination Row with Swap Button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Source Wallet Picker
                        DropdownButtonFormField<String>(
                          value: _sourceWalletId,
                          decoration: InputDecoration(
                            labelText: l10n.sourceWallet,
                            border: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.red,
                            ),
                          ),
                          items: wallets.map((w) {
                            return DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                '${w.name} (${_formatAmount(w.currentBalance, currency)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _sourceWalletId = val),
                        ),

                        // Divider with Swap button
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            IconButton(
                              icon: const Icon(Icons.swap_vert_rounded),
                              tooltip: l10n.swapWallets,
                              onPressed: _swapWallets,
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        // Destination Wallet Picker
                        DropdownButtonFormField<String>(
                          value: _destinationWalletId,
                          decoration: InputDecoration(
                            labelText: l10n.destinationWallet,
                            border: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.green,
                            ),
                          ),
                          items: wallets.map((w) {
                            return DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                '${w.name} (${_formatAmount(w.currentBalance, currency)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _destinationWalletId = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Transfer Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.transferAmount,
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return l10n.transferAmount;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Optional Transfer Fee
                  TextFormField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.transferFee,
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.receipt_long_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Time Picker Tile
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: Text(l10n.transferDate),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(_transferDate),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 8),

                  // Note
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.note,
                      hintText: 'Ví dụ: Nạp tiền điện thoại, rút ATM...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submit(wallets, l10n),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.transfer,
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
          );
        },
      ),
    );
  }
}
