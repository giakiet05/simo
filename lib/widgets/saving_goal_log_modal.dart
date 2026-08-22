import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/saving_goal.dart';
import '../services/currency_service.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String clean = newValue.text.replaceAll(',', '');
    final number = int.tryParse(clean);
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SavingGoalLogModal extends StatefulWidget {
  final SavingGoal goal;
  final String initialType; // 'deposit' or 'withdraw'
  final String currency;
  final dynamic l10n;
  final Function(double amount, String type, DateTime date, String? note) onSubmit;

  const SavingGoalLogModal({
    super.key,
    required this.goal,
    this.initialType = 'deposit',
    required this.currency,
    required this.l10n,
    required this.onSubmit,
  });

  @override
  State<SavingGoalLogModal> createState() => _SavingGoalLogModalState();
}

class _SavingGoalLogModalState extends State<SavingGoalLogModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedType;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cleanAmount = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(cleanAmount) ?? 0.0;
    if (amount <= 0) return;

    if (_selectedType == 'withdraw' && amount > widget.goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.l10n.locale == 'vi'
                ? 'Số tiền rút không được vượt quá số dư hiện có'
                : 'Withdrawal cannot exceed saved balance',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSubmit(
      amount,
      _selectedType,
      _selectedDate,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyService.getSymbol(widget.currency);
    final isDeposit = _selectedType == 'deposit';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDeposit ? widget.l10n.depositToGoal : widget.l10n.withdrawFromGoal,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Type Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 16),
                          const SizedBox(width: 6),
                          Text(widget.l10n.deposit),
                        ],
                      ),
                      selected: isDeposit,
                      selectedColor: Colors.green.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isDeposit ? Colors.green[800] : null,
                        fontWeight: isDeposit ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = 'deposit');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.remove_circle_outline, size: 16),
                          const SizedBox(width: 6),
                          Text(widget.l10n.withdraw),
                        ],
                      ),
                      selected: !isDeposit,
                      selectedColor: Colors.orange.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: !isDeposit ? Colors.orange[900] : null,
                        fontWeight: !isDeposit ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = 'withdraw');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: widget.l10n.amount,
                  suffixText: currencySymbol,
                  prefixIcon: Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isDeposit ? Colors.green : Colors.orange,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return widget.l10n.fillAllFields;
                  }
                  final cleanVal = val.replaceAll(',', '').trim();
                  final parsed = double.tryParse(cleanVal);
                  if (parsed == null || parsed <= 0) {
                    return widget.l10n.locale == 'vi' ? 'Vui lòng nhập số tiền > 0' : 'Please enter an amount > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Picker Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                title: Text(widget.l10n.transactionDateLabel, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: widget.l10n.note,
                  hintText: isDeposit
                      ? (widget.l10n.locale == 'vi' ? 'Ví dụ: Lương tháng 8, Tiền thưởng' : 'e.g. Monthly savings, Bonus')
                      : (widget.l10n.locale == 'vi' ? 'Lý do rút' : 'Withdrawal reason'),
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeposit ? Colors.green : Colors.orange[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isDeposit ? widget.l10n.deposit : widget.l10n.withdraw,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
