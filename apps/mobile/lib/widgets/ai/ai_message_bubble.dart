import 'package:flutter/material.dart';
import '../../models/ai_message.dart';
import 'ai_action_card.dart';
import '../../agent/ui/cards/ai_transaction_list_card.dart';
import '../../agent/ui/cards/ai_wallet_summary_card.dart';
import '../../agent/ui/cards/ai_budget_progress_card.dart';
import '../../agent/ui/cards/ai_debt_ledger_card.dart';
import '../../agent/ui/cards/ai_saving_goals_card.dart';

/// Widget rendering a dialogue bubble for user or assistant turns in the chat stream.
class AiMessageBubble extends StatelessWidget {
  final AiMessage message;
  final void Function(String)? onTransactionTap;
  final void Function(String)? onWalletTap;
  final void Function(String)? onLoanContactTap;
  final void Function(String)? onSavingGoalTap;
  final VoidCallback? onBudgetTap;
  final void Function(AiExecutedAction)? onActionTap;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.onTransactionTap,
    this.onWalletTap,
    this.onLoanContactTap,
    this.onSavingGoalTap,
    this.onBudgetTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubbleBody(context, isUser),

                // Render Action Confirmation Cards
                if (message.actions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...message.actions.map((action) => AiActionCard(
                        action: action,
                        onTap: onActionTap,
                      )),
                ],

                // Render Generative UI View Query Card
                if (message.viewPayload != null) ...[
                  const SizedBox(height: 4),
                  _buildViewPayloadCard(context, message.viewPayload!),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewPayloadCard(BuildContext context, AiViewPayload payload) {
    if (payload is TransactionListViewPayload) {
      return AiTransactionListCard(
        payload: payload,
        onItemTap: onTransactionTap,
      );
    } else if (payload is WalletSummaryViewPayload) {
      return AiWalletSummaryCard(
        payload: payload,
        onWalletTap: onWalletTap,
      );
    } else if (payload is BudgetProgressViewPayload) {
      return AiBudgetProgressCard(
        payload: payload,
        onBudgetTap: onBudgetTap,
      );
    } else if (payload is DebtLedgerViewPayload) {
      return AiDebtLedgerCard(
        payload: payload,
        onContactTap: onLoanContactTap,
      );
    } else if (payload is SavingGoalsViewPayload) {
      return AiSavingGoalsCard(
        payload: payload,
        onGoalTap: onSavingGoalTap,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBubbleBody(BuildContext context, bool isUser) {
    final theme = Theme.of(context);

    if (message.status == AiMessageStatus.thinking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI đang phân tích & xử lý...',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    if (message.status == AiMessageStatus.error) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.errorMessage ?? 'Đã xảy ra lỗi khi kết nối AI.',
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 14,
          color: isUser ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
          height: 1.4,
        ),
      ),
    );
  }
}
