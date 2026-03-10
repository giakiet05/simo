import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdHelper {
  // Load Ad Unit IDs từ .env file

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Fallback to test ID if .env not loaded or empty
      return dotenv.env['ADMOB_BANNER_AD_UNIT_ID'] ?? 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256716/2934735716'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID'] ??
             'ca-app-pub-3940256099942544/1033173712'; // Test ID fallback
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_REWARDED_AD_UNIT_ID'] ??
             'ca-app-pub-3940256099942544/5224354917'; // Test ID fallback
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
