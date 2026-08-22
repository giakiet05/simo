import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/monthly_budget_repository.dart';
import 'package:simo/repositories/category_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('MonthlyBudgetRepository Tests', () {
    late MonthlyBudgetRepository repo;
    late CategoryRepository categoryRepo;

    setUp(() {
      repo = MonthlyBudgetRepository();
      categoryRepo = CategoryRepository();
    });

    test('sets and gets total monthly budget for distinct months independently', () async {
      await repo.setMonthlyBudget(2026, 3, 25000000.0);
      await repo.setMonthlyBudget(2026, 4, 30000000.0);

      final marchBudget = await repo.getMonthlyBudget(2026, 3);
      final aprilBudget = await repo.getMonthlyBudget(2026, 4);
      final mayBudget = await repo.getMonthlyBudget(2026, 5);

      expect(marchBudget, isNotNull);
      expect(marchBudget!.amount, 25000000.0);
      expect(aprilBudget, isNotNull);
      expect(aprilBudget!.amount, 30000000.0);
      expect(mayBudget, isNull);
    });

    test('sets, updates and gets category monthly budgets per month', () async {
      final cat = await categoryRepo.create('Ăn uống', 'expense');

      await repo.setCategoryMonthlyBudget(cat.id, 2026, 3, 7000000.0);
      await repo.setCategoryMonthlyBudget(cat.id, 2026, 4, 8000000.0);

      final marchBudgets = await repo.getCategoryMonthlyBudgets(2026, 3);
      final aprilBudgets = await repo.getCategoryMonthlyBudgets(2026, 4);

      expect(marchBudgets[cat.id]?.amount, 7000000.0);
      expect(aprilBudgets[cat.id]?.amount, 8000000.0);

      // Update march
      await repo.setCategoryMonthlyBudget(cat.id, 2026, 3, 7500000.0);
      final updatedMarch = await repo.getCategoryMonthlyBudgets(2026, 3);
      expect(updatedMarch[cat.id]?.amount, 7500000.0);
    });

    test('copyBudgetsFromMonth copies total and category limits accurately', () async {
      final cat1 = await categoryRepo.create('Ăn uống', 'expense');
      final cat2 = await categoryRepo.create('Đi lại', 'expense');

      await repo.setMonthlyBudget(2026, 5, 28000000.0);
      await repo.setCategoryMonthlyBudget(cat1.id, 2026, 5, 6000000.0);
      await repo.setCategoryMonthlyBudget(cat2.id, 2026, 5, 2000000.0);

      // Copy to month 6
      await repo.copyBudgetsFromMonth(
        fromYear: 2026,
        fromMonth: 5,
        toYear: 2026,
        toMonth: 6,
      );

      final juneTotal = await repo.getMonthlyBudget(2026, 6);
      final juneCats = await repo.getCategoryMonthlyBudgets(2026, 6);

      expect(juneTotal?.amount, 28000000.0);
      expect(juneCats[cat1.id]?.amount, 6000000.0);
      expect(juneCats[cat2.id]?.amount, 2000000.0);
    });
  });
}
