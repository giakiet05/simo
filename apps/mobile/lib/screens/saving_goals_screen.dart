import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/localization_provider.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/saving_goal_card.dart';
import '../widgets/saving_goal_form_modal.dart';
import 'saving_goal_detail_screen.dart';

class SavingGoalsScreen extends ConsumerStatefulWidget {
  const SavingGoalsScreen({super.key});

  @override
  ConsumerState<SavingGoalsScreen> createState() => _SavingGoalsScreenState();
}

class _SavingGoalsScreenState extends ConsumerState<SavingGoalsScreen> {
  String _selectedFilter = 'all'; // 'all', 'in_progress', 'completed'

  void _openAddModal(dynamic l10n, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SavingGoalFormModal(
        currency: currency,
        l10n: l10n,
        onSave: (newGoal) {
          ref.read(savingGoalProvider.notifier).createGoal(newGoal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settings = ref.watch(settingsProvider).value;
    final currency = settings?.currency ?? 'VND';
    final currencySymbol = CurrencyService.getSymbol(currency);
    final numberFormat = NumberFormat('#,###');

    final goalsAsync = ref.watch(savingGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savingGoals),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addSavingGoal,
            onPressed: () => _openAddModal(l10n, currency),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: goalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (goals) {
                final totalTarget = goals.fold<double>(0.0, (sum, g) => sum + g.targetAmount);
                final totalSaved = goals.fold<double>(0.0, (sum, g) => sum + g.currentAmount);
                final overallPercent = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

                final filteredGoals = goals.where((g) {
                  if (_selectedFilter == 'in_progress') return !g.isCompleted;
                  if (_selectedFilter == 'completed') return g.isCompleted;
                  return true;
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Overview Summary Card (T014)
                    if (goals.isNotEmpty) ...[
                      _buildOverviewCard(
                        totalTarget: totalTarget,
                        totalSaved: totalSaved,
                        overallPercent: overallPercent,
                        currencySymbol: currencySymbol,
                        numberFormat: numberFormat,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', l10n.allGoals, goals.length),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'in_progress',
                              l10n.goalInProgress,
                              goals.where((g) => !g.isCompleted).length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'completed',
                              l10n.goalCompleted,
                              goals.where((g) => g.isCompleted).length,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Goals List or Empty State
                    if (filteredGoals.isEmpty)
                      _buildEmptyState(l10n, currency)
                    else
                      ...filteredGoals.map(
                        (goal) => SavingGoalCard(
                          goal: goal,
                          currency: currency,
                          l10n: l10n,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SavingGoalDetailScreen(goalId: goal.id),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required double totalTarget,
    required double totalSaved,
    required double overallPercent,
    required String currencySymbol,
    required NumberFormat numberFormat,
    required dynamic l10n,
  }) {
    final theme = Theme.of(context);
    final percentText = (overallPercent * 100).toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalSaved,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${numberFormat.format(totalSaved)} $currencySymbol',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${l10n.totalTarget}: ${numberFormat.format(totalTarget)} $currencySymbol',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: CircularProgressIndicator(
                        value: overallPercent,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                    Text(
                      '$percentText%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildEmptyState(dynamic l10n, String currency) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSavingGoals,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noSavingGoalsDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.addSavingGoal),
              onPressed: () => _openAddModal(l10n, currency),
            ),
          ],
        ),
      ),
    );
  }
}
