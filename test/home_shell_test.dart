import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('shell shows four tabs and switches pages', (tester) async {
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();

    // All four destinations are present.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Log'), findsWidgets);
    expect(find.text('Analyze'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

    // Home is selected by default; the Insights page is offstage.
    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text('Trends and insights'), findsNothing);

    // Tapping Analyze brings its page onstage.
    await tester.tap(find.text('Analyze'));
    await tester.pumpAndSettle();
    expect(find.text('Trends and insights'), findsOneWidget);
    expect(find.text('Good afternoon'), findsNothing);
  });

  testWidgets('Snap opens the analyzing preview sheet and Close dismisses it', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Snap'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Analyzing your food'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Analyzing your food'), findsNothing);
  });
}
