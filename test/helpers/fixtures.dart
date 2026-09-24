import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/log/application/log_providers.dart';
import 'package:food_guruji/features/log/domain/food_entry.dart';
import 'package:food_guruji/features/log/domain/nutrition.dart';
import 'package:food_guruji/features/profile/data/profile_repository.dart';
import 'package:food_guruji/features/profile/domain/user_profile.dart';
import 'package:food_guruji/features/shell/home_shell.dart';

import 'test_app.dart';

/// Asha: male, 30, 175 cm, 70 kg, moderately active, maintain.
/// Targets: 2556 kcal, protein 112 g, carbs 367 g, fat 71 g.
const asha = UserProfile(
  name: 'Asha',
  sex: Sex.male,
  age: 30,
  heightCm: 175,
  weightKg: 70,
  activity: ActivityLevel.moderate,
  goal: Goal.maintain,
);

FoodEntry entry(
  String name,
  double calories, {
  MealType meal = MealType.lunch,
  String day = '2026-09-22',
  double protein = 0,
}) => FoodEntry(
  id: '$day-$name',
  dayKey: day,
  meal: meal,
  name: name,
  perServing: Nutrition(calories: calories, proteinG: protein),
  createdAt: testNow,
);

Future<void> pumpHome(
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
  final container = ProviderScope.containerOf(
    tester.element(find.byType(HomeShell)),
  );
  for (final e in entries) {
    await container.read(foodLogRepositoryProvider).upsert(e);
  }
  await tester.pumpAndSettle();
}
