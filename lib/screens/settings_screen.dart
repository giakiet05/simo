import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _budgetController = TextEditingController();
  String _selectedCurrency = 'VND';
  String _selectedLanguage = 'vi';
  bool _initialized = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  String _formatBudgetForDisplay(double budget) {
    if (budget == budget.toInt()) {
      return NumberFormat('#,###').format(budget.toInt());
    }
    return NumberFormat('#,###.##').format(budget);
  }

  void _onBudgetChanged(String value) {
    final cleanValue = value.replaceAll(',', '');
    final numValue = double.tryParse(cleanValue);

    if (numValue != null) {
      final formatted = _formatBudgetForDisplay(numValue);
      if (formatted != value) {
        final cursorPos = _budgetController.selection.baseOffset;
        final oldCommas = value.substring(0, cursorPos).split(',').length - 1;

        _budgetController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: cursorPos + (formatted.split(',').length - 1 - oldCommas),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (settings) {
          if (!_initialized) {
            _budgetController.text = _formatBudgetForDisplay(settings.monthlyBudget);
            _selectedCurrency = settings.currency;
            _selectedLanguage = settings.language;
            _initialized = true;
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  l10n.monthlyBudgetSetting,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: l10n.monthlyBudgetSetting,
                  ),
                  onChanged: _onBudgetChanged,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.currency,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VND', child: Text('VND')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.language,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'vi', child: Text(l10n.vietnamese)),
                    DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final cleanText = _budgetController.text.replaceAll(',', '');
                      final budget = double.tryParse(cleanText) ?? 0.0;

                      await ref
                          .read(settingsProvider.notifier)
                          .updateBudget(budget);
                      await ref
                          .read(settingsProvider.notifier)
                          .updateCurrency(_selectedCurrency);
                      await ref
                          .read(settingsProvider.notifier)
                          .updateLanguage(_selectedLanguage);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.settingsSaved)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.save),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.about),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}
