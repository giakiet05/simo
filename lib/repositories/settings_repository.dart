import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsRepository {
  static const String _budgetKey = 'monthly_budget';
  static const String _currencyKey = 'currency';
  static const String _languageKey = 'language';

  Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final budget = prefs.getDouble(_budgetKey) ?? 0.0;
    final currency = prefs.getString(_currencyKey) ?? 'VND';
    final language = prefs.getString(_languageKey) ?? 'vi';

    return Settings(
      monthlyBudget: budget,
      currency: currency,
      language: language,
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
}
