import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'config/ads_config.dart';
import 'screens/home_screen.dart';
import 'utils/recurring_service.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize sqflite for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize AdMob only if enabled and on supported platforms (non-blocking)
  if (AdsConfig.adsEnabled && (Platform.isAndroid || Platform.isIOS)) {
    MobileAds.instance.initialize();
  }

  // Process recurring transactions on app start (non-blocking)
  final recurringService = RecurringService();
  recurringService.processRecurringTransactions();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Simo - Simple Money Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(settingsAsync.value?.themeMode ?? 'system'),
      home: HomeScreen(key: homeScreenKey),
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
