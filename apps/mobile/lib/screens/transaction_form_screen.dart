import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_constants.dart';
import '../widgets/category_form_modal.dart';
import '../widgets/custom_num_pad.dart';
import '../widgets/transaction/category_grid_picker.dart';
import '../widgets/transaction/date_quick_bar.dart';
import '../widgets/transaction/wallet_chip_selector.dart';
import 'home_screen.dart';

/// Streamlined transaction creation and editing screen.
///
/// Provides a fast, ergonomic two-tier interface featuring:
/// - Segmented expense / income type toggle.
/// - Large live amount display with thousand separator formatting.
/// - Visual 4-column category grid picker.
/// - Compact wallet chip selector with live balance.
/// - Quick date selector with calendar picker and original date rollback.
/// - Integrated calculator keypad with operators and '000' multiplier.
/// - Rapid continuous logging via 'Save & Add Another'.
class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? editTransactionId;
  final String? editType;
  final String? editAmount;
  final String? editFormula;
  final String? editCategoryId;
  final String? editWalletId;
  final String? editNote;
  final DateTime? editTransactionDate;
  final DateTime? editCreatedAt;

  const TransactionFormScreen({
    super.key,
    this.editTransactionId,
    this.editType,
    this.editAmount,
    this.editFormula,
    this.editCategoryId,
    this.editWalletId,
    this.editNote,
    this.editTransactionDate,
    this.editCreatedAt,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  late final bool _isEditMode;
  late String _type;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _selectedCategoryId;
  String? _selectedWalletId;
  late DateTime _selectedDate;
  DateTime? _originalDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.editTransactionId != null;
    _type = widget.editType ?? 'expense';

    if (_isEditMode) {
      _originalDate = widget.editTransactionDate ?? widget.editCreatedAt;
      _selectedDate = _originalDate ?? DateTime.now();
      _selectedCategoryId = widget.editCategoryId;
      _selectedWalletId = widget.editWalletId;
      _noteController = TextEditingController(text: widget.editNote ?? '');

      String amountText = widget.editFormula ?? widget.editAmount ?? '';
      if (amountText.isNotEmpty && widget.editFormula == null) {
        final amount = double.tryParse(amountText);
        if (amount != null) {
          amountText = _formatAmountForDisplay(amount);
        }
      } else if (amountText.isNotEmpty && widget.editFormula != null) {
        amountText = _formatFormulaForDisplay(widget.editFormula!);
      }
      _amountController = TextEditingController(text: amountText);
    } else {
      _selectedDate = DateTime.now();
      _selectedCategoryId = widget.editCategoryId;
      _selectedWalletId = widget.editWalletId;
      _amountController = TextEditingController();
      _noteController = TextEditingController(text: widget.editNote ?? '');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Formats amount with comma thousand separators.
  String _formatAmountForDisplay(double amount) {
    String result;
    if (amount == amount.toInt()) {
      result = amount.toInt().toString();
    } else {
      if (amount.abs() < 0.01) {
        result = amount
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      } else {
        result = amount.toString();
      }
    }

    final parts = result.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );

    return parts.join('.');
  }

  /// Formats mathematical expressions with comma separators for individual numbers.
  String _formatFormulaForDisplay(String formula) {
    return formula.replaceAllMapped(RegExp(r'\d+\.?\d*'), (match) {
      final numStr = match.group(0)!;
      final num = double.tryParse(numStr);
      if (num == null) return numStr;
      return _formatAmountForDisplay(num);
    });
  }

  /// Evaluates a mathematical expression string adhering to standard arithmetic order.
  double _evaluateFormula(String formula) {
    String cleanFormula = formula.replaceAll(' ', '');
    if (cleanFormula.isEmpty) return 0;

    final operations = <String>[];
    final numbers = <double>[];
    String currentNumber = '';

    for (int i = 0; i < cleanFormula.length; i++) {
      final char = cleanFormula[i];

      if (char == '+' || char == '-' || char == '*' || char == '/') {
        if (char == '-' &&
            (i == 0 ||
                cleanFormula[i - 1] == '+' ||
                cleanFormula[i - 1] == '-' ||
                cleanFormula[i - 1] == '*' ||
                cleanFormula[i - 1] == '/')) {
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

  /// Saves the transaction, supporting both single save and continuous multi-entry.
  Future<void> _handleSave({bool addAnother = false}) async {
    if (_isSaving) return;

    final l10n = ref.read(localizationProvider);
    final amountRaw = _amountController.text.trim().replaceAll(',', '');

    if (amountRaw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterAmount)),
      );
      return;
    }

    double amount;
    String? formula;

    if (amountRaw.contains('+') ||
        amountRaw.contains('-') ||
        amountRaw.contains('*') ||
        amountRaw.contains('/')) {
      formula = amountRaw;
      try {
        final cleanForEval = formula.replaceAll(RegExp(r'[+\-*/]+$'), '');
        amount = _evaluateFormula(cleanForEval);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invalidFormula)),
        );
        return;
      }
    } else {
      amount = double.tryParse(amountRaw) ?? 0;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.amountCannotNegative)),
      );
      return;
    }

    if (amount > AppConstants.maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppConstants.maxAmountError(l10n))),
      );
      return;
    }

    final effectiveWalletId =
        _selectedWalletId ?? ref.read(defaultWalletProvider)?.id;
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditMode && widget.editTransactionId != null) {
        await ref.read(transactionProvider.notifier).updateTransaction(
              widget.editTransactionId!,
              categoryId: _selectedCategoryId,
              walletId: effectiveWalletId,
              amount: amount,
              formula: formula,
              note: note,
              type: _type,
              transactionDate: _selectedDate,
            );

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          homeScreenKey.currentState?.switchToTransactionsTab();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locale == 'vi'
                    ? 'Đã cập nhật giao dịch'
                    : 'Transaction updated',
              ),
            ),
          );
        }
      } else {
        await ref.read(transactionProvider.notifier).createTransactions([
          {
            'categoryId': _selectedCategoryId,
            'walletId': effectiveWalletId,
            'amount': amount,
            'formula': formula,
            'note': note,
            'type': _type,
            'transactionDate': _selectedDate,
          }
        ]);

        if (mounted) {
          if (addAnother) {
            setState(() {
              _amountController.clear();
              _noteController.clear();
              _selectedCategoryId = null;
              _isSaving = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.locale == 'vi'
                      ? 'Đã lưu giao dịch. Nhập tiếp giao dịch mới...'
                      : 'Transaction saved. Enter next one...',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
            homeScreenKey.currentState?.switchToTransactionsTab();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('1 ${l10n.transactionCreated}'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = settingsAsync.value?.currency ?? 'VND';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? (l10n.locale == 'vi' ? 'Sửa giao dịch' : l10n.edit)
              : (l10n.locale == 'vi' ? 'Thêm giao dịch' : l10n.addTransaction),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('${l10n.error}: $error')),
        data: (categories) {
          final filteredCategories =
              categories.where((cat) => cat.type == _type).toList();

          if (_selectedCategoryId != null &&
              !filteredCategories.any((cat) => cat.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }

          final wallets = walletsAsync.value ?? [];
          final defaultWallet = ref.watch(defaultWalletProvider);
          final effectiveWalletId =
              _selectedWalletId ?? defaultWallet?.id ?? (wallets.isNotEmpty ? wallets.first.id : null);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Type Segmented Toggle
                      _buildTypeSelector(l10n),
                      const SizedBox(height: 14),

                      // Large Live Amount Display
                      _buildAmountDisplay(currencySymbol),
                      const SizedBox(height: 12),

                      // Compact Note Input
                      _buildNoteInput(l10n),
                      const SizedBox(height: 14),

                      // Wallet Horizontal Row
                      if (wallets.isNotEmpty) ...[
                        WalletChipSelector(
                          wallets: wallets,
                          selectedWalletId: effectiveWalletId,
                          onWalletChanged: (wallet) {
                            setState(() {
                              _selectedWalletId = wallet.id;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Date Horizontal Row
                      DateQuickChipsBar(
                        selectedDate: _selectedDate,
                        originalDate: _isEditMode ? _originalDate : null,
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Visual Category Icon Grid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.grid_view_rounded,
                                  size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                l10n.category,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            l10n.locale == 'vi'
                                ? 'Nhấn giữ để sửa/xóa'
                                : 'Long press to edit/delete',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CategoryGridPicker(
                        categories: filteredCategories,
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                        },
                        onCategoryLongPressed: (category) {
                          CategoryFormModal.show(
                            context,
                            categoryToEdit: category,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Action Buttons
              _buildBottomActionBar(l10n),
            ],
          );
        },
      ),
    );
  }

  /// Builds the top Segmented Type Selector between Expense and Income.
  Widget _buildTypeSelector(dynamic l10n) {
    final isExpense = _type == 'expense';
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_type != 'expense') {
                  setState(() {
                    _type = 'expense';
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isExpense ? Colors.redAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isExpense
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    l10n.expenseMinus,
                    style: TextStyle(
                      color: isExpense ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: isExpense ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_type != 'income') {
                  setState(() {
                    _type = 'income';
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !isExpense ? Colors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isExpense
                      ? [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    l10n.incomePlus,
                    style: TextStyle(
                      color: !isExpense ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: !isExpense ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the custom numeric keypad calculator inside a modal bottom sheet.
  Future<void> _showCalculatorKeyboard(BuildContext context) async {
    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: CustomNumPad(
              amountController: _amountController,
              noteController: _noteController,
              isEmbedded: false,
              showDisplay: true,
              onChanged: (_) {
                setState(() {});
              },
              onDone: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  /// Builds the large live amount display with live preview and currency symbol.
  /// Tapping this box pops up the CustomNumPad calculator in a bottom modal.
  Widget _buildAmountDisplay(String currencySymbol) {
    final theme = Theme.of(context);
    final text = _amountController.text.trim();
    final displayText = text.isEmpty ? '0' : text;
    final isExpense = _type == 'expense';
    final activeColor = isExpense ? Colors.redAccent : Colors.teal;

    String? previewValue;
    if (text.contains('+') || text.contains('-') || text.contains('*') || text.contains('/')) {
      try {
        final cleanForEval = text.replaceAll(',', '').replaceAll(RegExp(r'[+\-*/]+$'), '');
        final res = _evaluateFormula(cleanForEval);
        previewValue = '= ${_formatAmountForDisplay(res)} $currencySymbol';
      } catch (_) {
        previewValue = null;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('amount_display_button'),
        onTap: () => _showCalculatorKeyboard(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activeColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencySymbol,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.calculate_outlined,
                          size: 16,
                          color: activeColor,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      displayText,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (previewValue != null) ...[
                const SizedBox(height: 4),
                Text(
                  previewValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the inline note text field with clear button.
  Widget _buildNoteInput(dynamic l10n) {
    return TextField(
      controller: _noteController,
      decoration: InputDecoration(
        hintText: '${l10n.note} (${l10n.optional})',
        prefixIcon: const Icon(Icons.edit_note, size: 20),
        suffixIcon: _noteController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() {
                    _noteController.clear();
                  });
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  /// Builds the bottom sticky action bar with 'Save' and 'Save & Add Another' buttons.
  Widget _buildBottomActionBar(dynamic l10n) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _isEditMode
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _handleSave(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 20),
                  label: Text(
                    l10n.locale == 'vi' ? 'Lưu thay đổi' : l10n.save,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : () => _handleSave(addAnother: true),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.playlist_add, size: 20),
                      label: Text(
                        l10n.locale == 'vi' ? 'Lưu & Thêm tiếp' : 'Save & Add',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _handleSave(addAnother: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 20),
                      label: Text(
                        l10n.locale == 'vi' ? 'Lưu' : l10n.save,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

