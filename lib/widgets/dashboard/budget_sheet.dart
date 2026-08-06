import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/localization_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/currency_service.dart';
import '../../utils/icon_data.dart';

class BudgetSheet extends ConsumerStatefulWidget {
  const BudgetSheet({super.key});

  @override
  ConsumerState<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<BudgetSheet> {
  final TextEditingController _totalBudgetController = TextEditingController();
  bool _isEditingTotal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsAsync = ref.read(settingsProvider);
      settingsAsync.whenData((settings) {
        if (settings.monthlyBudget > 0) {
          _totalBudgetController.text = settings.monthlyBudget.toInt().toString();
        }
      });
    });
  }

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  void _saveTotalBudget() {
    final val = double.tryParse(_totalBudgetController.text.replaceAll(',', ''));
    if (val != null) {
      ref.read(settingsProvider.notifier).updateBudget(val);
    }
    setState(() {
      _isEditingTotal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoryAsync = ref.watch(categoryProvider);

    final String currency = settingsAsync.value?.currency ?? 'VND';
    final double totalBudget = settingsAsync.value?.monthlyBudget ?? 0.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.locale == 'vi' ? 'Ngân sách tháng này' : 'Monthly Budget',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTotalBudgetSection(totalBudget, currency),
          const SizedBox(height: 24),
          Text(
            l10n.locale == 'vi' ? 'Ngân sách từng danh mục' : 'Category Budgets',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: categoryAsync.when(
              data: (categories) {
                final expenseCats = categories.where((c) => c.type == 'expense').toList();
                if (expenseCats.isEmpty) {
                  return Center(child: Text(l10n.locale == 'vi' ? 'Chưa có danh mục chi tiêu' : 'No expense categories'));
                }
                return ListView.builder(
                  itemCount: expenseCats.length,
                  itemBuilder: (context, index) {
                    final cat = expenseCats[index];
                    return _buildCategoryBudgetTile(cat, currency);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBudgetSection(double totalBudget, String currency) {
    if (_isEditingTotal) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _totalBudgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                prefixText: CurrencyService.getSymbol(currency) + ' ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveTotalBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.check),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => setState(() => _isEditingTotal = true),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              totalBudget > 0
                  ? '${CurrencyService.getSymbol(currency)} ${NumberFormat('#,###').format(totalBudget)}'
                  : (ref.read(localizationProvider).locale == 'vi' ? 'Chưa đặt ngân sách' : 'Not set'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ref.read(localizationProvider).locale == 'vi' ? 'Chạm để sửa' : 'Tap to edit',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetTile(Category category, String currency) {
    final hasBudget = category.budgetLimit != null && category.budgetLimit! > 0;
    
    final iconData = CategoryIconData.getIcon(category.icon) ?? Icons.category;
    
    Color backgroundColor = AppColors.warning;
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        String hex = category.color!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF' + hex;
        backgroundColor = Color(int.parse(hex, radix: 16));
      } catch (e) {
        // Fallback
      }
    }
    
    final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
        ? Colors.black
        : Colors.white;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: backgroundColor,
        child: Icon(iconData, color: iconColor, size: 20),
      ),
      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: hasBudget 
        ? Text('Ngân sách: ${NumberFormat('#,###').format(category.budgetLimit)} ${CurrencyService.getSymbol(currency)}')
        : Text(ref.read(localizationProvider).locale == 'vi' ? 'Chưa đặt' : 'Not set'),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () => _showCategoryBudgetDialog(category),
      ),
    );
  }

  void _showCategoryBudgetDialog(Category category) {
    final catController = TextEditingController(
      text: category.budgetLimit != null && category.budgetLimit! > 0 
          ? category.budgetLimit!.toInt().toString() 
          : ''
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.read(localizationProvider).locale == 'vi' ? 'Ngân sách ${category.name}' : '${category.name} Budget'),
        content: TextField(
          controller: catController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: InputDecoration(
            hintText: 'Nhập số tiền...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.read(localizationProvider).locale == 'vi' ? 'Hủy' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(catController.text.replaceAll(',', ''));
              ref.read(categoryProvider.notifier).updateCategory(
                category.id,
                category.name,
                category.type,
                icon: category.icon,
                color: category.color,
                budgetLimit: val,
              );
              Navigator.pop(context);
            },
            child: Text(ref.read(localizationProvider).locale == 'vi' ? 'Lưu' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(newText);
    final formatter = NumberFormat('#,###');
    String newString = formatter.format(value);

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
