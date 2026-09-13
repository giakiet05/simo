import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/category.dart';
import 'package:simo/providers/monthly_budget_provider.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/widgets/category_form_modal.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  testWidgets('CategoryFormModal: Save button is disabled until dirty, Delete dialog shows warning', (tester) async {
    final cat = Category(
      id: 'custom_cat_1',
      name: 'Coffee & Drinks',
      type: 'expense',
      color: '#EF4444',
      icon: 'local_cafe',
      budgetLimit: 500000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CategoryFormModal.show(context, categoryToEdit: cat),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Verify category name pre-filled
    expect(find.text('Coffee & Drinks'), findsWidgets);

    // Find Save button (ElevatedButton in modal)
    final saveButtonFinder = find.descendant(
      of: find.byType(CategoryFormModal),
      matching: find.byType(ElevatedButton),
    );
    expect(saveButtonFinder, findsOneWidget);

    // Initially NOT dirty -> ElevatedButton onPressed should be null
    final ElevatedButton initialSaveButton = tester.widget(saveButtonFinder);
    expect(initialSaveButton.onPressed, isNull);

    // Now edit the name
    final nameFieldFinder = find.widgetWithText(TextFormField, 'Coffee & Drinks');
    await tester.enterText(nameFieldFinder, 'Coffee & Tea');
    await tester.pumpAndSettle();

    // Now dirty -> ElevatedButton onPressed should NOT be null
    final ElevatedButton dirtySaveButton = tester.widget(saveButtonFinder);
    expect(dirtySaveButton.onPressed, isNotNull);

    // Ensure delete button is visible (in sticky bottom bar)
    final deleteButtonFinder = find.widgetWithText(OutlinedButton, 'Xóa');
    expect(deleteButtonFinder, findsOneWidget);

    // Tap Delete button
    await tester.tap(deleteButtonFinder);
    await tester.pumpAndSettle();

    // Verify Alert Dialog shows warning about transactions
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.text('Các giao dịch thuộc danh mục này sẽ được chuyển thành "Không có danh mục".'),
      findsOneWidget,
    );
  });

  testWidgets('CategoryFormModal: helperText differentiates between past month and current/future month', (tester) async {
    final cat = Category(
      id: 'custom_cat_2',
      name: 'Dining',
      type: 'expense',
      color: '#EF4444',
      icon: 'restaurant',
      budgetLimit: 1000000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final now = DateTime.now();
    final currentKey = MonthYearKey(now.year, now.month);
    final pastKey = MonthYearKey(now.month == 1 ? now.year - 1 : now.year, now.month == 1 ? 12 : now.month - 1);

    // 1. Test Current Month
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CategoryFormModal.show(
                  context,
                  categoryToEdit: cat,
                  monthYearKey: currentKey,
                ),
                child: const Text('Open Current Month'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Current Month'));
    await tester.pumpAndSettle();

    expect(
      find.text('Áp dụng cho tháng ${currentKey.month}/${currentKey.year} và các tháng tiếp theo'),
      findsOneWidget,
    );

    // Close modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // 2. Test Past Month
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CategoryFormModal.show(
                  context,
                  categoryToEdit: cat,
                  monthYearKey: pastKey,
                ),
                child: const Text('Open Past Month'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Past Month'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chỉ áp dụng cho tháng ${pastKey.month}/${pastKey.year}'),
      findsOneWidget,
    );
  });
}
