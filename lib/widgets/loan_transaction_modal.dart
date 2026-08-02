import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/loan_contact.dart';
import '../models/loan_transaction.dart';
import '../providers/loan_provider.dart';
import '../providers/transaction_provider.dart';

class LoanTransactionModal extends ConsumerStatefulWidget {
  final LoanContact contact;
  final String initialTxType;
  final LoanTransaction? editTx;

  const LoanTransactionModal({
    super.key,
    required this.contact,
    required this.initialTxType,
    this.editTx,
  });

  @override
  ConsumerState<LoanTransactionModal> createState() => _LoanTransactionModalState();
}

class _LoanTransactionModalState extends ConsumerState<LoanTransactionModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _txType;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _txType = widget.initialTxType;
    if (widget.editTx != null) {
      final formatter = NumberFormat('#,###', 'en_US');
      _amountController.text = formatter.format(widget.editTx!.amount);
      _noteController.text = widget.editTx!.note;
      _dueDate = widget.editTx!.dueDate;
      _txType = widget.editTx!.type;
    }
  }

  void _onAmountChanged(String value) {
    final cleanValue = value.replaceAll(',', '');
    final numValue = double.tryParse(cleanValue);

    if (numValue != null) {
      final formatter = NumberFormat('#,###', 'en_US');
      final formatted = formatter.format(numValue);
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

  void _addThousand() {
    final currentText = _amountController.text.replaceAll(',', '');
    if (currentText.isEmpty) {
      _amountController.text = '0';
      return;
    }
    
    final newText = currentText + '000';
    _onAmountChanged(newText);
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    final repo = ref.read(loanRepositoryProvider);
    
    // Calculate difference for updating contact balances
    double oldAmount = widget.editTx?.amount ?? 0;
    double amountDiff = amount - oldAmount;
    
    final tx = LoanTransaction(
      id: widget.editTx?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), // assuming string ID, wait, id is int or string? In sqlite it's integer usually but models use String, let's keep it null if new, or if model expects something else, wait. Let's look at `LoanTransaction`.
      // Actually `LoanTransaction` model has `id: ...` but it's optional string.
      // Wait, if it's auto-increment int, `id` should be omitted for insert. 
      // Let's use `copyWith` if editTx != null.
      loanId: widget.contact.id,
      amount: amount,
      type: _txType,
      date: widget.editTx?.date ?? DateTime.now(),
      dueDate: _dueDate,
      note: _noteController.text.trim(),
    );

    LoanTransaction finalTx = widget.editTx?.copyWith(
      amount: amount,
      dueDate: _dueDate,
      note: _noteController.text.trim(),
    ) ?? tx;

    double newRemaining = widget.contact.remainingAmount;
    double newTotal = widget.contact.totalAmount;
    bool isRepay = _txType == 'repay' || _txType == 'collect';

    if (isRepay) {
      newRemaining -= amountDiff;
    } else {
      newRemaining += amountDiff;
      newTotal += amountDiff;
    }

    String newStatus = newRemaining <= 0 ? 'settled' : 'active';
    if (newRemaining < 0) newRemaining = 0;

    final updatedContact = widget.contact.copyWith(
      remainingAmount: newRemaining,
      totalAmount: newTotal,
      status: newStatus,
    );

    if (widget.editTx != null) {
      await repo.updateLoanTransaction(finalTx);
    } else {
      await repo.insertLoanTransaction(finalTx);
      
      // Save to main ledger only for new transactions for now
      final mainTxType = widget.contact.type == 'borrowed'
          ? (isRepay ? 'expense' : 'income')
          : (isRepay ? 'income' : 'expense');
      
      final noteText = _noteController.text.isNotEmpty 
          ? _noteController.text 
          : (isRepay ? (widget.contact.type == 'borrowed' ? 'Trả tiền cho ' : 'Thu tiền từ ') : (widget.contact.type == 'borrowed' ? 'Vay thêm từ ' : 'Cho vay thêm ')) + widget.contact.contactName;

      await ref.read(transactionProvider.notifier).createTransactions([{
        'categoryId': mainTxType == 'income' ? 'cat_other_income' : 'cat_other_expense',
        'amount': amount,
        'type': mainTxType,
        'note': noteText,
      }]);
    }
    
    await ref.read(loanProvider.notifier).updateLoanContact(updatedContact);
    ref.invalidate(loanTransactionsProvider(widget.contact.id));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Số tiền',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: _addThousand,
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('000', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            onChanged: _onAmountChanged,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Ghi chú (Không bắt buộc)'),
          ),
          const SizedBox(height: 16),
          if (_txType == 'borrow' || _txType == 'lend')
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày hẹn trả'),
              subtitle: Text(_dueDate == null ? 'Chưa chọn' : DateFormat('dd/MM/yyyy').format(_dueDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (d != null) setState(() => _dueDate = d);
              },
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary, // Changed to Cyan (primary color)
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Lưu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
