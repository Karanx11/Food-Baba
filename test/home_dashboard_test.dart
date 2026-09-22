import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/home/presentation/calorie_ring.dart';
import 'package:food_baba/features/home/presentation/home_page.dart';
import 'package:food_baba/features/log/application/log_providers.dart';
import 'package:food_baba/features/log/domain/food_entry.dart';
import 'package:food_baba/features/log/domain/nutrition.dart';
import 'package:food_baba/features/log/presentation/food_entry_form_page.dart';
import 'package:food_baba/features/profile/data/profile_repository.dart';
import 'package:food_baba/features/profile/domain/user_profile.dart';
import 'package:food_baba/features/profile/presentation/profile_form_page.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

/// Asha: male, 30, 175 cm, 70 kg, moderately active, maintain -> 2556 kcal.
const _asha = UserProfile(
  name: 'Asha',
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 70,
  activity: ActivityLevel.moderate,
  goal: Goal.maintain,
);

Future<void> _pumpHome(
  WidgetTester tester, {
  UserProfile? profile,
  List<FoodEntry> entries = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    testApp(
      home: const HomeShell(),
      repository: InMemoryProfileRepository(profile),
    ),
  );
  await tester.pumpAndSettle();

  if (entries.isNotEmpty) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    final repo = container.read(foodLogRepositoryProvider);
    for (final e in entries) {
      await repo.upsert(e);
    }
    await tester.pumpAndSettle();
  }
}

FoodEntry _lunch(String name, double calories, {double protein = 0}) =>
    FoodEntry(
      id: name,
      dayKey: '2026-09-22',
      meal: MealType.lunch,
      name: name,
      perServing: Nutrition(calories: calories, proteinG: protein),
      createdAt: testNow,
    );

void main() {
  testWidgets('without a profile: greeting, nudge, and eaten-only ring', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Good afternoon'), findsOneWidget); // 1 pm
    expect(find.text('Tue, 22 Sep'), findsOneWidget);
    expect(find.text('Set your daily targets'), findsOneWidget);
    expect(find.byType(CalorieRing), findsOneWidget);
    expect(find.text('kcal eaten'), findsOneWidget);
    expect(find.text('0 g'), findsNWidgets(3)); // macro rows, no targets
    expect(find.text('Nothing yet'), findsNWidgets(4));

    await tester.tap(find.text('Set up profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormPage), findsOneWidget);
  });

  testWidgets('with a profile and food: remaining, macros and meals', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      profile: _asha,
      entries: [_lunch('Dal tadka', 180, protein: 9)],
    );

    expect(find.text('Good afternoon, Asha'), findsOneWidget);
    expect(find.text('Set your daily targets'), findsNothing);

    // Ring centre and stats.
    expect(find.text('2376'), findsOneWidget); // 2556 - 180
    expect(find.text('kcal left'), findsOneWidget);
    expect(find.text('2556 kcal'), findsOneWidget);
    expect(find.text('2376 kcal'), findsOneWidget);

    // Macro bars against targets.
    expect(find.text('9 / 112 g'), findsOneWidget);
    expect(find.text('0 / 367 g'), findsOneWidget);
    expect(find.text('0 / 71 g'), findsOneWidget);

    // Meals card lists the lunch item with its calories.
    expect(find.text('Dal tadka'), findsOneWidget);
    expect(find.text('Nothing yet'), findsNWidgets(3));
  });

  testWidgets('going over the target flips the ring to "over"', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _asha, entries: [_lunch('Feast', 3000)]);

    expect(find.text('444'), findsOneWidget); // 3000 - 2556
    expect(find.text('kcal over'), findsOneWidget);
    expect(find.text('Over'), findsOneWidget);
    expect(find.text('444 kcal'), findsOneWidget);
  });

  testWidgets('quick actions: add to a meal, water, and see full log', (
    tester,
  ) async {
    await _pumpHome(tester, profile: _asha);

    await tester.tap(find.byKey(const Key('home-add-dinner')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodEntryFormPage), findsOneWidget);
    expect(find.text('Add to Dinner'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-water-plus')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 8 glasses · 250 ml'), findsOneWidget);

    await tester.tap(find.text('See full log'));
    await tester.pumpAndSettle();
    expect(find.text('Food Log'), findsOneWidget);
    // The same water count shows on the Log tab.
    expect(find.text('1 of 8 glasses · 250 ml'), findsOneWidget);
  });

  test('greeting follows the hour', () {
    expect(HomePage.greetingFor(7), 'Good morning');
    expect(HomePage.greetingFor(13), 'Good afternoon');
    expect(HomePage.greetingFor(20), 'Good evening');
  });
}
