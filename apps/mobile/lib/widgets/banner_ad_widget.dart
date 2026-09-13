import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';
import '../config/ads_config.dart';
import '../providers/ad_free_provider.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadAd();
  }

  @override
  void didUpdateWidget(BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Prevent reload on rebuild
    if (_bannerAd == null && !_isDisposed) {
      _checkAndLoadAd();
    }
  }

  void _checkAndLoadAd() {
    // Check if user is in ad-free period via provider
    final isAdFree = ref.read(adFreeProvider);
    if (isAdFree) {
      // Don't load ad
      return;
    }

    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted && !_isDisposed) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted && !_isDisposed) {
            setState(() {
              _bannerAd = null;
            });
          }
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ads disabled in build config, don't show anything
    if (!AdsConfig.adsEnabled) {
      return const SizedBox.shrink();
    }

    // Watch ad-free status from provider
    final isAdFree = ref.watch(adFreeProvider);
    if (isAdFree) {
      return const SizedBox.shrink();
    }

    if (_isDisposed || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
