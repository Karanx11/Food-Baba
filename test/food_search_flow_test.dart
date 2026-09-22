import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/food_search/presentation/food_search_page.dart';
import 'package:food_baba/features/food_search/presentation/portion_page.dart';
import 'package:food_baba/features/log/application/log_providers.dart';
import 'package:food_baba/features/log/domain/food_entry.dart';
import 'package:food_baba/features/log/domain/nutrition.dart';
import 'package:food_baba/features/log/presentation/food_entry_form_page.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

/// Tall viewport so the lazy lists build every row without scrolling.
void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _openSearchFor(WidgetTester tester, MealType meal) async {
  await tester.tap(find.byTooltip('Food log'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('add-${meal.name}')));
  await tester.pumpAndSettle();
  expect(find.byType(FoodSearchPage), findsOneWidget);
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(FoodSearchPage),
      matching: find.byType(TextField),
    ),
    query,
  );
  await tester.pump();
}

String _calories(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('portion-calories'))).data!;

void main() {
  testWidgets('search, adjust the portion and add it to lunch', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();
    await _openSearchFor(tester, MealType.lunch);

    await _search(tester, 'rice');
    expect(find.text('White rice (cooked)'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);
    expect(find.text('195 kcal per 1 katori (150 g)'), findsOneWidget);

    await tester.tap(find.text('White rice (cooked)'));
    await tester.pumpAndSettle();
    expect(find.byType(PortionPage), findsOneWidget);
    expect(_calories(tester), '195');
    expect(find.text('1 × 1 katori'), findsOneWidget);

    await tester.tap(find.byKey(const Key('portion-plus')));
    await tester.pump();
    expect(_calories(tester), '244'); // 1.25 × 150 g × 1.3 kcal/g
    expect(find.text('1.25 × 1 katori'), findsOneWidget);
    expect(find.text('187.5 g in total'), findsOneWidget);

    await tester.tap(find.text('Add to Lunch'));
    await tester.pumpAndSettle();

    // Both the portion page and search closed; the entry is on the log.
    expect(find.byType(PortionPage), findsNothing);
    expect(find.byType(FoodSearchPage), findsNothing);
    expect(find.text('White rice (cooked)'), findsOneWidget);
    expect(find.text('244 kcal'), findsNWidgets(2)); // row + lunch subtotal
    expect(find.textContaining('1.25 × 1 katori (150 g)'), findsOneWidget);
  });

  testWidgets('serving chips and the stepper recalculate live', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(
      testApp(
        home: PortionPage(
          food: testCatalog.first,
          dayKey: '2026-09-22',
          meal: MealType.lunch,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_calories(tester), '195');

    await tester.tap(find.text('1 cup (158 g)'));
    await tester.pump();
    expect(_calories(tester), '205'); // 158 g × 1.3

    await tester.tap(find.text('100 g'));
    await tester.pump();
    expect(_calories(tester), '130');

    // Step down to the minimum quarter serving; the minus button disables.
    final minus = find.byKey(const Key('portion-minus'));
    for (var i = 0; i < 3; i++) {
      await tester.tap(minus);
      await tester.pump();
    }
    expect(find.text('0.25 × 100 g'), findsOneWidget);
    expect(_calories(tester), '33'); // 25 g × 1.3 = 32.5
    expect(tester.widget<IconButton>(minus).onPressed, isNull);

    // Meal can be changed before adding.
    await tester.tap(find.text('Dinner'));
    await tester.pump();
    expect(find.text('Add to Dinner'), findsOneWidget);
  });

  testWidgets('aliases match, and no results offer a manual entry', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();
    await _openSearchFor(tester, MealType.snack);

    await _search(tester, 'kela');
    expect(find.text('Banana'), findsOneWidget);

    await _search(tester, 'xyzzy');
    expect(find.text('No matches for "xyzzy"'), findsOneWidget);
    await tester.tap(find.text('Create "xyzzy" manually'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodEntryFormPage), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'xyzzy'), findsOneWidget);
    expect(find.text('Add to Snacks'), findsOneWidget);
  });

  testWidgets('empty search shows recent foods and the catalog by category', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();

    // Seed one earlier lunch entry.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeShell)),
    );
    await container
        .read(foodLogRepositoryProvider)
        .upsert(
          FoodEntry(
            id: 'dal-1',
            dayKey: '2026-09-22',
            meal: MealType.lunch,
            name: 'Dal',
            servingLabel: '1 katori',
            perServing: const Nutrition(calories: 180, proteinG: 9),
            createdAt: testNow,
          ),
        );
    await tester.pumpAndSettle();

    await _openSearchFor(tester, MealType.dinner);
    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('180 kcal · 1 × 1 katori'), findsOneWidget);
    for (final category in ['Rice & grains', 'Breads', 'Fruits']) {
      expect(find.text(category), findsOneWidget);
    }

    // A recent food opens the form pre-filled, for the chosen meal.
    await tester.tap(find.byKey(const ValueKey('recent-dal-1')));
    await tester.pumpAndSettle();
    expect(find.byType(FoodEntryFormPage), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Dal'), findsOneWidget);
    expect(find.textContaining('180 kcal'), findsOneWidget);

    await tester.tap(find.text('Add to Dinner'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodSearchPage), findsNothing);
    expect(find.text('Dal'), findsNWidgets(2)); // lunch and dinner
    expect(find.text('360'), findsOneWidget); // day total
  });
}
