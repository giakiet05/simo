import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/monthly_budget_provider.dart';
import '../repositories/category_repository.dart';
import '../utils/mock_data_generator.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../repositories/database_helper.dart';
import 'about_screen.dart';
import 'export_backup_screen.dart';
import '../widgets/category_icon_widget.dart';
import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedCurrency = 'VND';
  String _selectedLanguage = 'vi';
  String _selectedTheme = 'system';
  bool _initialized = false;

  void _updateCurrency(String currency) async {
    setState(() => _selectedCurrency = currency);
    await ref.read(settingsProvider.notifier).updateCurrency(currency);
  }

  void _updateLanguage(String lang) async {
    setState(() => _selectedLanguage = lang);
    await ref.read(settingsProvider.notifier).updateLanguage(lang);
  }

  void _updateTheme(String theme) async {
    setState(() => _selectedTheme = theme);
    await ref.read(settingsProvider.notifier).updateThemeMode(theme);
  }

  void _showGenerateMockDataDialog(BuildContext context, dynamic l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.teal),
              const SizedBox(width: 8),
              Text(l10n.generateMockData),
            ],
          ),
          content: Text(l10n.generateMockDataConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.locale == 'vi'
                            ? 'Đang tạo dữ liệu mẫu...'
                            : 'Generating mock data...'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                final generator = MockDataGenerator(CategoryRepository());
                await generator.generateMockData();

                // Reload all providers
                await ref.read(categoryProvider.notifier).loadCategories();
                await ref.read(walletProvider.notifier).loadWallets();
                await ref.read(transactionProvider.notifier).loadTransactions();
                await ref.read(loanProvider.notifier).loadLoans();
                await ref.read(recurringProvider.notifier).loadRecurringConfigs();
                await ref.read(savingGoalProvider.notifier).loadGoals();
                ref.invalidate(monthlyBudgetFamily);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.mockDataGenerated),
                      backgroundColor: Colors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(l10n.locale == 'vi' ? 'Tạo' : 'Generate'),
            ),
          ],
        );
      },
    );
  }

  void _showResetDataDialog(BuildContext context, dynamic l10n) {
    final controller = TextEditingController();
    bool isMatched = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.resetAllData,
                style: const TextStyle(color: Colors.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.resetAllDataConfirm,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final target = l10n.locale == 'vi' ? 'xoa' : 'delete';
                      setDialogState(() {
                        isMatched = val.trim().toLowerCase() == target;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: isMatched
                      ? () async {
                          Navigator.pop(context);
                          await DatabaseHelper.instance.clearAllData();
                          // Reload all providers
                          await ref.read(categoryProvider.notifier).loadCategories();
                          await ref.read(walletProvider.notifier).loadWallets();
                          await ref.read(transactionProvider.notifier).loadTransactions();
                          await ref.read(loanProvider.notifier).loadLoans();
                          await ref.read(recurringProvider.notifier).loadRecurringConfigs();
                          await ref.read(savingGoalProvider.notifier).loadGoals();
                          ref.invalidate(monthlyBudgetFamily);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.resetSuccess),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    l10n.locale == 'vi' ? 'XÓA' : 'DELETE',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (settings) {
          if (!_initialized) {
            _selectedCurrency = settings.currency;
            _selectedLanguage = settings.language;
            _selectedTheme = settings.themeMode;
            _initialized = true;
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Tài khoản & Xác thực
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
                      child: Text(
                        l10n.locale == 'vi' ? 'Tài khoản & Xác thực' : 'Account & Authentication',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final authState = ref.watch(authProvider);
                        final isAuth = authState.isAuthenticated && authState.user != null;

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: isAuth
                                ? Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.teal.withValues(alpha: 0.2),
                                        backgroundImage: authState.user?.avatarUrl != null
                                            ? NetworkImage(authState.user!.avatarUrl!)
                                            : null,
                                        child: authState.user?.avatarUrl == null
                                            ? Text(
                                                (authState.user?.displayName?.isNotEmpty == true
                                                        ? authState.user!.displayName![0]
                                                        : authState.user!.email[0])
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.teal,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              authState.user?.displayName ?? 'Người dùng Simo',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              authState.user!.email,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(l10n.locale == 'vi' ? 'Đăng xuất' : 'Sign Out'),
                                              content: Text(l10n.locale == 'vi'
                                                  ? 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này?'
                                                  : 'Are you sure you want to sign out?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: Text(l10n.cancel),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: Text(
                                                    l10n.locale == 'vi' ? 'Đăng xuất' : 'Sign Out',
                                                    style: const TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(authProvider.notifier).signOut();
                                          }
                                        },
                                        child: Text(l10n.locale == 'vi' ? 'Đăng xuất' : 'Sign Out'),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.account_circle_outlined, size: 28, color: Colors.teal),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l10n.locale == 'vi' ? 'Chưa đăng nhập' : 'Not signed in',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  l10n.locale == 'vi'
                                                      ? 'Đăng nhập để đồng bộ và sao lưu an toàn'
                                                      : 'Sign in to sync across devices',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 44,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          icon: authState.isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.login_rounded, size: 20),
                                          label: Text(
                                            l10n.locale == 'vi'
                                                ? 'Đăng nhập với Google'
                                                : 'Sign in with Google',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: authState.isLoading
                                              ? null
                                              : () async {
                                                  final ok = await ref
                                                      .read(authProvider.notifier)
                                                      .signInWithGoogle();
                                                  if (context.mounted && !ok && authState.errorMessage != null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(authState.errorMessage!),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                  } else if (context.mounted && ok) {
                                                    ref.read(syncProvider.notifier).syncNow();
                                                  }
                                                },
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tùy chọn chung
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
                      child: Text(
                        l10n.locale == 'vi' ? 'Tùy chọn chung' : 'General Preferences',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CategoryIconWidget(
                              colorOverride: Colors.purple,
                              iconDataOverride: Icons.dark_mode,
                            ),
                            title: Text(l10n.locale == 'vi' ? 'Giao diện' : 'Theme', style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: DropdownButton<String>(
                              value: _selectedTheme,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down),
                              items: [
                                DropdownMenuItem(value: 'light', child: Text(l10n.locale == 'vi' ? 'Sáng' : 'Light')),
                                DropdownMenuItem(value: 'dark', child: Text(l10n.locale == 'vi' ? 'Tối' : 'Dark')),
                                DropdownMenuItem(value: 'system', child: Text(l10n.locale == 'vi' ? 'Hệ thống' : 'System')),
                              ],
                              onChanged: (val) {
                                if (val != null) _updateTheme(val);
                              },
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                          ListTile(
                            leading: const CategoryIconWidget(
                              colorOverride: Colors.blueAccent,
                              iconDataOverride: Icons.language,
                            ),
                            title: Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: DropdownButton<String>(
                              value: _selectedLanguage,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down),
                              items: [
                                DropdownMenuItem(value: 'vi', child: Text(l10n.vietnamese)),
                                DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                                DropdownMenuItem(value: 'zh', child: Text(l10n.chinese)),
                              ],
                              onChanged: (val) {
                                if (val != null) _updateLanguage(val);
                              },
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                          ListTile(
                            leading: const CategoryIconWidget(
                              colorOverride: Colors.green,
                              iconDataOverride: Icons.currency_exchange,
                            ),
                            title: Text(l10n.currency, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: DropdownButton<String>(
                              value: _selectedCurrency,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down),
                              items: CurrencyService.supportedCurrencies.map((currency) {
                                return DropdownMenuItem<String>(
                                  value: currency['code'],
                                  child: Text('${currency['code']} (${currency['symbol']})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) _updateCurrency(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Sao lưu & Xuất dữ liệu
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        l10n.exportBackup,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: const CategoryIconWidget(
                          colorOverride: Colors.indigo,
                          iconDataOverride: Icons.import_export_rounded,
                        ),
                        title: Text(
                          l10n.exportBackup,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExportBackupScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    // Đám mây & Đồng bộ
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        l10n.locale == 'vi' ? 'Đồng bộ đám mây (Cloud Sync)' : 'Cloud Synchronization',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final syncState = ref.watch(syncProvider);
                          return Column(
                            children: [
                              ListTile(
                                leading: CategoryIconWidget(
                                  colorOverride: syncState.status == SyncStatus.error
                                      ? Colors.red
                                      : (syncState.status == SyncStatus.syncing
                                          ? Colors.orange
                                          : Colors.teal),
                                  iconDataOverride: syncState.status == SyncStatus.syncing
                                      ? Icons.sync
                                      : (syncState.status == SyncStatus.error
                                          ? Icons.sync_problem
                                          : Icons.cloud_done_rounded),
                                ),
                                title: Text(
                                  l10n.locale == 'vi' ? 'Đồng bộ đa thiết bị' : 'Multi-Device Sync',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      syncState.message ??
                                          (syncState.lastSyncedAt != null
                                              ? 'Đã đồng bộ: ${syncState.lastSyncedAt!.toLocal().toString().substring(0, 16)}'
                                              : 'Chưa đồng bộ'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: syncState.status == SyncStatus.error ? Colors.red : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: syncState.streamStatus == LiveStreamStatus.connected
                                                ? Colors.teal
                                                : (syncState.streamStatus == LiveStreamStatus.reconnecting ||
                                                        syncState.streamStatus == LiveStreamStatus.connecting
                                                    ? Colors.orange
                                                    : Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          syncState.streamStatus == LiveStreamStatus.connected
                                              ? 'Live SSE: Trực tiếp'
                                              : (syncState.streamStatus == LiveStreamStatus.reconnecting
                                                  ? 'Live SSE: Đang kết nối lại'
                                                  : (syncState.streamStatus == LiveStreamStatus.connecting
                                                      ? 'Live SSE: Đang kết nối'
                                                      : 'Live SSE: Tạm dừng / Ngoại tuyến')),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: syncState.streamStatus == LiveStreamStatus.connected
                                                ? Colors.teal
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: syncState.status == SyncStatus.syncing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.refresh, color: Colors.teal),
                                        onPressed: () async {
                                          final res = await ref.read(syncProvider.notifier).syncNow();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(res.message),
                                                backgroundColor: res.success ? Colors.teal : Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Dữ liệu & Thử nghiệm
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        l10n.dataAndTesting,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          if (kDebugMode) ...[
                            ListTile(
                              leading: const CategoryIconWidget(
                                colorOverride: Colors.teal,
                                iconDataOverride: Icons.auto_awesome,
                              ),
                              title: Text(
                                l10n.generateMockData,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                l10n.generateMockDataDesc,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showGenerateMockDataDialog(context, l10n),
                            ),
                            const Divider(height: 1, indent: 56),
                          ],
                          ListTile(
                            leading: const CategoryIconWidget(
                              colorOverride: Colors.redAccent,
                              iconDataOverride: Icons.delete_forever,
                            ),
                            title: Text(
                              l10n.resetAllData,
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.redAccent),
                            ),
                            subtitle: Text(
                              l10n.resetAllDataDesc,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showResetDataDialog(context, l10n),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    // Thông tin & Khác
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Text(
                        l10n.locale == 'vi' ? 'Khác' : 'Others',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const CategoryIconWidget(
                              colorOverride: Colors.orange,
                              iconDataOverride: Icons.info_outline,
                            ),
                            title: Text(l10n.about, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AboutScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Banner Ad - sticky at bottom
              const BannerAdWidget(key: ValueKey('settings_banner_ad')),
            ],
          );
        },
      ),
    );
  }
}


