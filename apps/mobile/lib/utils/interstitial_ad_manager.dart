import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  void loadAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          print('Interstitial ad loaded');

          // Setup callbacks
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('Ad showed fullscreen content');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('Ad dismissed fullscreen content');
              ad.dispose();
              _isAdLoaded = false;
              // Preload next ad
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Ad failed to show fullscreen content: $error');
              ad.dispose();
              _isAdLoaded = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showAd() {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      print('Interstitial ad not ready yet');
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
