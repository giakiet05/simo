import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_message.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/loan_contact.dart';
import '../models/saving_goal.dart';

import '../agent/brain/agent_brain.dart';
import '../agent/memory/agent_memory_context.dart';
import '../agent/memory/financial_snapshot_builder.dart';
import '../agent/tools/agent_tool.dart';
import '../agent/tools/tool_registry.dart';

import '../agent/tools/read/query_transactions_tool.dart';
import '../agent/tools/read/view_wallets_tool.dart';
import '../agent/tools/read/view_budgets_tool.dart';
import '../agent/tools/read/view_debts_tool.dart';
import '../agent/tools/read/view_goals_tool.dart';

import '../agent/tools/write/category_tools.dart';
import '../agent/tools/write/transaction_tools.dart';
import '../agent/tools/write/wallet_tools.dart';
import '../agent/tools/write/budget_tools.dart';
import '../agent/tools/write/loan_tools.dart';
import '../agent/tools/write/goal_tools.dart';
import '../agent/tools/write/recurring_tools.dart';
import '../agent/tools/navigation/navigate_screen_tool.dart';

import '../services/speech/speech_recognition_service.dart';
import '../services/speech/speech_service_factory.dart';
import 'category_provider.dart';
import 'wallet_provider.dart';
import 'loan_provider.dart';
import 'saving_goal_provider.dart';

/// State representation of the conversational AI Assistant.
class AiAssistantState {
  final List<AiMessage> messages;
  final bool isListening;
  final bool isProcessing;
  final String recognizedSpeechText;
  final int silenceCountdown;
  final String? errorMessage;
  final int? horizonIndex;

  const AiAssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isProcessing = false,
    this.recognizedSpeechText = '',
    this.silenceCountdown = 5,
    this.errorMessage,
    this.horizonIndex,
  });

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isListening,
    bool? isProcessing,
    String? recognizedSpeechText,
    int? silenceCountdown,
    String? errorMessage,
    int? horizonIndex,
    bool clearHorizon = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      recognizedSpeechText: recognizedSpeechText ?? this.recognizedSpeechText,
      silenceCountdown: silenceCountdown ?? this.silenceCountdown,
      errorMessage: errorMessage,
      horizonIndex: clearHorizon ? null : (horizonIndex ?? this.horizonIndex),
    );
  }
}

/// State notifier managing dialogue turns, multimodal input, decoupled brain orchestration, and tool execution.
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  final AgentBrain _brain = AgentBrain();
  final ToolRegistry _toolRegistry = ToolRegistry();
  late final SpeechRecognitionService _speechService;
  Timer? _countdownTimer;

  AiAssistantNotifier(this._ref) : super(const AiAssistantState()) {
    _speechService = SpeechServiceFactory.create();
    _registerDefaultTools();
  }

  void _registerDefaultTools() {
    // Read Tools
    _toolRegistry.register(QueryTransactionsTool());
    _toolRegistry.register(ViewWalletsTool());
    _toolRegistry.register(ViewBudgetsTool());
    _toolRegistry.register(ViewDebtsTool());
    _toolRegistry.register(ViewGoalsTool());

    // Write Tools
    _toolRegistry.register(CreateTransactionTool());
    _toolRegistry.register(UpdateTransactionTool());
    _toolRegistry.register(DeleteTransactionTool());
    _toolRegistry.register(CreateWalletTool());
    _toolRegistry.register(AdjustWalletBalanceTool());
    _toolRegistry.register(TransferWalletTool());
    _toolRegistry.register(SetBudgetTool());
    _toolRegistry.register(CreateLoanTool());
    _toolRegistry.register(RepayLoanTool());
    _toolRegistry.register(CreateGoalTool());
    _toolRegistry.register(GoalDepositTool());
    _toolRegistry.register(GoalWithdrawTool());
    _toolRegistry.register(CreateRecurringTool());
    _toolRegistry.register(CreateCategoryTool());
    _toolRegistry.register(DeleteCategoryTool());

    // Navigation Tool
    _toolRegistry.register(NavigateScreenTool());
  }

  /// Sends a text message to the AI agent and executes any resulting financial operations.
  Future<void> sendMessage(
    String rawText, {
    Future<void> Function(String route, {Map<String, dynamic>? arguments})? onNavigate,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isProcessing) return;

    final userMessage = AiMessage.user(text);
    final thinkingMessage = AiMessage.assistantThinking();

    final updatedMessages = [...state.messages, userMessage, thinkingMessage];
    final horizon = AgentMemoryContext.calculateHorizonIndex(updatedMessages);

    if (mounted) {
      state = state.copyWith(
        messages: updatedMessages,
        isProcessing: true,
        errorMessage: null,
        recognizedSpeechText: '',
        horizonIndex: horizon,
      );
    }

    try {
      final categories = _ref.read(categoryProvider).value ?? [];
      final wallets = _ref.read(walletProvider).value ?? [];
      final loans = _ref.read(loanProvider).value ?? [];
      final goals = _ref.read(savingGoalProvider).value ?? [];

      // Extract bounded 10-turn sliding history
      final workingHistory = AgentMemoryContext.extractWorkingTurns(state.messages);

      // Build live financial snapshot
      final snapshot = FinancialSnapshotBuilder.buildSystemContext(_ref);

      // Process via Agent Brain
      final brainResult = await _brain.process(
        userInput: text,
        financialSnapshot: snapshot,
        workingHistory: workingHistory,
      );

      if (!mounted) return;

      final executionContext = AgentExecutionContext(
        ref: _ref,
        onNavigate: onNavigate,
      );

      // Execute Mutations (actions)
      final executedActions = <AiExecutedAction>[];
      for (final actionMap in brainResult.actions) {
        final actionType = actionMap['actionType'] as String? ?? 'transaction_create';
        try {
          await _toolRegistry.dispatch(actionType, actionMap, executionContext);
          final executed = _formatExecutedAction(
            actionMap,
            categories,
            wallets,
            loans,
            goals,
          );
          executedActions.add(executed);
        } catch (err) {
          debugPrint('AiAssistantNotifier: Error executing action $actionType: $err');
        }
      }

      // Execute View Queries (Generative UI)
      AiViewPayload? viewPayload;
      if (brainResult.viewQuery != null) {
        final viewType = brainResult.viewQuery!['viewType'] as String?;
        if (viewType != null) {
          try {
            final result = await _toolRegistry.dispatch(
              viewType,
              brainResult.viewQuery!,
              executionContext,
            );
            if (result is AiViewPayload) {
              viewPayload = result;
            }
          } catch (err) {
            debugPrint('AiAssistantNotifier: Error executing view query $viewType: $err');
          }
        }
      }

      if (mounted) {
        final newMessages = _replaceThinkingMessage(
          thinkingMessage.id,
          AiMessage.assistant(
            content: brainResult.responseMessage,
            actions: executedActions,
            viewPayload: viewPayload,
          ),
        );

        final newHorizon = AgentMemoryContext.calculateHorizonIndex(newMessages);
        state = state.copyWith(
          messages: newMessages,
          horizonIndex: newHorizon,
        );
      }
    } catch (e) {
      debugPrint('AiAssistantNotifier error: $e');
      String errorText = e.toString();
      if (errorText.startsWith('Exception: ')) {
        errorText = errorText.substring(11);
      }
      if (mounted) {
        final newMessages = _replaceThinkingMessage(
          thinkingMessage.id,
          AiMessage.error(errorMessage: errorText),
        );
        final newHorizon = AgentMemoryContext.calculateHorizonIndex(newMessages);
        state = state.copyWith(
          messages: newMessages,
          horizonIndex: newHorizon,
        );
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isProcessing: false);
      }
    }
  }

  /// Begins speech recording and live transcription.
  Future<void> startListening({
    Future<void> Function(String route, {Map<String, dynamic>? arguments})? onNavigate,
  }) async {
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
            sendMessage(state.recognizedSpeechText, onNavigate: onNavigate);
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
      _resetSilenceTimer(onNavigate: onNavigate);
      await _speechService.startListening(
        onResult: (text) {
          if (mounted) {
            state = state.copyWith(recognizedSpeechText: text);
            _resetSilenceTimer(onNavigate: onNavigate);
          }
        },
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  /// Stops ongoing speech recording and dispatches any captured speech text.
  Future<void> stopListening({
    Future<void> Function(String route, {Map<String, dynamic>? arguments})? onNavigate,
  }) async {
    _countdownTimer?.cancel();
    if (!state.isListening) return;

    if (mounted) {
      state = state.copyWith(isListening: false);
    }
    await _speechService.stop();
    if (state.recognizedSpeechText.isNotEmpty) {
      sendMessage(state.recognizedSpeechText, onNavigate: onNavigate);
    }
  }

  /// Clears active conversation history.
  void clearChat() {
    if (!mounted) return;
    state = state.copyWith(
      messages: [],
      errorMessage: null,
      recognizedSpeechText: '',
      clearHorizon: true,
    );
  }

  void _resetSilenceTimer({
    Future<void> Function(String route, {Map<String, dynamic>? arguments})? onNavigate,
  }) {
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
        stopListening(onNavigate: onNavigate);
      }
    });
  }

  List<AiMessage> _replaceThinkingMessage(String placeholderId, AiMessage newMessage) {
    return state.messages.map((m) {
      return m.id == placeholderId ? newMessage : m;
    }).toList();
  }

  AiExecutedAction _formatExecutedAction(
    Map<String, dynamic> rawAction,
    List<Category> categories,
    List<Wallet> wallets,
    List<LoanContact> loans,
    List<SavingGoal> goals,
  ) {
    final actionType = rawAction['actionType'] as String? ?? 'transaction_create';
    final note = rawAction['note'] as String? ?? '';

    String title = 'Giao dịch';
    String subtitle = note;

    switch (actionType) {
      case 'transaction_create':
      case 'transaction':
        final isExpense = (rawAction['type'] as String? ?? 'expense') == 'expense';
        title = isExpense ? 'Khoản chi tiêu' : 'Khoản thu nhập';
        final catId = rawAction['categoryId'] as String?;
        final catName = categories.where((c) => c.id == catId).firstOrNull?.name ?? 'Khác';
        final walletId = rawAction['walletId'] as String?;
        final walletName = wallets.where((w) => w.id == walletId).firstOrNull?.name ?? 'Mặc định';
        subtitle = '$catName • Ví $walletName${note.isNotEmpty ? ' ($note)' : ''}';
        break;

      case 'transaction_update':
        title = 'Cập nhật giao dịch';
        subtitle = note.isNotEmpty ? note : 'Đã chỉnh sửa giao dịch';
        break;

      case 'transaction_delete':
        title = 'Xóa giao dịch';
        subtitle = note.isNotEmpty ? note : 'Đã xóa giao dịch khỏi hệ thống';
        break;

      case 'wallet_create':
        title = 'Tạo ví mới';
        final name = rawAction['walletName'] as String? ?? 'Ví mới';
        subtitle = 'Tên ví: $name';
        break;

      case 'wallet_adjust_balance':
        title = 'Điều chỉnh số dư';
        final name = rawAction['walletName'] as String? ?? 'Ví';
        subtitle = 'Cập nhật số dư ví $name';
        break;

      case 'transfer':
        title = 'Chuyển khoản ví';
        final srcId = rawAction['sourceWalletId'] as String?;
        final dstId = rawAction['destinationWalletId'] as String?;
        final srcName = wallets.where((w) => w.id == srcId).firstOrNull?.name ?? 'Ví nguồn';
        final dstName = wallets.where((w) => w.id == dstId).firstOrNull?.name ?? 'Ví đích';
        subtitle = 'Từ $srcName ➔ $dstName';
        break;

      case 'budget_set':
        title = 'Thiết lập ngân sách';
        final catName = rawAction['categoryName'] as String? ?? 'Tổng chi tiêu';
        subtitle = 'Hạn mức: $catName';
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

      case 'goal_create':
        title = 'Tạo mục tiêu tiết kiệm';
        final goalName = rawAction['goalName'] as String? ?? 'Mục tiêu mới';
        subtitle = 'Mục tiêu: $goalName';
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

      case 'recurring_create':
        title = 'Tạo giao dịch định kỳ';
        subtitle = 'Lặp lại: $note';
        break;

      case 'category_create':
        title = 'Tạo danh mục mới';
        final catName = rawAction['categoryName'] as String? ?? rawAction['name'] as String? ?? 'Danh mục mới';
        final catType = (rawAction['type'] as String? ?? 'expense') == 'income' ? 'Thu nhập' : 'Chi tiêu';
        subtitle = 'Tên danh mục: $catName ($catType)';
        break;

      case 'category_delete':
        title = 'Xóa danh mục';
        final delName = rawAction['categoryName'] as String? ?? 'Danh mục';
        subtitle = 'Đã xóa danh mục: $delName';
        break;

      case 'navigate_screen':
        title = 'Điều hướng màn hình';
        final destination = rawAction['destination'] as String? ?? 'Màn hình';
        subtitle = 'Đang mở $destination';
        break;
    }

    return AiExecutedAction.fromRawAction(
      rawAction: rawAction,
      title: title,
      subtitle: subtitle,
      isSuccess: true,
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
