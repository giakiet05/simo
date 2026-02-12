import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/supabase.dart';
import '../utils/sync_service.dart';
import '../repositories/database_helper.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/settings_provider.dart';
import 'login_screen.dart';
import 'recurring_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isSyncing = false;

  Future<void> _sync() async {
    setState(() => _isSyncing = true);

    try {
      final syncService = SyncService();
      await syncService.sync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đồng bộ thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh providers to show updated data
        ref.invalidate(categoryProvider);
        ref.invalidate(transactionProvider);
        ref.invalidate(recurringProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đồng bộ thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?\n\nDữ liệu sẽ được đồng bộ lên cloud trước khi đăng xuất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang đồng bộ dữ liệu...'),
            ],
          ),
        ),
      ),
    );

    try {
      // Sync first to push any local changes to cloud
      print('[LOGOUT] Starting sync before logout...');
      final syncService = SyncService();
      await syncService.sync();
      print('[LOGOUT] Sync completed');

      // Invalidate all providers to clear cache
      ref.invalidate(categoryProvider);
      ref.invalidate(transactionProvider);
      ref.invalidate(recurringProvider);
      ref.invalidate(settingsProvider);

      // Clear local database - delete in correct order to avoid FK constraint errors
      final db = await DatabaseHelper.instance.database;

      // Delete in order: child tables first, then parent tables
      final deletedPending = await db.delete('pending_deletions');
      final deletedTx = await db.delete('transactions');
      final deletedConfigs = await db.delete('recurring_configs');
      final deletedCats = await db.delete('categories');

      print('[LOGOUT] Deleted: $deletedPending pending, $deletedTx tx, $deletedConfigs configs, $deletedCats categories');

      // Logout from Supabase
      await supabase.auth.signOut();

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('[LOGOUT] Error: $e');

      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? 'Chưa đăng nhập';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _sync,
              icon: _isSyncing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ dữ liệu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Giao dịch định kỳ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecurringScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Cài đặt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Về ứng dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
