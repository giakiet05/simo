import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_message.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/loan_contact.dart';
import '../models/saving_goal.dart';
import '../services/ai_action_dispatcher.dart';
import '../services/ai_transaction_service.dart';
import '../services/speech/speech_recognition_service.dart';
import '../services/speech/speech_service_factory.dart';
import 'category_provider.dart';
import 'wallet_provider.dart';
import 'loan_provider.dart';
import 'saving_goal_provider.dart';
import 'transaction_provider.dart';

/// State representation of the conversational AI Assistant.
class AiAssistantState {
  final List<AiMessage> messages;
  final bool isListening;
  final bool isProcessing;
  final String recognizedSpeechText;
  final int silenceCountdown;
  final String? errorMessage;

  const AiAssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isProcessing = false,
    this.recognizedSpeechText = '',
    this.silenceCountdown = 5,
    this.errorMessage,
  });

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isListening,
    bool? isProcessing,
    String? recognizedSpeechText,
    int? silenceCountdown,
    String? errorMessage,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      recognizedSpeechText: recognizedSpeechText ?? this.recognizedSpeechText,
      silenceCountdown: silenceCountdown ?? this.silenceCountdown,
      errorMessage: errorMessage,
    );
  }
}

/// State notifier managing dialogue turns, multimodal input, and agent action dispatch.
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  final AiTransactionService _aiService = AiTransactionService();
  late final SpeechRecognitionService _speechService;
  Timer? _countdownTimer;

  AiAssistantNotifier(this._ref) : super(const AiAssistantState()) {
    _speechService = SpeechServiceFactory.create();
  }

  /// Sends a text message to the AI agent and executes any resulting financial operations.
  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isProcessing) return;

    final userMessage = AiMessage.user(text);
    final thinkingMessage = AiMessage.assistantThinking();

    // Append user message and thinking placeholder
    if (mounted) {
      state = state.copyWith(
        messages: [...state.messages, userMessage, thinkingMessage],
        isProcessing: true,
        errorMessage: null,
        recognizedSpeechText: '',
      );
    }

    try {
      final categories = _ref.read(categoryProvider).value ?? [];
      final wallets = _ref.read(walletProvider).value ?? [];
      final loans = _ref.read(loanProvider).value ?? [];
      final goals = _ref.read(savingGoalProvider).value ?? [];

      // Build financial snapshot for context awareness
      final summaryContext = _buildFinancialSummary();

      // Collect last 6 conversational turns
      final chatHistory = <Map<String, String>>[];
      for (final msg in state.messages) {
        if (msg.id == thinkingMessage.id) continue;
        if (msg.role == AiMessageRole.user) {
          chatHistory.add({'role': 'user', 'content': msg.content});
        } else if (msg.role == AiMessageRole.assistant && msg.content.isNotEmpty) {
          chatHistory.add({'role': 'assistant', 'content': msg.content});
        }
      }
      final trimmedHistory = chatHistory.length > 6
          ? chatHistory.sublist(chatHistory.length - 6)
          : chatHistory;

      final parsed = await _aiService.parseUserIntent(
        spokenText: text,
        categories: categories,
        wallets: wallets,
        loanContacts: loans,
        savingGoals: goals,
        financialSummaryContext: summaryContext,
        chatHistory: trimmedHistory,
      );

      if (!mounted) return;

      if (parsed == null) {
        throw Exception('Không thể kết nối với AI. Vui lòng kiểm tra lại kết nối mạng.');
      }

      final isSuccess = parsed['isSuccess'] as bool? ?? false;
      final responseMessage = parsed['responseMessage'] as String? ??
          parsed['message'] as String? ??
          'Tôi đã nhận được thông tin của bạn.';

      if (!isSuccess && (parsed['actions'] as List<dynamic>? ?? []).isEmpty) {
        // Pure conversational or unhandled reply without mutations
        _replaceThinkingMessage(
          thinkingMessage.id,
          AiMessage.assistant(content: responseMessage),
        );
        return;
      }

      // Execute extracted actions via existing dispatcher
      final actionsList = parsed['actions'] as List<dynamic>? ?? [];
      final executedActions = <AiExecutedAction>[];

      if (actionsList.isNotEmpty) {
        await AiActionDispatcher.dispatch(
          ref: _ref,
          aiResult: parsed,
          availableWallets: wallets,
          availableLoanContacts: loans,
          availableSavingGoals: goals,
        );

        for (final rawAction in actionsList) {
          if (rawAction is! Map<String, dynamic>) continue;
          final executed = _formatExecutedAction(
            rawAction,
            categories,
            wallets,
            loans,
            goals,
          );
          executedActions.add(executed);
        }
      }

      if (mounted) {
        _replaceThinkingMessage(
          thinkingMessage.id,
          AiMessage.assistant(
            content: responseMessage,
            actions: executedActions,
          ),
        );
      }
    } catch (e) {
      debugPrint('AiAssistantNotifier error: $e');
      String errorText = e.toString();
      if (errorText.startsWith('Exception: ')) {
        errorText = errorText.substring(11);
      }
      if (mounted) {
        _replaceThinkingMessage(
          thinkingMessage.id,
          AiMessage.error(errorMessage: errorText),
        );
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  /// Begins speech recording and live transcription.
  Future<void> startListening() async {
    if (state.isListening || state.isProcessing) return;

    final available = await _speechService.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'listening') {
          state = state.copyWith(isListening: true, silenceCountdown: 5);
        } else if (status == 'done' || status == 'notListening') {
          _countdownTimer?.cancel();
          state = state.copyWith(isListening: false);
          if (state.recognizedSpeechText.isNotEmpty) {
            sendMessage(state.recognizedSpeechText);
          }
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        if (mounted) {
          state = state.copyWith(isListening: false, errorMessage: error);
        }
      },
    );

    if (available && mounted) {
      state = state.copyWith(
        isListening: true,
        recognizedSpeechText: '',
        silenceCountdown: 5,
      );
      _resetSilenceTimer();
      await _speechService.startListening(
        onResult: (text) {
          if (mounted) {
            state = state.copyWith(recognizedSpeechText: text);
            _resetSilenceTimer();
          }
        },
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  /// Stops ongoing speech recording and dispatches any captured speech text.
  Future<void> stopListening() async {
    _countdownTimer?.cancel();
    if (!state.isListening) return;

    if (mounted) {
      state = state.copyWith(isListening: false);
    }
    await _speechService.stop();
    if (state.recognizedSpeechText.isNotEmpty) {
      sendMessage(state.recognizedSpeechText);
    }
  }

  /// Clears active conversation history.
  void clearChat() {
    if (!mounted) return;
    state = state.copyWith(
      messages: [],
      errorMessage: null,
      recognizedSpeechText: '',
    );
  }

  void _resetSilenceTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !state.isListening) {
        timer.cancel();
        return;
      }
      if (state.silenceCountdown > 1) {
        state = state.copyWith(silenceCountdown: state.silenceCountdown - 1);
      } else {
        timer.cancel();
        stopListening();
      }
    });
  }

  void _replaceThinkingMessage(String placeholderId, AiMessage newMessage) {
    if (!mounted) return;
    final updated = state.messages.map((m) {
      return m.id == placeholderId ? newMessage : m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  String _buildFinancialSummary() {
    try {
      final txList = _ref.read(transactionProvider).value ?? [];
      final now = DateTime.now();
      final todayTxs = txList.where((tx) {
        return tx.transactionDate.year == now.year &&
            tx.transactionDate.month == now.month &&
            tx.transactionDate.day == now.day;
      }).toList();

      double todayExpense = 0;
      double todayIncome = 0;
      for (final tx in todayTxs) {
        if (tx.type == 'expense') {
          todayExpense += tx.amount;
        } else {
          todayIncome += tx.amount;
        }
      }

      return 'Tong chi tieu hom nay: ${todayExpense.toInt()} VND, Tong thu hom nay: ${todayIncome.toInt()} VND, So luong giao dich hom nay: ${todayTxs.length}.';
    } catch (_) {
      return 'Chua co du lieu chi tieu hom nay.';
    }
  }

  AiExecutedAction _formatExecutedAction(
    Map<String, dynamic> rawAction,
    List<Category> categories,
    List<Wallet> wallets,
    List<LoanContact> loans,
    List<SavingGoal> goals,
  ) {
    final actionType = rawAction['actionType'] as String? ?? 'transaction';
    final double amount = (rawAction['amount'] as num?)?.toDouble() ?? 0.0;
    final note = rawAction['note'] as String? ?? '';

    String title = 'Giao dịch';
    String subtitle = note;

    switch (actionType) {
      case 'transaction':
        final isExpense = (rawAction['type'] as String? ?? 'expense') == 'expense';
        title = isExpense ? 'Khoản chi tiêu' : 'Khoản thu nhập';
        final catId = rawAction['categoryId'] as String?;
        final catName = categories.where((c) => c.id == catId).firstOrNull?.name ?? 'Khác';
        final walletId = rawAction['walletId'] as String?;
        final walletName = wallets.where((w) => w.id == walletId).firstOrNull?.name ?? 'Mặc định';
        subtitle = '$catName • Ví $walletName${note.isNotEmpty ? ' ($note)' : ''}';
        break;

      case 'transfer':
        title = 'Chuyển khoản ví';
        final srcId = rawAction['sourceWalletId'] as String?;
        final dstId = rawAction['destinationWalletId'] as String?;
        final srcName = wallets.where((w) => w.id == srcId).firstOrNull?.name ?? 'Ví nguồn';
        final dstName = wallets.where((w) => w.id == dstId).firstOrNull?.name ?? 'Ví đích';
        subtitle = 'Từ $srcName ➔ $dstName';
        break;

      case 'loan_create':
        final isLent = (rawAction['loanType'] as String? ?? 'lent') == 'lent';
        title = isLent ? 'Cho vay / Mượn' : 'Đi vay / Mượn';
        final contactName = rawAction['contactName'] as String? ?? 'Người quen';
        subtitle = 'Đối tượng: $contactName';
        break;

      case 'loan_repay':
        final isCollect = (rawAction['repayType'] as String? ?? 'collect') == 'collect';
        title = isCollect ? 'Thu nợ' : 'Trả nợ';
        final contactName = rawAction['contactName'] as String? ?? 'Người quen';
        subtitle = 'Đối tượng: $contactName';
        break;

      case 'goal_deposit':
        title = 'Tích lũy mục tiêu';
        final goalName = rawAction['goalName'] as String? ?? 'Heo đất';
        subtitle = 'Mục tiêu: $goalName';
        break;

      case 'goal_withdraw':
        title = 'Rút tiền mục tiêu';
        final goalName = rawAction['goalName'] as String? ?? 'Heo đất';
        subtitle = 'Mục tiêu: $goalName';
        break;
    }

    return AiExecutedAction.fromRawAction(
      rawAction: rawAction,
      title: title,
      subtitle: subtitle,
      isSuccess: amount > 0,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _speechService.cancel();
    super.dispose();
  }
}

/// Global provider for the conversational AI Assistant.
final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier(ref);
});
