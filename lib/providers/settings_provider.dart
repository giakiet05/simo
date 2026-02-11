import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends StateNotifier<AsyncValue<Settings>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBudget(double budget) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    state = const AsyncValue.loading();
    try {
      await _repository.updateBudget(budget);
      state = AsyncValue.data(currentSettings.copyWith(monthlyBudget: budget));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateCurrency(String currency) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    state = const AsyncValue.loading();
    try {
      await _repository.updateCurrency(currency);
      state = AsyncValue.data(currentSettings.copyWith(currency: currency));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateLanguage(String language) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    state = const AsyncValue.loading();
    try {
      await _repository.updateLanguage(language);
      state = AsyncValue.data(currentSettings.copyWith(language: language));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<Settings>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
