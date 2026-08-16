import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';
import '../services/currency_service.dart';
import 'home_screen.dart';
import '../widgets/custom_num_pad.dart';
import '../widgets/category_icon_widget.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? editTransactionId;
  final String? editType;
  final String? editAmount;
  final String? editFormula;
  final String? editCategoryId;
  final String? editNote;

  const TransactionFormScreen({
    super.key,
    this.editTransactionId,
    this.editType,
    this.editAmount,
    this.editFormula,
    this.editCategoryId,
    this.editNote,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final List<TransactionItem> _items;
  late final bool _isEditMode;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editTransactionId != null;

    if (_isEditMode) {
      final item = TransactionItem();
      item.type = widget.editType ?? 'expense';

      // Format amount để hiển thị với dấu phẩy
      String amountText = widget.editFormula ?? widget.editAmount ?? '';
      if (amountText.isNotEmpty && widget.editFormula == null) {
        // Nếu là số thuần (không phải formula), format với dấu phẩy
        final amount = double.tryParse(amountText);
        if (amount != null) {
          amountText = _formatAmountForDisplay(amount);
        }
      } else if (amountText.isNotEmpty && widget.editFormula != null) {
        // Nếu là formula, format các số trong formula
        amountText = _formatFormulaForDisplay(widget.editFormula!);
      }

      item.amountController.text = amountText;
      item.categoryId = widget.editCategoryId;
      item.noteController.text = widget.editNote ?? '';
      _items = [item];
    } else {
      _items = [TransactionItem()];
    }
  }

  // Format number without .0 and with comma
  String _formatAmountForDisplay(double amount) {
    String result;
    if (amount == amount.toInt()) {
      result = amount.toInt().toString();
    } else {
      // For very small numbers (exchange rates), preserve precision
      if (amount.abs() < 0.01) {
        result = amount.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      } else {
        result = amount.toString();
      }
    }

    // Add comma separator
    final parts = result.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    return parts.join('.');
  }

  // Format formula with comma in numbers
  String _formatFormulaForDisplay(String formula) {
    return formula.replaceAllMapped(RegExp(r'\d+\.?\d*'), (match) {
      final numStr = match.group(0)!;
      final num = double.tryParse(numStr);
      if (num == null) return numStr;
      return _formatAmountForDisplay(num);
    });
  }

  // Remove comma from formatted string
  String _removeCommaFromAmount(String text) {
    return text.replaceAll(',', '');
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.edit : l10n.addTransaction),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        data: (categories) {
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
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _isEditMode ? _items.length : _items.length + 1,
                  itemBuilder: (context, index) {
                    if (!_isEditMode && index == _items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _items.add(TransactionItem());
                            });

                            // Scroll xuống bottom sau khi thêm item mới
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  _scrollController.position.maxScrollExtent,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addMore),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      );
                    }
                    return _buildTransactionItem(index, categories);
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveAll(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isEditMode ? l10n.save : l10n.saveAll),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCalculatorKeyboard(BuildContext context, TextEditingController amountController, TextEditingController noteController) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CustomNumPad(
        amountController: amountController,
        noteController: noteController,
      ),
    );
  }


  Widget _buildTransactionItem(int index, List<Category> categories) {
    final item = _items[index];
    final l10n = ref.watch(localizationProvider);

    // Filter categories based on transaction type
    final filteredCategories = categories.where((cat) => cat.type == item.type).toList();

    // Check if current categoryId exists in filtered categories list
    if (item.categoryId != null &&
        !filteredCategories.any((cat) => cat.id == item.categoryId)) {
      // Category was deleted or type changed, set to null
      item.categoryId = null;
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.transaction} ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _items.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: item.type,
              decoration: InputDecoration(
                labelText: l10n.type,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'expense', child: Text(l10n.expenseMinus)),
                DropdownMenuItem(value: 'income', child: Text(l10n.incomePlus)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    item.type = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: item.amountController,
              readOnly: true,
              showCursor: true,
              onTap: () => _showCalculatorKeyboard(context, item.amountController, item.noteController),
              decoration: InputDecoration(
                labelText: l10n.amount,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calculate),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: item.categoryId,
              decoration: InputDecoration(
                labelText: l10n.category,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.noCategory),
                ),
                ...filteredCategories.map((cat) {
                  final displayName = l10n.translateCategoryName(cat.id, cat.name);

                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        CategoryIconWidget(
                          category: cat,
                          size: 32,
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
                  item.categoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: item.noteController,
              decoration: InputDecoration(
                labelText: '${l10n.note} (${l10n.optional})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: item.transactionDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    item.transactionDate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.locale == 'vi' ? 'Ngày giao dịch' : 'Transaction Date',
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.transactionDate.day}/${item.transactionDate.month}/${item.transactionDate.year}',
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickDateButton(item, 0, l10n.locale == 'vi' ? 'Hôm nay' : 'Today'),
                  const SizedBox(width: 8),
                  _buildQuickDateButton(item, 1, l10n.locale == 'vi' ? 'Hôm qua' : 'Yesterday'),
                  const SizedBox(width: 8),
                  _buildQuickDateButton(item, 2, l10n.locale == 'vi' ? '2 ngày trước' : '2 days ago'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(TransactionItem item, int daysAgo, String label) {
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
    
    // Check if item's date is same as targetDate
    final isSelected = item.transactionDate.year == targetDate.year &&
                       item.transactionDate.month == targetDate.month &&
                       item.transactionDate.day == targetDate.day;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
      side: BorderSide(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
      ),
      onPressed: () {
        setState(() {
          // Keep the current time, just change the date
          final current = DateTime.now();
          item.transactionDate = DateTime(
            targetDate.year, 
            targetDate.month, 
            targetDate.day, 
            current.hour, 
            current.minute, 
            current.second
          );
        });
      },
    );
  }

  Future<void> _saveAll(BuildContext context) async {
    try {
      final transactionData = <Map<String, dynamic>>[];

      for (var item in _items) {
        final amountText = item.amountController.text.trim();
        if (amountText.isEmpty) continue;

        // Remove comma trước khi xử lý
        final cleanAmountText = _removeCommaFromAmount(amountText);

        double amount;
        String? formula;

        if (cleanAmountText.contains('+') ||
            cleanAmountText.contains('-') ||
            cleanAmountText.contains('*') ||
            cleanAmountText.contains('/')) {
          formula = cleanAmountText;
          try {
            amount = _evaluateFormula(cleanAmountText);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid formula: $cleanAmountText')),
              );
            }
            return;
          }
        } else {
          amount = double.tryParse(cleanAmountText) ?? 0;
          if (amount == 0) continue;
        }

        transactionData.add({
          'categoryId': item.categoryId,
          'amount': amount,
          'formula': formula,
          'note': item.noteController.text.trim().isEmpty
              ? null
              : item.noteController.text.trim(),
          'type': item.type,
          'transactionDate': item.transactionDate,
        });
      }

      if (transactionData.isEmpty) {
        if (context.mounted) {
          final l10n = ref.read(localizationProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.fillAllFields)),
          );
        }
        return;
      }

      if (_isEditMode && widget.editTransactionId != null) {
        final data = transactionData.first;
        await ref.read(transactionProvider.notifier).updateTransaction(
              widget.editTransactionId!,
              categoryId: data['categoryId'],
              amount: data['amount'],
              formula: data['formula'],
              note: data['note'],
              type: data['type'],
              transactionDate: data['transactionDate'],
            );

        if (context.mounted) {
          final l10n = ref.read(localizationProvider);
          // Pop về root (HomeScreen)
          Navigator.of(context).popUntil((route) => route.isFirst);
          // Chuyển sang tab Transactions
          homeScreenKey.currentState?.switchToTransactionsTab();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated')),
          );
        }
      } else {
        await ref.read(transactionProvider.notifier).createTransactions(transactionData);

        if (context.mounted) {
          final l10n = ref.read(localizationProvider);
          // Pop về root (HomeScreen)
          Navigator.of(context).popUntil((route) => route.isFirst);
          // Chuyển sang tab Transactions
          homeScreenKey.currentState?.switchToTransactionsTab();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${transactionData.length} ${l10n.transactionCreated}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = ref.read(localizationProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  double _evaluateFormula(String formula) {
    formula = formula.replaceAll(' ', '');
    if (formula.isEmpty) return 0;

    final operations = <String>[];
    final numbers = <double>[];
    String currentNumber = '';

    for (int i = 0; i < formula.length; i++) {
      final char = formula[i];

      if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (char == '-' && (i == 0 || formula[i - 1] == '+' || formula[i - 1] == '-' || formula[i - 1] == '*' || formula[i - 1] == '/')) {
          currentNumber += char;
        } else {
          if (currentNumber.isNotEmpty) {
            numbers.add(double.parse(currentNumber));
            currentNumber = '';
          }
          operations.add(char);
        }
      } else {
        currentNumber += char;
      }
    }

    if (currentNumber.isNotEmpty) {
      numbers.add(double.parse(currentNumber));
    }

    if (numbers.isEmpty) return 0;

    while (operations.contains('*') || operations.contains('/')) {
      for (int i = 0; i < operations.length; i++) {
        if (operations[i] == '*') {
          numbers[i] = numbers[i] * numbers[i + 1];
          numbers.removeAt(i + 1);
          operations.removeAt(i);
          break;
        } else if (operations[i] == '/') {
          numbers[i] = numbers[i] / numbers[i + 1];
          numbers.removeAt(i + 1);
          operations.removeAt(i);
          break;
        }
      }
    }

    double result = numbers[0];
    for (int i = 0; i < operations.length; i++) {
      if (operations[i] == '+') {
        result += numbers[i + 1];
      } else if (operations[i] == '-') {
        result -= numbers[i + 1];
      }
    }

    return result;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }
}

class TransactionItem {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  String? categoryId;
  String type = 'expense';
  DateTime transactionDate = DateTime.now();

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}

