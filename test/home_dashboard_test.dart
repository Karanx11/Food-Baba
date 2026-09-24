import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/core/widgets/loaders/burger_loader.dart';
import 'package:food_guruji/features/food_search/presentation/food_search_page.dart';
import 'package:food_guruji/features/insights/presentation/daily_breakdown_page.dart';
import 'package:food_guruji/features/log/domain/food_entry.dart';
import 'package:food_guruji/features/profile/data/profile_repository.dart';
import 'package:food_guruji/features/profile/presentation/profile_form_page.dart';
import 'package:food_guruji/features/shell/home_shell.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('without a profile: header, week strip, nudge and zero goal', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Welcome Back 👋'), findsOneWidget);
    expect(find.text('Stay On Track Today'), findsOneWidget);
    for (var d = 19; d <= 25; d++) {
      expect(find.byKey(ValueKey('day-2026-09-$d')), findsOneWidget);
    }
    expect(find.text('Set your daily targets'), findsOneWidget);
    expect(find.text("Today's Goal"), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('kcal eaten'), findsOneWidget);
    expect(find.text('0g'), findsNWidgets(3));
    expect(find.text("Today's Meals"), findsOneWidget);
    expect(find.text('No food yet'), findsNWidgets(4));

    await tester.tap(find.text('Set up profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormPage), findsOneWidget);
  });

  testWidgets('with a profile and food: goal, macros left and meal cards', (
    tester,
  ) async {
    await pumpHome(
      tester,
      profile: asha,
      entries: [entry('Dal tadka', 180, protein: 9)],
    );

    expect(find.text('Welcome back, Asha 👋'), findsOneWidget);
    expect(find.text('Set your daily targets'), findsNothing);
    expect(find.text('180 / 2556'), findsOneWidget);
    expect(find.text('2376 kcal left'), findsOneWidget);
    expect(find.text('103g'), findsOneWidget);
    expect(find.text('Protein left'), findsOneWidget);
    expect(find.text('367g'), findsOneWidget);
    expect(find.text('Carbs left'), findsOneWidget);
    expect(find.text('71g'), findsOneWidget);
    expect(find.text('Fat left'), findsOneWidget);
    expect(find.text('180 Kcal'), findsOneWidget);
    expect(find.text('🍛'), findsOneWidget); // dal thumbnail
    expect(find.text('No food yet'), findsNWidgets(3));
  });

  testWidgets('going over shows kcal over and macros over', (tester) async {
    await pumpHome(
      tester,
      profile: asha,
      entries: [entry('Feast', 3000, protein: 150)],
    );

    expect(find.text('3000 / 2556'), findsOneWidget);
    expect(find.text('444 kcal over'), findsOneWidget);
    expect(find.text('38g'), findsOneWidget);
    expect(find.text('Protein over'), findsOneWidget);
  });

  testWidgets('week strip marks days and selects past days only', (
    tester,
  ) async {
    await pumpHome(
      tester,
      profile: asha,
      entries: [
        entry('Poha', 250, meal: MealType.breakfast, day: '2026-09-20'),
        entry('Dal tadka', 180),
      ],
    );

    expect(find.byKey(const ValueKey('logged-2026-09-20')), findsOneWidget);
    expect(find.byKey(const ValueKey('logged-2026-09-22')), findsOneWidget);
    expect(find.byKey(const ValueKey('logged-2026-09-21')), findsNothing);
    // Past days without food get a dashed ring; today and the future don't.
    expect(find.byKey(const ValueKey('missed-2026-09-21')), findsOneWidget);
    expect(find.byKey(const ValueKey('missed-2026-09-22')), findsNothing);
    expect(find.byKey(const ValueKey('missed-2026-09-23')), findsNothing);

    // Future days can't be selected.
    await tester.tap(find.byKey(const ValueKey('day-2026-09-23')));
    await tester.pumpAndSettle();
    expect(find.text("Today's Meals"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-2026-09-20')));
    await tester.pumpAndSettle();
    expect(find.text('Meals on Sun, 20 Sep'), findsOneWidget);
    expect(find.text('Daily Goal'), findsOneWidget);
    expect(find.text('250 / 2556'), findsOneWidget);
    expect(find.text('250 Kcal'), findsOneWidget);

    // The log follows the same selected day.
    await tester.tap(find.byTooltip('Food log'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sun, 20 Sep'), findsOneWidget);
  });

  testWidgets('quick actions open search, log, breakdown and profile', (
    tester,
  ) async {
    await pumpHome(tester, profile: asha, entries: [entry('Dal tadka', 180)]);

    await tester.tap(find.byKey(const Key('home-add-dinner')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchPage), findsOneWidget);
    expect(find.text('Add to Dinner'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('meal-card-lunch')));
    await tester.pumpAndSettle();
    expect(find.text('Food Log'), findsOneWidget);
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('today-goal-card')));
    await tester.pumpAndSettle();
    expect(find.byType(DailyBreakdownPage), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your Profile'), findsOneWidget);
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Reminders'));
    await tester.pump();
    expect(find.text('Reminders arrive in a later step.'), findsOneWidget);
  });

  testWidgets('shows a loader, not zeros, until the day has loaded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(
        home: const HomeShell(),
        repository: InMemoryProfileRepository(asha),
      ),
    );
    expect(find.byType(BurgerLoader), findsOneWidget);
    expect(find.text('No food yet'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(BurgerLoader), findsNothing);
    expect(find.text('No food yet'), findsNWidgets(4));
  });
}
