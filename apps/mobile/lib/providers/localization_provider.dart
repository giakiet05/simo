import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/localization.dart';
import 'settings_provider.dart';

final localizationProvider = Provider<AppLocalizations>((ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) => AppLocalizations(settings.language),
    loading: () => AppLocalizations('vi'),
    error: (_, __) => AppLocalizations('vi'),
  );
});
