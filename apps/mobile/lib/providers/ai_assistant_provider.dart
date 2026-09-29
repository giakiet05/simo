import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_message.dart';
import '../repositories/ai_message_repository.dart';

import '../agent/engine/react_agent.dart';
import '../agent/engine/agent_event.dart';
import '../agent/memory/agent_memory_context.dart';
import '../agent/memory/pending_intent_state.dart';
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

/// State representation of the conversational AI Assistant.
class AiAssistantState {
  final List<AiMessage> messages;
  final bool isListening;
  final bool isProcessing;
  final String recognizedSpeechText;
  final int silenceCountdown;
  final String? errorMessage;
  final int? horizonIndex;
  final PendingIntent? pendingIntent;

  const AiAssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isProcessing = false,
    this.recognizedSpeechText = '',
    this.silenceCountdown = 5,
    this.errorMessage,
    this.horizonIndex,
    this.pendingIntent,
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
    PendingIntent? pendingIntent,
    bool clearPendingIntent = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      recognizedSpeechText: recognizedSpeechText ?? this.recognizedSpeechText,
      silenceCountdown: silenceCountdown ?? this.silenceCountdown,
      errorMessage: errorMessage,
      horizonIndex: clearHorizon ? null : (horizonIndex ?? this.horizonIndex),
      pendingIntent: clearPendingIntent ? null : (pendingIntent ?? this.pendingIntent),
    );
  }
}

/// Provider for the AI message repository.
final aiMessageRepositoryProvider = Provider<AiMessageRepository>((ref) {
  return AiMessageRepository();
});

/// State notifier managing dialogue turns, multimodal input, decoupled brain orchestration, and tool execution.
class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final Ref _ref;
  final AiMessageRepository _aiMessageRepository;
  final ToolRegistry _toolRegistry = ToolRegistry();
  late final SpeechRecognitionService _speechService;
  Timer? _countdownTimer;

  AiAssistantNotifier(
    this._ref, {
    AiMessageRepository? aiMessageRepository,
  })  : _aiMessageRepository = aiMessageRepository ?? AiMessageRepository(),
        super(const AiAssistantState()) {
    _speechService = SpeechServiceFactory.create();
    _registerDefaultTools();
    _loadPersistedMessages();
  }

  /// Loads recent conversational turns from SQLite upon initialization.
  Future<void> _loadPersistedMessages() async {
    try {
      final recent = await _aiMessageRepository.getRecentMessages(maxTurns: 50);
      if (!mounted) return;
      if (recent.isNotEmpty) {
        final horizon = AgentMemoryContext.calculateHorizonIndex(recent);
        state = state.copyWith(
          messages: recent,
          horizonIndex: horizon,
        );
      }
    } catch (e) {
      debugPrint('AiAssistantNotifier: Failed to load persisted chat messages: $e');
    }
  }

  void _registerDefaultTools() {
    // Read Tools
    _toolRegistry.register(QueryTransactionsTool());
    _toolRegistry.register(ViewWalletsTool());
    _toolRegistry.register(ViewBudgetsTool());
    _toolRegistry.register(ViewDebtsTool());
    _toolRegistry.register(ViewGoalsTool());

    // Write Tools - Full CRUD across 7 entities
    _toolRegistry.register(CreateTransactionTool());
    _toolRegistry.register(UpdateTransactionTool());
    _toolRegistry.register(DeleteTransactionTool());

    _toolRegistry.register(CreateWalletTool());
    _toolRegistry.register(UpdateWalletTool());
    _toolRegistry.register(DeleteWalletTool());
    _toolRegistry.register(AdjustWalletBalanceTool());
    _toolRegistry.register(TransferWalletTool());

    _toolRegistry.register(SetBudgetTool());
    _toolRegistry.register(DeleteBudgetTool());

    _toolRegistry.register(CreateLoanTool());
    _toolRegistry.register(UpdateLoanTool());
    _toolRegistry.register(DeleteLoanTool());
    _toolRegistry.register(RepayLoanTool());

    _toolRegistry.register(CreateGoalTool());
    _toolRegistry.register(UpdateGoalTool());
    _toolRegistry.register(DeleteGoalTool());
    _toolRegistry.register(GoalDepositTool());
    _toolRegistry.register(GoalWithdrawTool());

    _toolRegistry.register(CreateRecurringTool());
    _toolRegistry.register(UpdateRecurringTool());
    _toolRegistry.register(DeleteRecurringTool());

    _toolRegistry.register(CreateCategoryTool());
    _toolRegistry.register(UpdateCategoryTool());
    _toolRegistry.register(DeleteCategoryTool());

    // Navigation Tool
    _toolRegistry.register(NavigateScreenTool());
  }

  /// Returns the registered tools registry for testing and inspection.
  ToolRegistry get toolRegistry => _toolRegistry;

  /// Sends a text message to the AI agent and executes any resulting financial operations.
  Future<void> sendMessage(
    String rawText, {
    Future<void> Function(String route, {Map<String, dynamic>? arguments})? onNavigate,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isProcessing) return;

    // Immediately cancel any speech recording/transcription and timers in flight
    _countdownTimer?.cancel();
    if (state.isListening) {
      await _speechService.cancel();
    }

    // Allocate a unique turnId for this dialogue turn
    final turnId = const Uuid().v4();
    final userMessage = AiMessage.user(text, turnId: turnId);
    final thinkingMessage = AiMessage.assistantThinking(turnId: turnId);

    // Persist user prompt immediately to SQLite
    unawaited(_aiMessageRepository.insertMessage(userMessage).catchError((e) {
      debugPrint('AiAssistantNotifier: Failed to persist user message: $e');
    }));

    final updatedMessages = [...state.messages, userMessage, thinkingMessage];
    final horizon = AgentMemoryContext.calculateHorizonIndex(updatedMessages);

    if (mounted) {
      state = state.copyWith(
        messages: updatedMessages,
        isListening: false,
        isProcessing: true,
        errorMessage: null,
        recognizedSpeechText: '',
        horizonIndex: horizon,
      );
    }

    try {
      final executionContext = AgentExecutionContext(
        ref: _ref,
        onNavigate: onNavigate,
      );

      // Extract bounded 10-turn sliding history
      final workingHistory = AgentMemoryContext.extractWorkingTurns(state.messages);

      // Build live financial snapshot
      final snapshot = FinancialSnapshotBuilder.buildSystemContext(_ref);

      // Execute via ReActAgent
      final reactAgent = ReActAgent(
        toolRegistry: _toolRegistry,
        executionContext: executionContext,
      );

      await for (final event in reactAgent.run(
        userInput: text,
        financialSnapshot: snapshot,
        workingHistory: workingHistory,
      )) {
        if (!mounted) return;

        if (event is AgentFinalAnswerEvent) {
          final assistantMessage = AiMessage.assistant(
            content: event.content,
            turnId: turnId,
            actions: event.actions,
            viewPayload: event.viewPayload,
          );

          // Persist assistant message and prune old turns
          try {
            await _aiMessageRepository.insertMessage(assistantMessage);
            await _aiMessageRepository.pruneOldTurns(maxTurns: 50);
          } catch (e) {
            debugPrint('AiAssistantNotifier: Failed to persist assistant message: $e');
          }

          final newMessages = _replaceThinkingMessage(
            thinkingMessage.id,
            assistantMessage,
          );
          final prunedMessages = _pruneInMemoryMessages(newMessages, maxTurns: 50);

          final newHorizon = AgentMemoryContext.calculateHorizonIndex(prunedMessages);
          state = state.copyWith(
            messages: prunedMessages,
            recognizedSpeechText: '',
            horizonIndex: newHorizon,
          );
        } else if (event is AgentErrorEvent) {
          debugPrint('AiAssistantNotifier: ReAct AgentErrorEvent: ${event.errorMessage}');
        }
      }
    } catch (e) {
      debugPrint('AiAssistantNotifier error: $e');
      String errorText = e.toString();
      if (errorText.startsWith('Exception: ')) {
        errorText = errorText.substring(11);
      }
      if (mounted) {
        final errorMessage = AiMessage.error(
          errorMessage: errorText,
          turnId: turnId,
        );

        // Persist error message and prune old turns
        try {
          await _aiMessageRepository.insertMessage(errorMessage);
          await _aiMessageRepository.pruneOldTurns(maxTurns: 50);
        } catch (err) {
          debugPrint('AiAssistantNotifier: Failed to persist error message: $err');
        }

        final newMessages = _replaceThinkingMessage(
          thinkingMessage.id,
          errorMessage,
        );
        final prunedMessages = _pruneInMemoryMessages(newMessages, maxTurns: 50);

        final newHorizon = AgentMemoryContext.calculateHorizonIndex(prunedMessages);
        state = state.copyWith(
          messages: prunedMessages,
          recognizedSpeechText: '',
          horizonIndex: newHorizon,
        );
      }
    } finally {
      if (mounted) {
        state = state.copyWith(
          isProcessing: false,
          recognizedSpeechText: '',
        );
      }
    }
  }

  /// Begins speech recording and live transcription into chat text.
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
          if (mounted && state.isListening && !state.isProcessing) {
            state = state.copyWith(recognizedSpeechText: text);
            _resetSilenceTimer();
          }
        },
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  /// Stops ongoing speech recording without auto-sending.
  Future<void> stopListening() async {
    _countdownTimer?.cancel();
    if (!state.isListening) return;

    if (mounted) {
      state = state.copyWith(isListening: false);
    }
    await _speechService.stop();
  }

  /// Clears active conversation history and deletes all persisted messages from SQLite.
  Future<void> clearChat() async {
    if (!mounted) return;
    _countdownTimer?.cancel();
    _speechService.cancel();
    state = state.copyWith(
      messages: [],
      isListening: false,
      errorMessage: null,
      recognizedSpeechText: '',
      clearHorizon: true,
      clearPendingIntent: true,
    );
    try {
      await _aiMessageRepository.clearAll();
    } catch (e) {
      debugPrint('AiAssistantNotifier: Failed to clear persisted chat messages: $e');
    }
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

  List<AiMessage> _replaceThinkingMessage(String placeholderId, AiMessage newMessage) {
    return state.messages.map((m) {
      return m.id == placeholderId ? newMessage : m;
    }).toList();
  }

  /// Prunes in-memory messages to retain only the latest [maxTurns] conversational turns.
  List<AiMessage> _pruneInMemoryMessages(List<AiMessage> messages, {int maxTurns = 50}) {
    if (messages.isEmpty) return messages;
    final turnIds = <String>{};
    for (int i = messages.length - 1; i >= 0; i--) {
      turnIds.add(messages[i].turnId);
      if (turnIds.length >= maxTurns) break;
    }
    return messages.where((m) => turnIds.contains(m.turnId)).toList();
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
  final repo = ref.watch(aiMessageRepositoryProvider);
  return AiAssistantNotifier(ref, aiMessageRepository: repo);
});
