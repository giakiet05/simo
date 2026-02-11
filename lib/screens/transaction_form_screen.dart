import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/category.dart';
import 'home_screen.dart';

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
      result = amount.toString();
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

  void _showCalculatorKeyboard(BuildContext context, TextEditingController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CalculatorKeyboard(controller: controller),
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
              onTap: () => _showCalculatorKeyboard(context, item.amountController),
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
                    child: Text(displayName),
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
          ],
        ),
      ),
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

class _CalculatorKeyboard extends ConsumerStatefulWidget {
  final TextEditingController controller;

  const _CalculatorKeyboard({required this.controller});

  @override
  ConsumerState<_CalculatorKeyboard> createState() => _CalculatorKeyboardState();
}

class _CalculatorKeyboardState extends ConsumerState<_CalculatorKeyboard> {
  String _currentFormula = '';
  String _ansValue = '0';
  String _previewResult = '';
  String _errorMessage = '';
  String _lastValidFormula = ''; // Track formula trước khi bấm =

  @override
  void initState() {
    super.initState();
    // Remove comma từ controller text để tính toán
    _currentFormula = widget.controller.text.replaceAll(',', '');
    _lastValidFormula = _currentFormula;
    _updatePreview();
  }

  void _updatePreview() {
    if (_currentFormula.isEmpty) {
      _previewResult = '';
      return;
    }

    try {
      final result = _evaluateFormula(_currentFormula.replaceAll('ANS', _ansValue));
      _previewResult = '= ${_formatNumber(result)}';
    } catch (e) {
      _previewResult = '';
    }
  }

  String _formatNumber(double num) {
    if (num == num.toInt()) {
      return num.toInt().toString();
    }
    return num.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  String _formatAmountForDisplay(double amount) {
    String result;
    if (amount == amount.toInt()) {
      result = amount.toInt().toString();
    } else {
      result = amount.toString();
    }

    // Add comma separator
    final parts = result.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    return parts.join('.');
  }

  String _formatForDisplay(String formula) {
    if (formula.isEmpty) return formula;

    // Replace các số trong formula với phiên bản có dấu phẩy
    String result = formula;

    // Tìm tất cả các số (bao gồm cả số thập phân)
    final regex = RegExp(r'\d+\.?\d*');
    result = result.replaceAllMapped(regex, (match) {
      final numStr = match.group(0)!;

      // Nếu có dấu chấm thập phân
      if (numStr.contains('.')) {
        final parts = numStr.split('.');
        final intPart = int.tryParse(parts[0]);
        if (intPart == null) return numStr;

        // Format phần nguyên với dấu phẩy
        final formattedInt = intPart.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
        return '$formattedInt.${parts[1]}';
      }

      // Số nguyên
      final num = int.tryParse(numStr);
      if (num == null) return numStr;

      // Format với dấu phẩy
      return num.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 75,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      _currentFormula.isEmpty ? '0' : _formatForDisplay(_currentFormula),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: 20,
                      child: _previewResult.isNotEmpty
                          ? Text(
                              _previewResult,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildRow1(),
              const SizedBox(height: 6),
              _buildRow2(),
              const SizedBox(height: 6),
              _buildRow3(),
              const SizedBox(height: 6),
              _buildRow4(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = '';
                    });

                    // Quyết định lưu formula hay kết quả
                    String formulaToSave = _currentFormula;

                    // Nếu _currentFormula chỉ là số (không có toán tử)
                    // và _lastValidFormula có toán tử → dùng _lastValidFormula
                    if (!_currentFormula.contains(RegExp(r'[+\-*/]')) &&
                        _lastValidFormula.contains(RegExp(r'[+\-*/]'))) {
                      formulaToSave = _lastValidFormula;
                    }

                    if (formulaToSave.isEmpty) {
                      setState(() {
                        _errorMessage = l10n.pleaseEnterAmount;
                      });
                      return;
                    }

                    // Validate formula bằng cách evaluate
                    String formulaToEvaluate = formulaToSave.replaceAll('ANS', _ansValue);
                    formulaToEvaluate = formulaToEvaluate.replaceAll(RegExp(r'[+\-*/]+$'), '');

                    try {
                      final result = _evaluateFormula(formulaToEvaluate);

                      if (result < 0) {
                        setState(() {
                          _errorMessage = l10n.amountCannotNegative;
                        });
                        return;
                      }

                      // Format formula với dấu phẩy trước khi lưu
                      String formattedForSave = formulaToSave.replaceAllMapped(RegExp(r'\d+\.?\d*'), (match) {
                        final numStr = match.group(0)!;
                        final num = double.tryParse(numStr);
                        if (num == null) return numStr;
                        return _formatAmountForDisplay(num);
                      });

                      // Lưu formula đã format
                      widget.controller.text = formattedForSave;
                    } catch (e) {
                      setState(() {
                        _errorMessage = l10n.invalidFormula;
                      });
                      return;
                    }

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    l10n.done,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow1() {
    return Row(
      children: [
        _buildButton('7'),
        _buildButton('8'),
        _buildButton('9'),
        _buildButton('AC'),
        _buildButton('DEL'),
      ],
    );
  }

  Widget _buildRow2() {
    return Row(
      children: [
        _buildButton('4'),
        _buildButton('5'),
        _buildButton('6'),
        _buildButton('×'),
        _buildButton('÷'),
      ],
    );
  }

  Widget _buildRow3() {
    return Row(
      children: [
        _buildButton('1'),
        _buildButton('2'),
        _buildButton('3'),
        _buildButton('+'),
        _buildButton('-'),
      ],
    );
  }

  Widget _buildRow4() {
    return Row(
      children: [
        _buildButton('0'),
        _buildButton('000'),
        _buildButton('.'),
        _buildButton('ANS'),
        _buildButton('='),
      ],
    );
  }

  Widget _buildButton(String btn) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: ElevatedButton(
          onPressed: () => _handleCalcButton(btn),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _getButtonColor(btn),
            foregroundColor: _getButtonTextColor(btn),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: btn == 'DEL'
              ? const Icon(Icons.backspace_outlined, size: 20)
              : Text(
                  btn,
                  style: TextStyle(
                    fontSize: btn.length >= 2 ? 13 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Color _getButtonColor(String btn) {
    if (btn == 'AC') return Colors.red[400]!;
    if (btn == 'DEL') return Colors.orange[400]!;
    if (['+', '-', '×', '÷'].contains(btn)) return Colors.blue[400]!;
    if (btn == 'ANS') return Colors.purple[300]!;
    if (btn == '=') return Colors.teal;
    return Colors.grey[300]!;
  }

  Color _getButtonTextColor(String btn) {
    if (['AC', 'DEL', '+', '-', '×', '÷', 'ANS', '='].contains(btn)) return Colors.white;
    return Colors.black87;
  }

  void _handleCalcButton(String btn) {
    setState(() {
      _errorMessage = '';

      if (btn == 'AC') {
        _currentFormula = '';
        _previewResult = '';
      } else if (btn == 'DEL') {
        if (_currentFormula.isNotEmpty) {
          if (_currentFormula.endsWith('ANS')) {
            _currentFormula = _currentFormula.substring(0, _currentFormula.length - 3);
          } else {
            _currentFormula = _currentFormula.substring(0, _currentFormula.length - 1);
          }
        }
      } else if (btn == '=') {
        if (_currentFormula.isNotEmpty) {
          try {
            String formulaToEvaluate = _currentFormula.replaceAll('ANS', _ansValue);
            formulaToEvaluate = formulaToEvaluate.replaceAll(RegExp(r'[+\-*/]+$'), '');

            final result = _evaluateFormula(formulaToEvaluate);
            _ansValue = _formatNumber(result);
            // Lưu formula trước khi ghi đè
            _lastValidFormula = _currentFormula;
            _currentFormula = _ansValue;
            _previewResult = '';
          } catch (e) {
            _previewResult = 'Error';
          }
        }
      } else if (btn == 'ANS') {
        _currentFormula += 'ANS';
      } else if (btn == '×') {
        if (_currentFormula.isNotEmpty && !_currentFormula.endsWith('*') && !_currentFormula.endsWith('/') && !_currentFormula.endsWith('+') && !_currentFormula.endsWith('-')) {
          _currentFormula += '*';
        }
      } else if (btn == '÷') {
        if (_currentFormula.isNotEmpty && !_currentFormula.endsWith('*') && !_currentFormula.endsWith('/') && !_currentFormula.endsWith('+') && !_currentFormula.endsWith('-')) {
          _currentFormula += '/';
        }
      } else if (btn == '+') {
        if (_currentFormula.isNotEmpty && !_currentFormula.endsWith('*') && !_currentFormula.endsWith('/') && !_currentFormula.endsWith('+') && !_currentFormula.endsWith('-')) {
          _currentFormula += '+';
        }
      } else if (btn == '-') {
        if (_currentFormula.isEmpty || _currentFormula.endsWith('*') || _currentFormula.endsWith('/') || _currentFormula.endsWith('+')) {
          _currentFormula += '-';
        } else if (!_currentFormula.endsWith('-')) {
          _currentFormula += '-';
        }
      } else if (btn == '000') {
        _currentFormula += '000';
      } else {
        _currentFormula += btn;
      }

      // Update _lastValidFormula nếu có toán tử
      if (_currentFormula.contains(RegExp(r'[+\-*/]'))) {
        _lastValidFormula = _currentFormula;
      }

      _updatePreview();
    });
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
}

class TransactionItem {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  String? categoryId;
  String type = 'expense';

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}
