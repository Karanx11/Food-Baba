import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/core/dates.dart';
import 'package:food_baba/features/log/application/log_providers.dart';
import 'package:food_baba/features/log/domain/food_entry.dart';
import 'package:food_baba/features/log/domain/nutrition.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

Future<void> _pumpHome(WidgetTester tester, List<String> loggedDays) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(testApp(home: const HomeShell()));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(HomeShell)),
  );
  final repo = container.read(foodLogRepositoryProvider);
  for (final day in loggedDays) {
    await repo.upsert(
      FoodEntry(
        id: 'e-$day',
        dayKey: day,
        meal: MealType.lunch,
        name: 'Dal',
        perServing: const Nutrition(calories: 100),
        createdAt: parseDayKey(day),
      ),
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no history invites the user to start a streak', (tester) async {
    await _pumpHome(tester, const []);
    expect(find.byKey(const Key('streak-card')), findsOneWidget);
    expect(find.text('Start a streak'), findsOneWidget);
    expect(find.text('Log a meal today to begin.'), findsOneWidget);
  });

  testWidgets('a run ending today shows the streak and next badge', (
    tester,
  ) async {
    // Today is 2026-09-22 in tests; log the last three days.
    await _pumpHome(tester, const ['2026-09-20', '2026-09-21', '2026-09-22']);
    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('4 days to your 7-day badge'), findsOneWidget);
  });

  testWidgets('logged yesterday but not today warns the streak is at risk', (
    tester,
  ) async {
    await _pumpHome(tester, const ['2026-09-20', '2026-09-21']);
    expect(find.text('2-day streak at risk'), findsOneWidget);
    expect(find.text('Log today to keep it alive.'), findsOneWidget);
  });
}
