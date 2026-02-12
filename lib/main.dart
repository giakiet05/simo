import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/recurring_service.dart';
import 'utils/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Initialize sqflite for desktop platforms
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Process recurring transactions on app start
  final recurringService = RecurringService();
  await recurringService.processRecurringTransactions();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Auto navigate to home when user confirms email via deep link
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen(key: homeScreenKey)),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Simo - Simple Money Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: supabase.auth.currentUser != null
          ? HomeScreen(key: homeScreenKey)
          : const LoginScreen(),
    );
  }
}
