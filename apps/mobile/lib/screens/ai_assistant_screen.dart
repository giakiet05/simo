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
          builder: (_) => TransactionFormScreen(editTransactionId: tx.id),
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
            builder: (_) => TransactionFormScreen(editTransactionId: targetTx!.id),
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
            Text(
              'Mô hình GPT-4o-mini',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa lịch sử trò chuyện',
              onPressed: () {
                ref.read(aiAssistantProvider.notifier).clearChat();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? _buildEmptyWelcomeState(theme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg = state.messages[index];
                        final showHorizon = state.horizonIndex != null && index == state.horizonIndex;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showHorizon) const MemoryHorizonDivider(),
                            AiMessageBubble(
                              message: msg,
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
            if (state.messages.isNotEmpty && !state.isListening)
              AiQuickPrompts(
                onSelectPrompt: (prompt) {
                  _textController.text = prompt;
                  _handleSend();
                },
              ),
            _buildInputArea(theme, state),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWelcomeState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 48,
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
            const SizedBox(height: 32),
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
    if (state.isListening) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.recognizedSpeechText.isEmpty
                  ? 'Đang nghe... (Tự động dừng sau ${state.silenceCountdown}s)'
                  : '"${state.recognizedSpeechText}"',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                ref.read(aiAssistantProvider.notifier).stopListening(onNavigate: _handleNavigate);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chạm vào nút để gửi ngay',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

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
              Icons.mic,
              color: theme.colorScheme.primary,
            ),
            tooltip: 'Nói lệnh bằng giọng nói',
            onPressed: state.isProcessing
                ? null
                : () {
                    ref.read(aiAssistantProvider.notifier).startListening(onNavigate: _handleNavigate);
                  },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              enabled: !state.isProcessing,
              decoration: InputDecoration(
                hintText: 'Nhập chi tiêu hoặc câu hỏi...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: theme.hintColor,
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
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
