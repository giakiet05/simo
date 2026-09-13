import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/saving_goal.dart';
import '../providers/localization_provider.dart';
import '../providers/saving_goal_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../widgets/saving_goal_form_modal.dart';
import '../widgets/saving_goal_log_modal.dart';

class SavingGoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;

  const SavingGoalDetailScreen({
    super.key,
    required this.goalId,
  });

  @override
  ConsumerState<SavingGoalDetailScreen> createState() => _SavingGoalDetailScreenState();
}

class _SavingGoalDetailScreenState extends ConsumerState<SavingGoalDetailScreen> {
  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.teal;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.teal;
    }
  }

  IconData _getIconData(String? iconKey) {
    switch (iconKey) {
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'vacation':
        return Icons.beach_access_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'savings':
      default:
        return Icons.savings_rounded;
    }
  }

  void _openEditModal(SavingGoal goal, dynamic l10n, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SavingGoalFormModal(
        initialGoal: goal,
        currency: currency,
        l10n: l10n,
        onSave: (updatedGoal) {
          ref.read(savingGoalProvider.notifier).updateGoal(updatedGoal);
        },
      ),
    );
  }

  void _openLogModal(SavingGoal goal, String type, dynamic l10n, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SavingGoalLogModal(
        goal: goal,
        initialType: type,
        currency: currency,
        l10n: l10n,
        onSubmit: (amount, logType, logDate, note) {
          ref.read(savingGoalProvider.notifier).addLog(
                goalId: goal.id,
                amount: amount,
                type: logType,
                logDate: logDate,
                note: note,
              );
        },
      ),
    );
  }

  void _confirmDeleteGoal(SavingGoal goal, dynamic l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteSavingGoal),
        content: Text(l10n.deleteSavingGoalConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref.read(savingGoalProvider.notifier).deleteGoal(goal.id);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.delete),
          ),
        ],
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

    return goalsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $err')),
      ),
      data: (goals) {
        final goal = goals.firstWhere(
          (g) => g.id == widget.goalId,
          orElse: () => SavingGoal(name: '', targetAmount: 0),
        );

        if (goal.name.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.noData)),
          );
        }

        final color = _parseColor(goal.color);
        final iconData = _getIconData(goal.icon);
        final percent = (goal.progressPercentage * 100).toStringAsFixed(1);
        final isCompleted = goal.isCompleted;

        return Scaffold(
          appBar: AppBar(
            title: Text(goal.name),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openEditModal(goal, l10n, currency),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDeleteGoal(goal, l10n),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Main Goal Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: color, size: 36),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              goal.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (goal.note != null && goal.note!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                goal.note!,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: goal.progressPercentage,
                                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                                valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : color),
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Stats Breakdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(l10n.currentSaved, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${numberFormat.format(goal.currentAmount)} $currencySymbol',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isCompleted ? Colors.green : color),
                                    ),
                                  ],
                                ),
                                Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                                Column(
                                  children: [
                                    Text(l10n.remainingToSave, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${numberFormat.format(goal.remainingAmount)} $currencySymbol',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                                Column(
                                  children: [
                                    Text(l10n.percentUsed, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$percent%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Smart Monthly Pace Insight
                            if (!isCompleted && goal.recommendedMonthlyPace != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.insights, size: 16, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.locale == 'vi'
                                            ? 'Cần tích lũy ~${numberFormat.format(goal.recommendedMonthlyPace!)} $currencySymbol/tháng'
                                            : 'Save ~${numberFormat.format(goal.recommendedMonthlyPace!)} $currencySymbol/mo to finish on time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons (Deposit / Withdraw)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(l10n.deposit, style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _openLogModal(goal, 'deposit', l10n, currency),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[800],
                              side: BorderSide(color: Colors.orange[800]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: Text(l10n.withdraw, style: const TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: goal.currentAmount > 0 ? () => _openLogModal(goal, 'withdraw', l10n, currency) : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // History Logs Section
                    Text(
                      l10n.historyLogs,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    Consumer(
                      builder: (context, ref, child) {
                        final logsAsync = ref.watch(savingGoalLogsProvider(goal.id));
                        return logsAsync.when(
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
                          error: (e, _) => Text('Error loading history: $e'),
                          data: (logs) {
                            if (logs.isEmpty) {
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text(l10n.noHistoryLogs, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logs.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final isDeposit = log.isDeposit;

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDeposit ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isDeposit ? Colors.green : Colors.orange[800],
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      '${isDeposit ? '+' : '-'}${numberFormat.format(log.amount)} $currencySymbol',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isDeposit ? Colors.green[800] : Colors.orange[900],
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${DateFormat('dd/MM/yyyy HH:mm').format(log.logDate)}${log.note != null && log.note!.isNotEmpty ? ' • ${log.note}' : ''}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                                      onPressed: () {
                                        ref.read(savingGoalProvider.notifier).deleteLog(log.id);
                                        ref.invalidate(savingGoalLogsProvider(goal.id));
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
