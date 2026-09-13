import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import '../services/live_sync_service.dart';
export '../services/live_sync_service.dart' show LiveStreamStatus;
import 'transaction_provider.dart';
import 'wallet_provider.dart';
import 'category_provider.dart';
import 'monthly_budget_provider.dart';
import 'saving_goal_provider.dart';
import 'loan_provider.dart';
import 'recurring_provider.dart';

/// SyncStatus represents the live state of data synchronization.
enum SyncStatus { idle, syncing, success, error }

/// SyncState holds state data for the sync provider.
class SyncState {
  final SyncStatus status;
  final LiveStreamStatus streamStatus;
  final String? message;
  final DateTime? lastSyncedAt;
  final int lastPushedCount;
  final int lastPulledCount;

  const SyncState({
    this.status = SyncStatus.idle,
    this.streamStatus = LiveStreamStatus.disconnected,
    this.message,
    this.lastSyncedAt,
    this.lastPushedCount = 0,
    this.lastPulledCount = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    LiveStreamStatus? streamStatus,
    String? message,
    DateTime? lastSyncedAt,
    int? lastPushedCount,
    int? lastPulledCount,
  }) {
    return SyncState(
      status: status ?? this.status,
      streamStatus: streamStatus ?? this.streamStatus,
      message: message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastPushedCount: lastPushedCount ?? this.lastPushedCount,
      lastPulledCount: lastPulledCount ?? this.lastPulledCount,
    );
  }
}

/// SyncNotifier coordinates UI sync triggers and invalidations.
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  final LiveSyncService _liveSyncService;
  final Ref _ref;
  StreamSubscription<LiveStreamStatus>? _streamStatusSubscription;

  SyncNotifier(this._syncService, this._liveSyncService, this._ref) : super(const SyncState()) {
    _syncService.startNetworkMonitoring(() {
      syncNow();
    });

    // Wire live stream callbacks
    _liveSyncService.setOnDataChangedCallback(() {
      syncNow();
    });

    _streamStatusSubscription = _liveSyncService.statusStream.listen((streamStatus) {
      state = state.copyWith(streamStatus: streamStatus);
    });

    // Auto-sync & start SSE stream on boot
    Future.microtask(() {
      syncNow();
      _liveSyncService.connect();
    });
  }

  /// Executes manual or auto sync and updates provider state.
  Future<SyncResult> syncNow({String? customBaseUrl, String? customToken}) async {
    state = state.copyWith(status: SyncStatus.syncing, message: 'Đang đồng bộ dữ liệu...');
    final result = await _syncService.sync(
      customBaseUrl: customBaseUrl,
      customToken: customToken,
    );

    if (result.success) {
      state = state.copyWith(
        status: SyncStatus.success,
        message: 'Đồng bộ thành công (${result.pushedCount} tải lên, ${result.pulledCount} tải về)',
        lastSyncedAt: result.serverTime ?? DateTime.now(),
        lastPushedCount: result.pushedCount,
        lastPulledCount: result.pulledCount,
      );

      // Invalidate local state providers if new changes were pulled down
      if (result.pulledCount > 0) {
        _ref.invalidate(transactionProvider);
        _ref.invalidate(walletProvider);
        _ref.invalidate(categoryProvider);
        _ref.invalidate(monthlyBudgetFamily);
        _ref.invalidate(savingGoalProvider);
        _ref.invalidate(loanProvider);
        _ref.invalidate(recurringProvider);
      }
    } else {
      state = state.copyWith(
        status: SyncStatus.error,
        message: result.message,
      );
    }

    return result;
  }

  /// Triggers a debounced background sync after local mutation.
  void triggerDebouncedSync() {
    _syncService.triggerDebouncedSync(onSyncCompleted: () {
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: DateTime.now(),
      );
    });
  }

  /// Pauses live sync stream when app transitions to background.
  void pauseLiveSync() {
    _liveSyncService.pause();
  }

  /// Resumes live sync stream and catches up deltas when app transitions to foreground.
  void resumeLiveSync() {
    _liveSyncService.resume();
    syncNow();
  }

  @override
  void dispose() {
    _streamStatusSubscription?.cancel();
    _liveSyncService.dispose();
    _syncService.dispose();
    super.dispose();
  }
}

/// Global provider for SyncService.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Global provider for LiveSyncService.
final liveSyncServiceProvider = Provider<LiveSyncService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final liveService = LiveSyncService(syncService: syncService);
  ref.onDispose(() => liveService.dispose());
  return liveService;
});

/// Global provider for SyncState and operations.
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final liveSyncService = ref.watch(liveSyncServiceProvider);
  return SyncNotifier(syncService, liveSyncService, ref);
});
