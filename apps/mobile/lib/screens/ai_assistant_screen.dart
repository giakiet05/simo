import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_assistant_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/saving_goal_provider.dart';

import '../models/ai_message.dart';
import '../models/transaction.dart';
import '../models/loan_contact.dart';
import '../models/saving_goal.dart';

import '../agent/ui/memory_horizon_divider.dart';
import '../widgets/ai/ai_message_bubble.dart';
import '../widgets/ai/ai_quick_prompts.dart';

import 'category_budget_screen.dart';
import 'category_screen.dart';
import 'export_backup_screen.dart';
import 'loan_screen.dart';
import 'loan_detail_screen.dart';
import 'recurring_screen.dart';
import 'saving_goals_screen.dart';
import 'saving_goal_detail_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';
import 'transaction_form_screen.dart';
import 'wallet_detail_screen.dart';
import 'wallets_screen.dart';

/// Full conversational AI Assistant screen allowing ChatGPT-style text chatting
/// and voice dictation with autonomous financial action execution.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleNavigate(String route, {Map<String, dynamic>? arguments}) async {
    if (!mounted) return;

    Widget targetScreen;
    switch (route.toLowerCase()) {
      case 'reports':
      case 'statistics':
        targetScreen = const StatisticsScreen();
        break;
      case 'wallets':
        targetScreen = const WalletsScreen();
        break;
      case 'budgets':
        targetScreen = const CategoryBudgetScreen();
        break;
      case 'loans':
        targetScreen = const LoanScreen();
        break;
      case 'goals':
        targetScreen = const SavingGoalsScreen();
        break;
      case 'recurring':
        targetScreen = const RecurringScreen();
        break;
      case 'export_backup':
      case 'backup':
      case 'export':
        targetScreen = const ExportBackupScreen();
        break;
      case 'categories':
        targetScreen = const CategoryScreen();
        break;
      case 'settings':
        targetScreen = const SettingsScreen();
        break;
      default:
        return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(aiAssistantProvider.notifier).sendMessage(
          text,
          onNavigate: _handleNavigate,
        );
    _scrollToBottom();
  }

  void _handleTransactionTap(String transactionId) {
    final txs = ref.read(transactionProvider).value ?? [];
    final tx = txs.where((t) => t.id == transactionId).firstOrNull;
    if (tx != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TransactionFormScreen(
            editTransactionId: tx.id,
            editType: tx.type,
            editAmount: tx.amount.toString(),
            editFormula: tx.formula,
            editCategoryId: tx.categoryId,
            editWalletId: tx.walletId,
            editNote: tx.note,
            editTransactionDate: tx.transactionDate,
            editCreatedAt: tx.createdAt,
          ),
        ),
      );
    }
  }

  void _handleWalletTap(String walletId) {
    final wallets = ref.read(walletProvider).value ?? [];
    final wallet = wallets.where((w) => w.id == walletId).firstOrNull;
    if (wallet != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WalletDetailScreen(walletId: wallet.id),
        ),
      );
    }
  }

  void _handleLoanContactTap(String contactId) {
    final loans = ref.read(loanProvider).value ?? [];
    final loan = loans.where((l) => l.id == contactId).firstOrNull;
    if (loan != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoanDetailScreen(contact: loan),
        ),
      );
    }
  }

  void _handleSavingGoalTap(String goalId) {
    final goals = ref.read(savingGoalProvider).value ?? [];
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SavingGoalDetailScreen(goalId: goal.id),
        ),
      );
    }
  }

  void _handleBudgetTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CategoryBudgetScreen(),
      ),
    );
  }

  void _handleActionCardTap(AiExecutedAction action) {
    final type = action.actionType.toLowerCase();
    final raw = action.rawAction ?? {};

    if (type.startsWith('transaction')) {
      final txs = ref.read(transactionProvider).value ?? [];
      final rawId = raw['transactionId'] as String? ?? raw['id'] as String?;
      final targetNote = (raw['note'] as String?)?.toLowerCase();

      Transaction? targetTx;
      if (rawId != null && rawId.isNotEmpty) {
        targetTx = txs.where((t) => t.id == rawId).firstOrNull;
      }
      if (targetTx == null && targetNote != null && targetNote.isNotEmpty) {
        targetTx = txs.where((t) => (t.note ?? '').toLowerCase().contains(targetNote)).firstOrNull;
      }
      targetTx ??= txs.firstOrNull;

      if (targetTx != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionFormScreen(
              editTransactionId: targetTx!.id,
              editType: targetTx.type,
              editAmount: targetTx.amount.toString(),
              editFormula: targetTx.formula,
              editCategoryId: targetTx.categoryId,
              editWalletId: targetTx.walletId,
              editNote: targetTx.note,
              editTransactionDate: targetTx.transactionDate,
              editCreatedAt: targetTx.createdAt,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TransactionFormScreen(),
          ),
        );
      }
    } else if (type.startsWith('category')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CategoryScreen(),
        ),
      );
    } else if (type.startsWith('wallet') || type == 'transfer') {
      final wallets = ref.read(walletProvider).value ?? [];
      final wid = (raw['walletId'] as String?) ??
          (raw['destinationWalletId'] as String?) ??
          (raw['sourceWalletId'] as String?);
      final wallet = wid != null ? wallets.where((w) => w.id == wid).firstOrNull : null;
      if (wallet != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WalletDetailScreen(walletId: wallet.id),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const WalletsScreen(),
          ),
        );
      }
    } else if (type == 'budget_set') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CategoryBudgetScreen(),
        ),
      );
    } else if (type.startsWith('loan')) {
      final loans = ref.read(loanProvider).value ?? [];
      final cid = raw['contactId'] as String?;
      final cname = (raw['contactName'] as String?)?.toLowerCase();
      LoanContact? contact;
      if (cid != null) {
        contact = loans.where((l) => l.id == cid).firstOrNull;
      }
      if (contact == null && cname != null) {
        contact = loans.where((l) => l.contactName.toLowerCase().contains(cname)).firstOrNull;
      }
      if (contact != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LoanDetailScreen(contact: contact!),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const LoanScreen(),
          ),
        );
      }
    } else if (type.startsWith('goal')) {
      final goals = ref.read(savingGoalProvider).value ?? [];
      final gid = raw['goalId'] as String?;
      final gname = (raw['goalName'] as String?)?.toLowerCase();
      SavingGoal? goal;
      if (gid != null) {
        goal = goals.where((g) => g.id == gid).firstOrNull;
      }
      if (goal == null && gname != null) {
        goal = goals.where((g) => g.name.toLowerCase().contains(gname)).firstOrNull;
      }
      if (goal != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SavingGoalDetailScreen(goalId: goal!.id),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SavingGoalsScreen(),
          ),
        );
      }
    } else if (type.startsWith('recurring')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RecurringScreen(),
        ),
      );
    } else if (type == 'navigate_screen') {
      final dest = raw['destination'] as String? ?? '';
      _handleNavigate(dest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final theme = Theme.of(context);

    ref.listen(aiAssistantProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      // Update text controller only when new speech text arrives and not actively processing
      if (!next.isProcessing &&
          next.recognizedSpeechText.isNotEmpty &&
          next.recognizedSpeechText != previous?.recognizedSpeechText) {
        _textController.text = next.recognizedSpeechText;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
      // Ensure input controller is cleared whenever message submission starts
      if (previous?.isProcessing == false && next.isProcessing == true) {
        _textController.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trợ lý AI Simo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: state.isProcessing ? Colors.orange : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.isProcessing
                      ? 'Đang xử lý...'
                      : (state.isListening ? 'Đang nghe giọng nói...' : 'Trực tuyến (ReAct Agent)'),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xóa lịch sử hội thoại',
            onPressed: () {
              ref.read(aiAssistantProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isHorizonBoundary = state.horizonIndex != null &&
                          index == state.horizonIndex;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isHorizonBoundary)
                            const MemoryHorizonDivider(),
                          AiMessageBubble(
                            message: message,
                            onTransactionTap: _handleTransactionTap,
                            onWalletTap: _handleWalletTap,
                            onLoanContactTap: _handleLoanContactTap,
                            onSavingGoalTap: _handleSavingGoalTap,
                            onBudgetTap: _handleBudgetTap,
                            onActionTap: _handleActionCardTap,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          _buildInputArea(theme, state),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tôi có thể giúp gì cho bạn?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Nói hoặc gõ bằng tiếng Việt tự nhiên để ghi chép thu chi, đặt ngân sách, xem báo cáo, quản lý ví và sổ nợ.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AiQuickPrompts(
              onSelectPrompt: (prompt) {
                _textController.text = prompt;
                _handleSend();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, AiAssistantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              state.isListening ? Icons.mic : Icons.mic_none_rounded,
              color: state.isListening ? Colors.red : theme.colorScheme.primary,
            ),
            tooltip: state.isListening
                ? 'Đang nghe... Chạm để dừng'
                : 'Nói lệnh để nhập vào khung chat',
            onPressed: state.isProcessing
                ? null
                : () {
                    if (state.isListening) {
                      ref.read(aiAssistantProvider.notifier).stopListening();
                    } else {
                      ref.read(aiAssistantProvider.notifier).startListening();
                    }
                  },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              enabled: !state.isProcessing,
              decoration: InputDecoration(
                hintText: state.isListening
                    ? 'Đang nghe giọng nói của bạn...'
                    : 'Nhập chi tiêu hoặc câu hỏi...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: state.isListening ? Colors.red.shade700 : theme.hintColor,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                filled: true,
                fillColor: state.isListening
                    ? Colors.red.withValues(alpha: 0.05)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send_rounded, size: 20),
            tooltip: 'Gửi tin nhắn',
            onPressed: state.isProcessing ? null : _handleSend,
          ),
        ],
      ),
    );
  }
}
