import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ads_config.dart';
import '../utils/ad_helper.dart';

class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;
  static const String _adFreeUntilKey = 'ad_free_until_timestamp';

  static Future<void> loadRewardedAd() async {
    if (_isLoading || _rewardedAd != null) return;

    _isLoading = true;

    await RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  static Future<void> showRewardedAd({
    required Function() onUserEarnedReward,
    required Function() onAdDismissed,
  }) async {
    if (_rewardedAd == null) {
      onAdDismissed();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdDismissed();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdDismissed();
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward();
      },
    );

    _rewardedAd = null;
  }

  static Future<void> grantAdFreeTime() async {
    final prefs = await SharedPreferences.getInstance();
    final adFreeUntil = DateTime.now().add(
      Duration(seconds: AdsConfig.adFreeDurationSeconds),
    );
    await prefs.setInt(_adFreeUntilKey, adFreeUntil.millisecondsSinceEpoch);
  }

  static Future<bool> isAdFreeActive() async {
    final prefs = await SharedPreferences.getInstance();
    final adFreeUntilTimestamp = prefs.getInt(_adFreeUntilKey);

    if (adFreeUntilTimestamp == null) return false;

    final adFreeUntil = DateTime.fromMillisecondsSinceEpoch(adFreeUntilTimestamp);
    final isActive = DateTime.now().isBefore(adFreeUntil);

    if (!isActive) {
      await prefs.remove(_adFreeUntilKey);
    }

    return isActive;
  }

  static Future<Duration?> getRemainingAdFreeTime() async {
    final prefs = await SharedPreferences.getInstance();
    final adFreeUntilTimestamp = prefs.getInt(_adFreeUntilKey);

    if (adFreeUntilTimestamp == null) return null;

    final adFreeUntil = DateTime.fromMillisecondsSinceEpoch(adFreeUntilTimestamp);
    final remaining = adFreeUntil.difference(DateTime.now());

    if (remaining.isNegative) {
      await prefs.remove(_adFreeUntilKey);
      return null;
    }

    return remaining;
  }

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
