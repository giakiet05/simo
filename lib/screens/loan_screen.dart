import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/currency_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/localization_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/settings_provider.dart';
import '../models/loan_contact.dart';
import '../widgets/loan_contact_modal.dart';
import 'loan_detail_screen.dart';

class LoanScreen extends ConsumerStatefulWidget {
  const LoanScreen({super.key});

  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.locale == 'vi' ? 'Sổ Nợ' : 'Loans'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const LoanContactModal(),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.locale == 'vi' ? 'Nợ (Phải trả)' : 'Borrowed (Payables)'),
              Tab(text: l10n.locale == 'vi' ? 'Cho vay (Phải thu)' : 'Lent (Receivables)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LoanListView(type: 'borrowed'),
            _LoanListView(type: 'lent'),
          ],
        ),
      ),
    );
  }
}

class _LoanListView extends ConsumerStatefulWidget {
  final String type;

  const _LoanListView({required this.type});

  @override
  ConsumerState<_LoanListView> createState() => _LoanListViewState();
}

class _LoanListViewState extends ConsumerState<_LoanListView> {
  String _formatAmount(double amount, String currency) {
    final symbol = CurrencyService.getSymbol(currency);
    final formatter = NumberFormat('#,###.##', 'en_US');
    return '${formatter.format(amount)} $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final contactsAsync = ref.watch(loanProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return contactsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (allContacts) {
        final contacts = allContacts.where((c) => c.type == widget.type).toList();
        
        return settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => const SizedBox.shrink(),
          data: (settings) {
            if (contacts.isEmpty) {
              return Center(
                child: Text(
                  l10n.locale == 'vi' ? (widget.type == 'borrowed' ? 'Chưa có khoản nợ nào' : 'Chưa có khoản cho vay nào') : 'No loans found',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            double totalPending = 0;
            for (var c in contacts) {
              totalPending += c.remainingAmount;
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.locale == 'vi' ? (widget.type == 'borrowed' ? 'Tổng nợ chưa trả:' : 'Tổng nợ chưa thu:') : 'Total pending:',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatAmount(totalPending, settings.currency),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(contact.contactName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _formatAmount(contact.remainingAmount, settings.currency),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoanDetailScreen(contact: contact),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
