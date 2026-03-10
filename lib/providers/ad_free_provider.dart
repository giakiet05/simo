import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rewarded_ad_service.dart';

class AdFreeNotifier extends StateNotifier<bool> {
  Timer? _expiryTimer;
  Timer? _periodicTimer;

  AdFreeNotifier() : super(false) {
    _checkStatus();
    _startPeriodicCheck();
  }

  Future<void> _checkStatus() async {
    final isActive = await RewardedAdService.isAdFreeActive();
    if (state != isActive) {
      state = isActive;
    }

    if (isActive) {
      _scheduleExpiryCheck();
    } else {
      _cancelExpiryTimer();
    }
  }

  void _startPeriodicCheck() {
    // Check every 5 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatus();
    });
  }

  Future<void> _scheduleExpiryCheck() async {
    _cancelExpiryTimer();

    final remaining = await RewardedAdService.getRemainingAdFreeTime();
    if (remaining != null && remaining.inSeconds > 0) {
      // Schedule a timer to check when ad-free expires
      _expiryTimer = Timer(remaining, () {
        _checkStatus();
      });
    }
  }

  void _cancelExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  Future<void> refresh() async {
    await _checkStatus();
  }

  Future<void> grantAdFreeTime() async {
    await RewardedAdService.grantAdFreeTime();
    state = true;
    _scheduleExpiryCheck();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final adFreeProvider = StateNotifierProvider<AdFreeNotifier, bool>((ref) {
  return AdFreeNotifier();
});
