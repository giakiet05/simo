import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/import_inspection.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';
import 'loan_provider.dart';
import 'settings_provider.dart';
import 'recurring_provider.dart';
import 'saving_goal_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class BackupState {
  final bool isLoading;
  final String? message;
  final String? error;
  final ImportInspection? inspection;

  const BackupState({
    this.isLoading = false,
    this.message,
    this.error,
    this.inspection,
  });

  BackupState copyWith({
    bool? isLoading,
    String? message,
    String? error,
    ImportInspection? inspection,
  }) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      message: message,
      error: error,
      inspection: inspection ?? this.inspection,
    );
  }
}

class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;
  final Ref _ref;

  BackupNotifier(this._backupService, this._ref) : super(const BackupState());

  Future<File?> createBackup() async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final file = await _backupService.createBackupFile();
      state = state.copyWith(isLoading: false, message: 'Backup created successfully');
      return file;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<ImportInspection?> inspectBackup(File file) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final inspection = await _backupService.inspectBackupFile(file);
      state = state.copyWith(isLoading: false, inspection: inspection);
      return inspection;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> restoreBackup(File file, {required bool overwriteMode}) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final success = await _backupService.restoreFromBackup(file, overwriteMode: overwriteMode);
      if (success) {
        // Invalidate and reload all application state
        await _ref.read(categoryProvider.notifier).loadCategories();
        await _ref.read(transactionProvider.notifier).loadTransactions();
        await _ref.read(loanProvider.notifier).loadLoans();
        await _ref.read(settingsProvider.notifier).loadSettings();
        await _ref.read(recurringProvider.notifier).loadRecurringConfigs();
        await _ref.read(savingGoalProvider.notifier).loadGoals();
        state = state.copyWith(isLoading: false, message: 'Data restored successfully');
      }
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((ref) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupNotifier(backupService, ref);
});
