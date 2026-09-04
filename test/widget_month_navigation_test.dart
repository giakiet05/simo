import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simo/widgets/month_year_picker_modal.dart';

void main() {
  testWidgets('MonthNavigationBar renders and handles navigation accurately',
      (WidgetTester tester) async {
    bool prevCalled = false;
    bool nextCalled = false;
    bool monthTapCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthNavigationBar(
            selectedYear: 2026,
            selectedMonth: 5,
            canGoPrevious: false,
            canGoNext: true,
            onPrevious: () => prevCalled = true,
            onNext: () => nextCalled = true,
            onMonthTap: () => monthTapCalled = true,
            l10n: const _MockL10n(),
          ),
        ),
      ),
    );

    // Verify text
    expect(find.text('5/2026'), findsOneWidget);

    // Tap disabled previous button -> should NOT trigger prevCalled
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(prevCalled, isFalse);

    // Tap enabled next button -> should trigger nextCalled
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(nextCalled, isTrue);

    // Tap month title -> should trigger monthTapCalled
    await tester.tap(find.text('5/2026'));
    await tester.pump();
    expect(monthTapCalled, isTrue);
  });
}

class _MockL10n {
  const _MockL10n();
  String get locale => 'vi';
}
