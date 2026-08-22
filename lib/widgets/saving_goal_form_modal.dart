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

class SavingGoalFormModal extends StatefulWidget {
  final SavingGoal? initialGoal;
  final String currency;
  final dynamic l10n;
  final Function(SavingGoal) onSave;

  const SavingGoalFormModal({
    super.key,
    this.initialGoal,
    required this.currency,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<SavingGoalFormModal> createState() => _SavingGoalFormModalState();
}

class _SavingGoalFormModalState extends State<SavingGoalFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  DateTime? _selectedDate;
  String _selectedColor = '#009688'; // Teal
  String _selectedIcon = 'savings';
  String _selectedStatus = 'active';

  static const List<String> _colorPalette = [
    '#009688', // Teal
    '#2196F3', // Blue
    '#9C27B0', // Purple
    '#E91E63', // Pink
    '#FF9800', // Orange
    '#4CAF50', // Green
    '#3F51B5', // Indigo
    '#795548', // Brown
  ];

  static const Map<String, IconData> _iconPresets = {
    'savings': Icons.savings_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'flight': Icons.flight_takeoff_rounded,
    'car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'school': Icons.school_rounded,
    'favorite': Icons.favorite_rounded,
    'star': Icons.star_rounded,
    'phone': Icons.smartphone_rounded,
    'vacation': Icons.beach_access_rounded,
    'fitness': Icons.fitness_center_rounded,
  };

  @override
  void initState() {
    super.initState();
    final g = widget.initialGoal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _amountController = TextEditingController(
      text: g != null ? NumberFormat('#,###').format(g.targetAmount.toInt()) : '',
    );
    _noteController = TextEditingController(text: g?.note ?? '');
    _selectedDate = g?.targetDate;
    _selectedColor = g?.color ?? _colorPalette.first;
    _selectedIcon = g?.icon ?? 'savings';
    _selectedStatus = g?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.teal;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.teal;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final cleanAmount = _amountController.text.replaceAll(',', '').trim();
    final targetAmount = double.tryParse(cleanAmount) ?? 0.0;
    if (targetAmount <= 0) return;

    final goal = SavingGoal(
      id: widget.initialGoal?.id,
      name: _nameController.text.trim(),
      targetAmount: targetAmount,
      currentAmount: widget.initialGoal?.currentAmount ?? 0.0,
      targetDate: _selectedDate,
      color: _selectedColor,
      icon: _selectedIcon,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      status: _selectedStatus,
      createdAt: widget.initialGoal?.createdAt,
    );

    widget.onSave(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialGoal != null;
    final currencySymbol = CurrencyService.getSymbol(widget.currency);

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
                    isEditing ? widget.l10n.editSavingGoal : widget.l10n.addSavingGoal,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Goal Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.l10n.goalName,
                  hintText: widget.l10n.locale == 'vi' ? 'Ví dụ: Mua Macbook, Quỹ du lịch' : 'e.g. New Laptop, Vacation',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return widget.l10n.fillAllFields;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: widget.l10n.targetAmount,
                  suffixText: currencySymbol,
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return widget.l10n.fillAllFields;
                  }
                  final cleanVal = val.replaceAll(',', '').trim();
                  final parsed = double.tryParse(cleanVal);
                  if (parsed == null || parsed <= 0) {
                    return widget.l10n.locale == 'vi' ? 'Vui lòng nhập số tiền lớn hơn 0' : 'Please enter an amount > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Date (Deadline)
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
                title: Text(widget.l10n.optionalDeadline, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : (widget.l10n.locale == 'vi' ? 'Không đặt hạn chót' : 'No deadline'),
                  style: TextStyle(
                    fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                    color: _selectedDate != null ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _selectedDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_calendar_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 90)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Icon Picker
              Text(
                widget.l10n.locale == 'vi' ? 'Biểu tượng' : 'Icon',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _iconPresets.entries.map((entry) {
                    final isSelected = _selectedIcon == entry.key;
                    final currentColor = _parseColor(_selectedColor);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = entry.key),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? currentColor : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        child: Icon(
                          entry.value,
                          size: 22,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Color Picker
              Text(
                widget.l10n.locale == 'vi' ? 'Màu chủ đạo' : 'Color theme',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _colorPalette.map((hex) {
                    final color = _parseColor(hex);
                    final isSelected = _selectedColor == hex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black54, width: 3) : null,
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: widget.l10n.note,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEditing ? widget.l10n.apply : widget.l10n.saveAll,
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
