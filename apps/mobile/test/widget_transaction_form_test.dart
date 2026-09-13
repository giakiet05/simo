import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/category.dart';
import 'package:simo/models/transaction.dart';
import 'package:simo/models/wallet.dart';
import 'package:simo/providers/category_provider.dart';
import 'package:simo/providers/transaction_provider.dart';
import 'package:simo/providers/wallet_provider.dart';
import 'package:simo/screens/transaction_form_screen.dart';
import 'package:simo/widgets/custom_num_pad.dart';
import 'package:simo/widgets/transaction/category_grid_picker.dart';
import 'package:simo/widgets/transaction/date_quick_bar.dart';
import 'package:simo/widgets/transaction/wallet_chip_selector.dart';

class _FakeCategoryNotifier extends StateNotifier<AsyncValue<List<Category>>>
    implements CategoryNotifier {
  _FakeCategoryNotifier(List<Category> categories)
      : super(AsyncValue.data(categories));

  @override
  Future<void> loadCategories() async {}

  @override
  Future<void> createCategory(String name, String type,
      {String? icon, String? color, double? budgetLimit}) async {}

  @override
  Future<void> updateCategory(String id, String name, String type,
      {String? icon, String? color, double? budgetLimit}) async {}

  @override
  Future<void> deleteCategory(String id) async {}
}

class _FakeWalletNotifier extends StateNotifier<AsyncValue<List<Wallet>>>
    implements WalletNotifier {
  _FakeWalletNotifier(List<Wallet> wallets) : super(AsyncValue.data(wallets));

  @override
  Future<void> loadWallets() async {}

  @override
  Future<void> createWallet(Wallet wallet) async {}

  @override
  Future<void> updateWallet(Wallet wallet) async {}

  @override
  Future<void> deleteWallet(String id) async {}

  @override
  Future<void> setDefaultWallet(String id) async {}

  @override
  Future<void> recalculateAllBalances() async {}

  @override
  Future<void> transferFunds({
    required String sourceWalletId,
    required String destinationWalletId,
    required double amount,
    double fee = 0.0,
    required DateTime transferDate,
    String? note,
  }) async {}
}

class _FakeTransactionNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>>
    implements TransactionNotifier {
  _FakeTransactionNotifier() : super(const AsyncValue.data([]));

  final List<Map<String, dynamic>> createdPayloads = [];
  Map<String, dynamic>? updatedPayload;

  @override
  Future<void> createTransactions(
      List<Map<String, dynamic>> transactionData) async {
    createdPayloads.addAll(transactionData);
  }

  @override
  Future<void> updateTransaction(
    String id, {
    String? categoryId,
    String? walletId,
    double? amount,
    String? formula,
    String? note,
    String? type,
    DateTime? transactionDate,
  }) async {
    updatedPayload = {
      'id': id,
      'categoryId': categoryId,
      'walletId': walletId,
      'amount': amount,
      'formula': formula,
      'note': note,
      'type': type,
      'transactionDate': transactionDate,
    };
  }

  @override
  Future<void> loadTransactions({
    String? categoryId,
    String? walletId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? keyword,
  }) async {}

  @override
  Future<void> deleteTransactions(List<String> ids) async {}

  @override
  Future<void> updateTransactionsWallet(
      List<String> ids, String walletId) async {}

  @override
  Future<void> updateTransactionsCategory(
      List<String> ids, String? categoryId) async {}

  @override
  Future<void> updateTransactionsDate(List<String> ids, DateTime date) async {}
}

void main() {
  final testCategories = [
    Category(
      id: 'cat-food',
      name: 'Ăn uống',
      type: 'expense',
      icon: 'restaurant',
      color: '#FF5722',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Category(
      id: 'cat-salary',
      name: 'Lương',
      type: 'income',
      icon: 'attach_money',
      color: '#4CAF50',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final testWallets = [
    Wallet(
      id: 'wallet-cash',
      name: 'Tiền mặt',
      type: 'cash',
      initialBalance: 2000000.0,
      color: '#10B981',
      icon: 'wallet',
      isDefault: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  group('TransactionFormScreen Widget Tests', () {
    testWidgets(
        'US1 (T005): Layout renders type toggle, amount display, category grid, and numpad',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeTx = _FakeTransactionNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryProvider.overrideWith(
                (ref) => _FakeCategoryNotifier(testCategories)),
            walletProvider.overrideWith(
                (ref) => _FakeWalletNotifier(testWallets)),
            defaultWalletProvider.overrideWithValue(testWallets.first),
            transactionProvider.overrideWith((ref) => fakeTx),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(),
          ),
        ),
      );

      await tester.pump();

      // 1. Verify AppBar title for Add mode
      expect(find.text('Thêm giao dịch'), findsOneWidget);

      // 2. Verify Segmented Type Toggle
      expect(find.text('Chi tiêu (-)'), findsOneWidget);
      expect(find.text('Thu nhập (+)'), findsOneWidget);

      // 3. Verify Amount Display initially shows '0'
      expect(find.text('0'), findsWidgets);

      // 4. Verify Sub-widgets exist (CustomNumPad is initially hidden)
      expect(find.byType(CategoryGridPicker), findsOneWidget);
      expect(find.byType(WalletChipSelector), findsOneWidget);
      expect(find.byType(DateQuickChipsBar), findsOneWidget);
      expect(find.byType(CustomNumPad), findsNothing);

      // 5. Tap Amount Display to pop up CustomNumPad modal
      await tester.tap(find.byKey(const Key('amount_display_button')));
      await tester.pumpAndSettle();

      expect(find.byType(CustomNumPad), findsOneWidget);

      // Tap calculator keypad: 5 -> 0 -> 000 => 50,000
      await tester.tap(find.widgetWithText(ElevatedButton, '5'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '0'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '000'));
      await tester.pump();

      // Tap 'Xong' button to close bottom sheet
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xong'));
      await tester.pumpAndSettle();

      // Verify amount display updated live
      expect(find.text('50,000'), findsWidgets);

      // 6. Toggle type to Income
      await tester.tap(find.text('Thu nhập (+)'));
      await tester.pump();

      // Verify income categories are displayed
      expect(find.text('Lương'), findsOneWidget);
    });

    testWidgets(
        'US2 (T010): Edit Mode pre-fills data and supports original date rollback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final originalDate = DateTime(2026, 8, 20, 10, 0);
      final fakeTx = _FakeTransactionNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryProvider.overrideWith(
                (ref) => _FakeCategoryNotifier(testCategories)),
            walletProvider.overrideWith(
                (ref) => _FakeWalletNotifier(testWallets)),
            defaultWalletProvider.overrideWithValue(testWallets.first),
            transactionProvider.overrideWith((ref) => fakeTx),
          ],
          child: MaterialApp(
            home: TransactionFormScreen(
              editTransactionId: 'tx-edit-001',
              editType: 'expense',
              editAmount: '150000',
              editFormula: '100000+50000',
              editNote: 'Ăn tối với bạn bè',
              editTransactionDate: originalDate,
            ),
          ),
        ),
      );

      await tester.pump();

      // 1. Verify AppBar title for Edit mode
      expect(find.text('Sửa giao dịch'), findsOneWidget);

      // 2. Verify Note pre-filled
      expect(find.text('Ăn tối với bạn bè'), findsOneWidget);

      // 3. Verify Formula / Amount pre-filled
      expect(find.text('100,000+50,000'), findsOneWidget);

      // 4. Verify Original Date rollback button appears
      expect(find.textContaining('Ngày gốc: 20/08'), findsOneWidget);

      // 5. Tap 'Hôm nay' quick chip to change date
      await tester.tap(find.text('Hôm nay'));
      await tester.pump();

      // 6. Tap 'Ngày gốc' button to rollback
      await tester.tap(find.textContaining('Ngày gốc: 20/08'));
      await tester.pump();

      // 7. Verify Save button in edit mode
      expect(find.text('Lưu thay đổi'), findsOneWidget);

      // 8. Tap 'Lưu thay đổi' and verify payload
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();

      expect(fakeTx.updatedPayload, isNotNull);
      expect(fakeTx.updatedPayload!['id'], equals('tx-edit-001'));
      expect(fakeTx.updatedPayload!['amount'], equals(150000.0));
      expect(fakeTx.updatedPayload!['note'], equals('Ăn tối với bạn bè'));
    });

    testWidgets(
        'US3 (T013): Continuous entry via Save & Add Another resets amount and keeps wallet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeTx = _FakeTransactionNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryProvider.overrideWith(
                (ref) => _FakeCategoryNotifier(testCategories)),
            walletProvider.overrideWith(
                (ref) => _FakeWalletNotifier(testWallets)),
            defaultWalletProvider.overrideWithValue(testWallets.first),
            transactionProvider.overrideWith((ref) => fakeTx),
          ],
          child: const MaterialApp(
            home: TransactionFormScreen(),
          ),
        ),
      );

      await tester.pump();

      // 1. Enter amount via popup keypad: tap amount display -> 7 -> 5 -> 000 -> Xong
      await tester.tap(find.byKey(const Key('amount_display_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '7'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '5'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '000'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xong'));
      await tester.pumpAndSettle();

      // 2. Enter note
      await tester.enterText(find.byType(TextField), 'Cafe sáng');
      await tester.pump();

      // 3. Tap 'Lưu & Thêm tiếp' button
      final addAnotherBtn = find.widgetWithText(OutlinedButton, 'Lưu & Thêm tiếp');
      expect(addAnotherBtn, findsOneWidget);
      await tester.tap(addAnotherBtn);
      await tester.pump();

      // Verify transaction was committed
      expect(fakeTx.createdPayloads.length, equals(1));
      expect(fakeTx.createdPayloads.first['amount'], equals(75000.0));
      expect(fakeTx.createdPayloads.first['note'], equals('Cafe sáng'));

      // 4. Verify amount was reset for the next entry
      expect(find.text('0'), findsWidgets);

      // 5. Verify note was cleared
      expect(find.text('Cafe sáng'), findsNothing);

      // 6. Verify form is still open and ready for the next entry
      expect(find.text('Thêm giao dịch'), findsOneWidget);
    });
  });
}
