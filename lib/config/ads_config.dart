/// Ads configuration
/// Use --dart-define to control ads:
/// - flutter build apk --dart-define=ENABLE_ADS=true  (with ads)
/// - flutter build apk --dart-define=ENABLE_ADS=false (no ads)

class AdsConfig {
  // Check if ads are enabled via build-time environment variable
  static const bool _enableAdsEnv = bool.fromEnvironment(
    'ENABLE_ADS',
    defaultValue: true, // Default: có ads
  );

  /// Whether ads are enabled in this build
  static bool get adsEnabled => _enableAdsEnv;

  /// Debug info
  static String get buildType => adsEnabled ? 'With Ads' : 'No Ads';

  // Ad Unit IDs are loaded from AdHelper (with fallback logic)

  /// Ad-free duration after watching rewarded ad (in seconds)
  /// Production: 43200 seconds (12 hours)
  static const int adFreeDurationSeconds = 43200;
}
