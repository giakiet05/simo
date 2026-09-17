import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ai_message.dart';

/// Card rendering debt ledger (receivables and payables) inside the AI chat stream.
class AiDebtLedgerCard extends StatelessWidget {
  final DebtLedgerViewPayload payload;
  final void Function(String contactId)? onContactTap;

  const AiDebtLedgerCard({
    super.key,
    required this.payload,
    this.onContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.handshake_outlined, size: 16, color: Colors.teal),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sổ theo dõi vay nợ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary Pill
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cần thu',
                        style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        currencyFormatter.format(payload.totalReceivable),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cần trả',
                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        currencyFormatter.format(payload.totalPayable),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (payload.contacts.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payload.contacts.length > 4 ? 4 : payload.contacts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final c = payload.contacts[index];
                final isReceivable = c.type == 'lent';
                return InkWell(
                  onTap: () => onContactTap?.call(c.id),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Row(
                      children: [
                        Icon(
                          isReceivable ? Icons.arrow_outward : Icons.arrow_downward,
                          size: 14,
                          color: isReceivable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c.contactName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(c.remainingAmount),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isReceivable ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
