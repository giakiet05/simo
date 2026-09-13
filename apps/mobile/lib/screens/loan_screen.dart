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
  final int initialTab;
  const LoanScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends ConsumerState<LoanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locale == 'vi' ? 'Sổ Nợ' : 'Loans'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.locale == 'vi' ? 'Thêm người liên hệ' : 'Add contact',
            onPressed: () {
              final tabIndex = _tabController.index;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => LoanContactModal(
                  initialType: tabIndex == 0 ? 'borrowed' : 'lent',
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: l10n.locale == 'vi' ? 'Nợ (Phải trả)' : 'Borrowed (Payables)'),
            Tab(text: l10n.locale == 'vi' ? 'Cho vay (Phải thu)' : 'Lent (Receivables)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LoanListView(type: 'borrowed'),
          _LoanListView(type: 'lent'),
        ],
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
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          child: Text(
                            contact.contactName.isNotEmpty ? contact.contactName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
