import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/core/widgets/loaders/pan_loader.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('five round buttons switch tabs and show the selected icon', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();

    for (final tooltip in [
      'Home',
      'Food log',
      'Snap food',
      'Progress',
      'Profile',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget, reason: tooltip);
    }
    expect(find.text('Stay On Track Today'), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Food log'));
    await tester.pumpAndSettle();
    expect(find.text('Food Log'), findsOneWidget);
    expect(find.byIcon(Icons.room_service_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Goal Progress'), findsWidgets);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your Profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Stay On Track Today'), findsOneWidget);
  });

  testWidgets('Snap opens the analyzing sheet at full width; Close hides it', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Snap food'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Analyzing your food'), findsOneWidget);

    // Fills the width Material allows (640 max on wide screens) rather than
    // shrinking to its content.
    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final sheetContent = find.ancestor(
      of: find.byType(PanLoader),
      matching: find.byType(SingleChildScrollView),
    );
    expect(tester.getSize(sheetContent).width, math.min(screenWidth, 640));

    await tester.tap(find.text('Close'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Analyzing your food'), findsNothing);
  });
}
