import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsRepository {
  static const String _budgetKey = 'monthly_budget';
  static const String _currencyKey = 'currency';
  static const String _languageKey = 'language';
  static const String _themeModeKey = 'theme_mode';

  Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final budget = prefs.getDouble(_budgetKey) ?? 0.0;
    final currency = prefs.getString(_currencyKey) ?? 'VND';
    final themeMode = prefs.getString(_themeModeKey) ?? 'system';

    // Detect system language on first launch
    String language;
    if (prefs.containsKey(_languageKey)) {
      // User has already set language, use saved value
      language = prefs.getString(_languageKey)!;
    } else {
      // First launch: detect system locale
      final systemLocale = Platform.localeName; // e.g., 'vi_VN', 'en_US', 'zh_CN'
      final languageCode = systemLocale.split('_')[0]; // Extract 'vi', 'en', 'zh'

      // Map system locale to app language
      if (languageCode == 'vi') {
        language = 'vi';
        print('Detected Vietnamese system locale, using Vietnamese');
      } else if (languageCode == 'zh') {
        language = 'zh';
        print('Detected Chinese system locale, using Chinese');
      } else {
        language = 'en';
        print('Detected $languageCode system locale, using English');
      }

      // Save detected language for future launches
      await prefs.setString(_languageKey, language);
    }

    return Settings(
      monthlyBudget: budget,
      currency: currency,
      language: language,
      themeMode: themeMode,
    );
  }

  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_budgetKey, settings.monthlyBudget);
    await prefs.setString(_currencyKey, settings.currency);
    await prefs.setString(_languageKey, settings.language);
  }

  Future<void> updateBudget(double budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetKey, budget);
  }

  Future<void> updateCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  Future<void> updateLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  Future<void> updateThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
  }
}
