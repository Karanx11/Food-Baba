import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/insights/presentation/daily_breakdown_page.dart';
import 'package:food_baba/features/log/domain/food_entry.dart';
import 'package:food_baba/features/profile/presentation/profile_form_page.dart';

import 'helpers/fixtures.dart';

Future<void> _openBreakdown(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('today-goal-card')));
  await tester.pumpAndSettle();
  expect(find.byType(DailyBreakdownPage), findsOneWidget);
}

void main() {
  testWidgets('shows calories, macros, water and a health score', (
    tester,
  ) async {
    await pumpHome(
      tester,
      profile: asha,
      entries: [entry('Dal tadka', 180, protein: 9)],
    );
    await _openBreakdown(tester);

    expect(find.text('Daily Breakdown'), findsOneWidget);
    expect(find.text('Today · Tue, 22 Sep'), findsOneWidget);
    expect(find.text('180 / 2556'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('9 g'), findsOneWidget);
    expect(find.text('0 g'), findsNWidgets(2)); // carbs and fats

    expect(find.text('0/2000 ml'), findsOneWidget);
    await tester.tap(find.byKey(const Key('breakdown-water')));
    await tester.pumpAndSettle();
    expect(find.text('250/2000 ml'), findsOneWidget);

    // 180 of 2556 kcal scores 0, 9 of 112 g protein 0.2, no fiber 0,
    // sugar and sodium within limits 1.25 each: 2.7, rounded to 3.
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('Needs work'), findsOneWidget);
    expect(find.byKey(const ValueKey('status-Fiber-low')), findsOneWidget);
    expect(find.byKey(const ValueKey('status-Sugar-good')), findsOneWidget);
    expect(find.byKey(const ValueKey('status-Sodium-good')), findsOneWidget);
    expect(find.text('0mg'), findsOneWidget);
  });

  testWidgets('an empty day has no score yet', (tester) async {
    await pumpHome(tester, profile: asha);
    await _openBreakdown(tester);

    expect(find.text('0 / 2556'), findsOneWidget);
    expect(find.text('No data yet'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
    expect(find.byKey(const ValueKey('status-Fiber-unknown')), findsOneWidget);
  });

  testWidgets('follows the day picked on the week strip', (tester) async {
    await pumpHome(
      tester,
      profile: asha,
      entries: [
        entry('Poha', 250, meal: MealType.breakfast, day: '2026-09-21'),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('day-2026-09-21')));
    await tester.pumpAndSettle();
    await _openBreakdown(tester);

    expect(find.text('Yesterday · Mon, 21 Sep'), findsOneWidget);
    expect(find.text('250 / 2556'), findsOneWidget);
  });

  testWidgets('the menu opens the food log; the pencil edits targets', (
    tester,
  ) async {
    await pumpHome(tester, profile: asha);
    await _openBreakdown(tester);

    await tester.tap(find.byTooltip('Edit targets'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormPage), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open food log'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyBreakdownPage), findsNothing);
    expect(find.text('Food Log'), findsOneWidget);
  });
}
