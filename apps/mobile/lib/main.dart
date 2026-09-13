import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'providers/sync_provider.dart';

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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconnect SSE stream and pull latest changes from server
      ref.read(syncProvider.notifier).resumeLiveSync();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      // Pause SSE stream to save battery and network in background
      ref.read(syncProvider.notifier).pauseLiveSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    // Eagerly initialize and monitor sync connectivity
    ref.watch(syncProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Simo - Simple Money Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(settingsAsync.value?.themeMode ?? 'system'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
        Locale('zh'),
      ],
      locale: Locale(settingsAsync.value?.language ?? 'vi'),
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
