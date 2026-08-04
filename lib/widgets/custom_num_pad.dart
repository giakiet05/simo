import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';

class CustomNumPad extends ConsumerStatefulWidget {
  final TextEditingController amountController;
  final TextEditingController noteController;
  final bool showOperators;

  const CustomNumPad({
    super.key,
    required this.amountController,
    required this.noteController,
    this.showOperators = true,
  });

  @override
  ConsumerState<CustomNumPad> createState() => CustomNumPadState();
}

class CustomNumPadState extends ConsumerState<CustomNumPad> {
  String _currentFormula = '';
  String _ansValue = '0';
  String _previewResult = '';
  String _errorMessage = '';
  String _lastValidFormula = ''; // Track formula trước khi bấm =
  double? _originalAmountBeforeConversion; // Track original amount for currency conversion

  @override
  void initState() {
    super.initState();
    // Remove comma từ controller text để tính toán
    _currentFormula = widget.amountController.text.replaceAll(',', '');
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

    // For very small numbers (exchange rates), use more decimal places
    if (num.abs() < 0.01) {
      // Use up to 8 decimal places for small numbers, remove trailing zeros
      return num.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '');
    }

    // For normal numbers, use 2 decimal places
    return num.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

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
              _buildConvertButton(),
              const SizedBox(height: 8),
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
                      widget.amountController.text = formattedForSave;
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

  Future<void> _handleCurrencyConversion() async {
    final l10n = ref.read(localizationProvider);

    if (_currentFormula.isEmpty) {
      setState(() {
        _errorMessage = l10n.pleaseEnterAmountFirst;
      });
      return;
    }

    double foreignAmount;
    try {
      // If already converted before, use the original amount
      // Otherwise calculate from current formula
      if (_originalAmountBeforeConversion != null) {
        foreignAmount = _originalAmountBeforeConversion!;
        print('Using original amount: $foreignAmount (for re-conversion)');
      } else {
        final formulaToEvaluate = _currentFormula.replaceAll('ANS', _ansValue);
        foreignAmount = _evaluateFormula(formulaToEvaluate);
        // Save original amount for potential re-conversion
        _originalAmountBeforeConversion = foreignAmount;
        print('Saving original amount: $foreignAmount');
      }
    } catch (e) {
      setState(() {
        _errorMessage = l10n.invalidAmount;
      });
      return;
    }

    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.value;
    if (settings == null) {
      setState(() {
        _errorMessage = l10n.cannotLoadSettings;
      });
      return;
    }

    final mainCurrency = settings.currency;

    final selectedCurrency = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectCurrency),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: CurrencyService.supportedCurrencies.length,
            itemBuilder: (context, index) {
              final currency = CurrencyService.supportedCurrencies[index];
              final code = currency['code']!;

              if (code == mainCurrency) {
                return const SizedBox.shrink();
              }

              return ListTile(
                title: Text('${currency['code']} - ${currency['name']}'),
                subtitle: Text(currency['symbol']!),
                onTap: () => Navigator.pop(context, code),
              );
            },
          ),
        ),
      ),
    );

    if (selectedCurrency == null) return;

    setState(() {
      _errorMessage = '';
    });

    try {
      final currencyService = CurrencyService();
      print('Converting $foreignAmount $selectedCurrency to $mainCurrency');

      // IMPORTANT: Convert FROM foreign currency TO main currency
      final rate = await currencyService.getRate(
        from: selectedCurrency,
        to: mainCurrency,
      );

      print('Conversion rate $selectedCurrency->$mainCurrency: $rate');

      setState(() {
        // Formula: foreignAmount * rate = mainCurrencyAmount
        // Example: 100 USD * 25920 = 2,592,000 VND
        _currentFormula = '${_formatNumber(foreignAmount)}*${_formatNumber(rate)}';
        _updatePreview();

        final currentNote = widget.noteController.text.trim();
        final conversionNote = '$selectedCurrency->$mainCurrency';

        if (currentNote.isEmpty) {
          widget.noteController.text = conversionNote;
        } else if (!currentNote.contains(conversionNote)) {
          widget.noteController.text = '$currentNote ($conversionNote)';
        }
      });
    } catch (e, stackTrace) {
      print('Currency conversion error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = '${l10n.failedToFetchRate}: $e';
      });
    }
  }

  Widget _buildConvertButton() {
    final l10n = ref.watch(localizationProvider);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleCurrencyConversion(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.currency_exchange, size: 18),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currencyConverter,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.currencyConverterHint,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow1() {
    return Row(
      children: [
        _buildButton('1'),
        _buildButton('2'),
        _buildButton('3'),
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
        _buildButton('7'),
        _buildButton('8'),
        _buildButton('9'),
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
        _originalAmountBeforeConversion = null; // Clear conversion tracking
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
        // Clear conversion tracking when user manually edits amount
        if (_originalAmountBeforeConversion != null) {
          _originalAmountBeforeConversion = null;
        }
      } else {
        _currentFormula += btn;
        // Clear conversion tracking when user manually types numbers
        if (RegExp(r'^[0-9.]$').hasMatch(btn) && _originalAmountBeforeConversion != null) {
          _originalAmountBeforeConversion = null;
        }
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

