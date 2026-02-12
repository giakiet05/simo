import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/supabase.dart';
import '../utils/sync_service.dart';
import '../repositories/database_helper.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureDefaultCategoriesForNewUser() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Check if user has any data on cloud (categories OR transactions)
    final cloudCategories = await supabase
        .from('categories')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    final cloudTransactions = await supabase
        .from('transactions')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    // Only create default categories if user is TRULY NEW (no categories AND no transactions)
    if (cloudCategories.isEmpty && cloudTransactions.isEmpty) {
      // First login - create default categories
      print('[LOGIN] New user detected, creating default categories...');

      final db = await DatabaseHelper.instance.database;
      final defaultCategories = [
        {'id': 'cat_salary', 'name': 'Salary', 'type': 'income'},
        {'id': 'cat_bonus', 'name': 'Bonus', 'type': 'income'},
        {'id': 'cat_investment', 'name': 'Investment', 'type': 'income'},
        {'id': 'cat_other_income', 'name': 'Other Income', 'type': 'income'},
        {'id': 'cat_food', 'name': 'Food & Dining', 'type': 'expense'},
        {'id': 'cat_transport', 'name': 'Transportation', 'type': 'expense'},
        {'id': 'cat_shopping', 'name': 'Shopping', 'type': 'expense'},
        {'id': 'cat_entertainment', 'name': 'Entertainment', 'type': 'expense'},
        {'id': 'cat_bills', 'name': 'Bills & Utilities', 'type': 'expense'},
        {'id': 'cat_healthcare', 'name': 'Healthcare', 'type': 'expense'},
        {'id': 'cat_other_expense', 'name': 'Other', 'type': 'expense'},
      ];

      final now = DateTime.now().toIso8601String();
      for (var category in defaultCategories) {
        await db.insert('categories', {
          'id': category['id'],
          'name': category['name'],
          'type': category['type'],
          'synced': 0, // Mark as not synced to trigger PUSH
          'created_at': now,
          'updated_at': now,
        });
      }

      print('[LOGIN] Created ${defaultCategories.length} default categories');
    } else {
      print('[LOGIN] Existing user (has data on cloud), skipping default categories');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Navigate to home FIRST (like before)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(key: homeScreenKey)),
      );

      // Start loading immediately
      Future.microtask(() {
        homeScreenKey.currentState?.startLoading();
      });

      // Sync data in background AFTER navigation
      Future.delayed(const Duration(milliseconds: 100), () async {
        try {
          print('[LOGIN] Starting background sync...');

          // Debug: Check local categories before sync
          final db = await DatabaseHelper.instance.database;
          final localCats = await db.query('categories');
          print('[LOGIN] Local categories before sync: ${localCats.length}');

          // Check and create default categories for new users
          await _ensureDefaultCategoriesForNewUser();

          final syncService = SyncService();
          await syncService.sync();
          print('[LOGIN] Sync completed successfully');

          // Debug: Check local categories after sync
          final localCatsAfter = await db.query('categories');
          print('[LOGIN] Local categories after sync: ${localCatsAfter.length}');

          // Refresh HomeScreen after sync
          homeScreenKey.currentState?.refreshData();
          print('[LOGIN] HomeScreen refresh requested');
        } catch (syncError) {
          print('[LOGIN] Sync failed: $syncError');
          // Hide loading even if sync failed
          homeScreenKey.currentState?.refreshData();
        }
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Đăng nhập thất bại';

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('invalid login credentials') ||
            errorStr.contains('invalid_credentials')) {
          errorMessage = 'Email hoặc mật khẩu không đúng';
        } else if (errorStr.contains('email not confirmed') ||
                   errorStr.contains('email_not_confirmed')) {
          errorMessage = 'Vui lòng xác nhận email trước khi đăng nhập.\nKiểm tra hộp thư của bạn.';
        } else if (errorStr.contains('network') ||
                   errorStr.contains('fetch')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
        } else {
          errorMessage = 'Đăng nhập thất bại: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Simo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quản lý tài chính đơn giản',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('Đăng ký'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
