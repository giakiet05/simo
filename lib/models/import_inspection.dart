class ImportInspection {
  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final int totalCategories;
  final int totalTransactions;
  final int totalMonthlyBudgets;
  final int totalCategoryBudgets;
  final int totalLoans;
  final int totalLoanTransactions;
  final int totalRecurringConfigs;
  final int totalSavingGoals;
  final int totalSavingGoalLogs;
  final int totalWallets;
  final int totalWalletTransfers;
  final bool isValid;
  final String? errorMessage;

  const ImportInspection({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.totalCategories,
    required this.totalTransactions,
    required this.totalMonthlyBudgets,
    required this.totalCategoryBudgets,
    required this.totalLoans,
    required this.totalLoanTransactions,
    required this.totalRecurringConfigs,
    this.totalSavingGoals = 0,
    this.totalSavingGoalLogs = 0,
    this.totalWallets = 0,
    this.totalWalletTransfers = 0,
    this.isValid = true,
    this.errorMessage,
  });

  factory ImportInspection.invalid(String error) {
    return ImportInspection(
      schemaVersion: 0,
      appVersion: '',
      exportedAt: DateTime.now(),
      totalCategories: 0,
      totalTransactions: 0,
      totalMonthlyBudgets: 0,
      totalCategoryBudgets: 0,
      totalLoans: 0,
      totalLoanTransactions: 0,
      totalRecurringConfigs: 0,
      totalSavingGoals: 0,
      totalSavingGoalLogs: 0,
      totalWallets: 0,
      totalWalletTransfers: 0,
      isValid: false,
      errorMessage: error,
    );
  }
}
