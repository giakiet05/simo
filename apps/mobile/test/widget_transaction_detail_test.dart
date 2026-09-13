import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/transaction.dart';
import 'package:simo/widgets/transaction/transaction_detail_bottom_sheet.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('TransactionDetailBottomSheet renders all transaction details and triggers callbacks',
      (WidgetTester tester) async {
    bool editCalled = false;
    bool deleteCalled = false;

    final testTransaction = Transaction(
      id: 'tx-test-1234567890',
      amount: 150000.0,
      type: 'expense',
      categoryId: null,
      walletId: null,
      formula: '100000 + 50000',
      note: 'Ăn trưa với đồng nghiệp',
      transactionDate: DateTime(2026, 9, 5, 12, 30),
      createdAt: DateTime(2026, 9, 5, 12, 35, 10),
      updatedAt: DateTime(2026, 9, 5, 12, 40, 20),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TransactionDetailBottomSheet.show(
                    context,
                    transaction: testTransaction,
                    onEdit: () => editCalled = true,
                    onDelete: () => deleteCalled = true,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Chi tiết giao dịch'), findsOneWidget);

    // Verify Amount formatted
    expect(find.textContaining('150,000'), findsOneWidget);

    // Verify Note
    expect(find.text('Ăn trưa với đồng nghiệp'), findsOneWidget);

    // Verify Formula
    expect(find.text('100000 + 50000'), findsOneWidget);

    // Verify Transaction ID is removed
    expect(find.text('Mã giao dịch'), findsNothing);
    expect(find.text('Transaction ID'), findsNothing);

    // Verify Actions: Edit button
    final editButton = find.byIcon(Icons.edit_outlined);
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(editCalled, isTrue);

    // Re-open sheet to test delete
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
    final deleteButton = find.byIcon(Icons.delete_outline);
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);

    // Verify select multiple button is removed from sheet
    expect(find.byIcon(Icons.checklist_rounded), findsNothing);
  });
}
