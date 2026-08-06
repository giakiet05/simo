import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_contact.dart';
import '../models/loan_transaction.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../widgets/loan_transaction_modal.dart';
import '../widgets/loan_contact_modal.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final LoanContact contact;

  const LoanDetailScreen({super.key, required this.contact});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};

  String _formatAmount(double amount, String currency) {
    final symbol = CurrencyService.getSymbol(currency);
    final formatter = NumberFormat('#,###.##', 'en_US');
    return '${formatter.format(amount)} $symbol';
  }

  void _showTransactionModal(LoanContact currentContact, String txType, [LoanTransaction? editTx]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LoanTransactionModal(
        contact: currentContact,
        initialTxType: txType,
        editTx: editTx,
      ),
    );
  }

  Future<void> _deleteSelected(LoanContact currentContact, List<LoanTransaction> transactions) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá giao dịch'),
        content: Text('Bạn có chắc chắn muốn xoá ${_selectedTransactionIds.length} giao dịch đã chọn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(loanRepositoryProvider);

    for (var txId in _selectedTransactionIds) {
      await repo.deleteLoanTransaction(txId);
    }
    
    // Recalculate balances completely
    final updatedTxs = await repo.getLoanTransactions(currentContact.id);
    double newRemaining = 0;
    double newTotal = 0;
    for (var tx in updatedTxs) {
      bool isRepay = tx.type == 'repay' || tx.type == 'collect';
      if (isRepay) {
        newRemaining -= tx.amount;
      } else {
        newRemaining += tx.amount;
        newTotal += tx.amount;
      }
    }

    if (newRemaining < 0) newRemaining = 0;

    final updatedContact = currentContact.copyWith(
      remainingAmount: newRemaining,
      totalAmount: newTotal,
      status: newRemaining <= 0 ? 'settled' : 'active',
    );

    await ref.read(loanProvider.notifier).updateLoanContact(updatedContact);
    ref.invalidate(loanTransactionsProvider(currentContact.id));

    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  void _showActionMenu(LoanContact currentContact, LoanTransaction tx) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Sửa'),
              onTap: () {
                Navigator.pop(context);
                _showTransactionModal(currentContact, tx.type, tx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                setState(() {
                  _selectedTransactionIds.add(tx.id);
                });
                await _deleteSelected(currentContact, [tx]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box),
              title: const Text('Chọn nhiều'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = true;
                  _selectedTransactionIds.add(tx.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContactMenu(LoanContact currentContact) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Sửa người giao dịch'),
              onTap: () {
                Navigator.pop(sheetContext);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => LoanContactModal(editContact: currentContact),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa người giao dịch', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Xóa người giao dịch'),
                    content: const Text('Bạn có chắc muốn xóa người này? Toàn bộ giao dịch nợ liên quan cũng sẽ bị xóa.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(loanProvider.notifier).deleteLoanContact(currentContact.id);
                  if (mounted) Navigator.pop(context); // Go back to LoanScreen
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final allContactsAsync = ref.watch(loanProvider);
    
    final currentContact = allContactsAsync.maybeWhen(
      data: (contacts) => contacts.firstWhere((c) => c.id == widget.contact.id, orElse: () => widget.contact),
      orElse: () => widget.contact,
    );
    
    final txAsync = ref.watch(loanTransactionsProvider(currentContact.id));

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (!didPop && _isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedTransactionIds.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedTransactionIds.length} đã chọn')
            : Text(currentContact.contactName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedTransactionIds.clear();
                  });
                },
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedTransactionIds.isEmpty
                      ? null
                      : () => txAsync.whenData((txs) => _deleteSelected(currentContact, txs)),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showContactMenu(currentContact),
                ),
              ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const SizedBox.shrink(),
        data: (settings) {
          return Column(
            children: [
              if (!_isSelectionMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    children: [
                      Text(
                        currentContact.type == 'borrowed' ? 'Tổng nợ chưa trả' : 'Tổng nợ chưa thu',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatAmount(currentContact.remainingAmount, settings.currency),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              if (!_isSelectionMode)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.remove),
                          label: Text(currentContact.type == 'borrowed' ? 'Trả' : 'Thu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _showTransactionModal(currentContact, currentContact.type == 'borrowed' ? 'repay' : 'collect'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(currentContact.type == 'borrowed' ? 'Vay' : 'Cho vay'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _showTransactionModal(currentContact, currentContact.type == 'borrowed' ? 'borrow' : 'lend'),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: txAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(child: Text('Chưa có giao dịch nào'));
                    }
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isPositive = tx.type == 'borrow' || tx.type == 'lend';
                        final isSelected = _selectedTransactionIds.contains(tx.id);
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                          child: ListTile(
                            leading: _isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) _selectedTransactionIds.add(tx.id);
                                      else _selectedTransactionIds.remove(tx.id);
                                    });
                                  }
                                )
                              : CircleAvatar(
                                  backgroundColor: isPositive ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  child: Icon(isPositive ? Icons.add : Icons.remove, 
                                             color: isPositive ? Colors.red : Colors.green),
                                ),
                            title: Text(tx.note.isEmpty ? (isPositive ? (currentContact.type == 'borrowed' ? 'Vay' : 'Cho vay') : (currentContact.type == 'borrowed' ? 'Trả' : 'Thu')) : tx.note),
                            subtitle: Text(
                              isPositive && tx.dueDate != null
                                  ? 'Hẹn trả: ${DateFormat('dd/MM/yyyy').format(tx.dueDate!)}\nNgày: ${DateFormat('dd/MM/yyyy').format(tx.date)}'
                                  : 'Ngày: ${DateFormat('dd/MM/yyyy').format(tx.date)}'
                            ),
                            trailing: Text(
                              '${isPositive ? '+' : '-'}${_formatAmount(tx.amount, settings.currency)}',
                              style: TextStyle(
                                color: isPositive ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            onTap: _isSelectionMode
                              ? () {
                                  setState(() {
                                    if (isSelected) _selectedTransactionIds.remove(tx.id);
                                    else _selectedTransactionIds.add(tx.id);
                                  });
                                }
                              : () => _showActionMenu(currentContact, tx),
                            onLongPress: _isSelectionMode
                              ? null
                              : () {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedTransactionIds.add(tx.id);
                                  });
                                },
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          );
        }
      ),
      ),
    );
  }
}
