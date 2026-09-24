import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/core/widgets/loaders/burger_loader.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('splash shows the burger loader, then fades into the shell', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());

    expect(find.byType(BurgerLoader), findsOneWidget);
    expect(find.text('Food Baba'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);

    // Still on the splash before the minimum duration elapses.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomeShell), findsNothing);

    // Past the minimum duration plus the fade, the shell is in place. The gate
    // resolves the local session first, so let those providers settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(BurgerLoader), findsNothing);
  });
}
