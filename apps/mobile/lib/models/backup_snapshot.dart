import 'dart:convert';

class BackupSnapshot {
  final int version;
  final String app;
  final String appVersion;
  final DateTime exportedAt;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> monthlyBudgets;
  final List<Map<String, dynamic>> categoryMonthlyBudgets;
  final List<Map<String, dynamic>> loanContacts;
  final List<Map<String, dynamic>> loanTransactions;
  final List<Map<String, dynamic>> recurringConfigs;
  final List<Map<String, dynamic>> savingGoals;
  final List<Map<String, dynamic>> savingGoalLogs;
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> walletTransfers;

  const BackupSnapshot({
    this.version = 1,
    this.app = 'simo',
    required this.appVersion,
    required this.exportedAt,
    required this.settings,
    required this.categories,
    required this.transactions,
    required this.monthlyBudgets,
    required this.categoryMonthlyBudgets,
    required this.loanContacts,
    required this.loanTransactions,
    required this.recurringConfigs,
    this.savingGoals = const [],
    this.savingGoalLogs = const [],
    this.wallets = const [],
    this.walletTransfers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'app': app,
      'app_version': appVersion,
      'exported_at': exportedAt.toIso8601String(),
      'data': {
        'settings': settings,
        'categories': categories,
        'transactions': transactions,
        'monthly_budgets': monthlyBudgets,
        'category_monthly_budgets': categoryMonthlyBudgets,
        'loan_contacts': loanContacts,
        'loan_transactions': loanTransactions,
        'recurring_configs': recurringConfigs,
        'saving_goals': savingGoals,
        'saving_goal_logs': savingGoalLogs,
        'wallets': wallets,
        'wallet_transfers': walletTransfers,
      },
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  factory BackupSnapshot.fromMap(Map<String, dynamic> map) {
    final version = map['version'] as int? ?? 1;
    final app = map['app'] as String? ?? 'simo';
    final appVersion = map['app_version'] as String? ?? '1.0.0';
    final exportedAtStr = map['exported_at'] as String?;
    final exportedAt = exportedAtStr != null
        ? DateTime.tryParse(exportedAtStr) ?? DateTime.now()
        : DateTime.now();

    final data = (map['data'] as Map<String, dynamic>?) ?? {};

    return BackupSnapshot(
      version: version,
      app: app,
      appVersion: appVersion,
      exportedAt: exportedAt,
      settings: (data['settings'] as Map<String, dynamic>?) ?? {},
      categories: (data['categories'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      transactions: (data['transactions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      monthlyBudgets: (data['monthly_budgets'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      categoryMonthlyBudgets: (data['category_monthly_budgets'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      loanContacts: (data['loan_contacts'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      loanTransactions: (data['loan_transactions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      recurringConfigs: (data['recurring_configs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      savingGoals: (data['saving_goals'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      savingGoalLogs: (data['saving_goal_logs'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      wallets: (data['wallets'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      walletTransfers: (data['wallet_transfers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }

  factory BackupSnapshot.fromJsonString(String jsonString) {
    final Map<String, dynamic> map =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupSnapshot.fromMap(map);
  }
}
