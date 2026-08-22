import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/loan_provider.dart';
import '../repositories/category_repository.dart';
import '../utils/mock_data_generator.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../repositories/database_helper.dart';
import 'about_screen.dart';
import 'export_backup_screen.dart';
import '../widgets/category_icon_widget.dart';

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
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
                await ref.read(transactionProvider.notifier).loadTransactions();
                await ref.read(loanProvider.notifier).loadLoans();

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
                          await ref.read(transactionProvider.notifier).loadTransactions();
                          await ref.read(loanProvider.notifier).loadLoans();

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
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
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
                          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
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
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
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
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
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


