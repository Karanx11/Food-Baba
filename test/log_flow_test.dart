import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/food_search/presentation/food_search_page.dart';
import 'package:food_guruji/features/log/domain/food_entry.dart';
import 'package:food_guruji/features/log/presentation/food_entry_form_page.dart';
import 'package:food_guruji/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Opens the Log tab in a tall viewport so every meal section and the water
/// card are built without scrolling (the page list is lazy).
Future<void> _openLog(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(testApp(home: const HomeShell()));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Food log'));
  await tester.pumpAndSettle();
}

Future<void> _addFood(
  WidgetTester tester, {
  required MealType meal,
  required String name,
  required String calories,
  String protein = '',
}) async {
  // Add opens food search; the custom-food option leads to the manual form.
  await tester.tap(find.byKey(Key('add-${meal.name}')));
  await tester.pumpAndSettle();
  expect(find.byType(FoodSearchPage), findsOneWidget);
  await tester.tap(find.byKey(const Key('create-custom-food')));
  await tester.pumpAndSettle();
  expect(find.byType(FoodEntryFormPage), findsOneWidget);

  await tester.enterText(_field('Food name'), name);
  await tester.enterText(_field('Calories'), calories);
  if (protein.isNotEmpty) await tester.enterText(_field('Protein'), protein);
  await tester.pump();

  await tester.tap(find.text('Add to ${meal.label}'));
  await tester.pumpAndSettle();
  expect(find.byType(FoodEntryFormPage), findsNothing);
  expect(find.byType(FoodSearchPage), findsNothing);
}

void main() {
  testWidgets('log starts empty for today with the summary at zero', (
    tester,
  ) async {
    await _openLog(tester);

    expect(find.textContaining('Today · Tue, 22 Sep'), findsOneWidget);
    expect(find.text('Nothing logged yet'), findsNWidgets(4));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('kcal eaten'), findsOneWidget);
    expect(
      find.text('Set up your profile to get daily targets.'),
      findsOneWidget,
    );
  });

  testWidgets('adding a food to lunch updates the meal and day totals', (
    tester,
  ) async {
    await _openLog(tester);
    await _addFood(
      tester,
      meal: MealType.lunch,
      name: 'Dal',
      calories: '180',
      protein: '9',
    );

    expect(find.text('Dal'), findsOneWidget);
    expect(find.text('180 kcal'), findsNWidgets(2)); // row + lunch subtotal
    expect(find.text('180'), findsOneWidget); // day total
    expect(find.text('9 g'), findsOneWidget); // protein chip
    expect(find.text('Nothing logged yet'), findsNWidgets(3));
  });

  testWidgets('editing servings scales the totals', (tester) async {
    await _openLog(tester);
    await _addFood(tester, meal: MealType.lunch, name: 'Dal', calories: '180');

    await tester.tap(find.text('Dal'));
    await tester.pumpAndSettle();
    expect(find.text('Edit food'), findsOneWidget);

    await tester.enterText(_field('Servings'), '2');
    await tester.pump();
    expect(find.textContaining('360 kcal'), findsOneWidget); // live preview

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('360 kcal'), findsNWidgets(2));
    expect(find.textContaining('2 × 1 serving'), findsOneWidget);
  });

  testWidgets('swipe to delete removes the entry and undo restores it', (
    tester,
  ) async {
    await _openLog(tester);
    await _addFood(tester, meal: MealType.lunch, name: 'Dal', calories: '180');

    await tester.drag(find.text('Dal'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Dal'), findsNothing);
    // The store confirms the delete on a later tick, then the undo bar shows.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Removed Dal'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Dal'), findsOneWidget);
  });

  testWidgets('recent foods pre-fill the form for another meal', (
    tester,
  ) async {
    await _openLog(tester);
    await _addFood(tester, meal: MealType.lunch, name: 'Dal', calories: '180');

    await tester.tap(find.byKey(const Key('add-dinner')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-custom-food')));
    await tester.pumpAndSettle();
    expect(find.text('Recent'), findsOneWidget);

    await tester.tap(find.widgetWithText(ActionChip, 'Dal'));
    await tester.pump();
    expect(_field('Dal'), findsOneWidget);
    expect(find.textContaining('180 kcal'), findsOneWidget);

    await tester.tap(find.text('Add to Dinner'));
    await tester.pumpAndSettle();
    expect(find.text('Dal'), findsNWidgets(2));
    expect(find.text('360'), findsOneWidget); // day total
  });

  testWidgets('water buttons change the glass count', (tester) async {
    await _openLog(tester);

    final plus = find.byKey(const Key('water-plus'));
    await tester.tap(plus);
    await tester.pumpAndSettle();
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(find.text('2 of 8 glasses · 500 ml'), findsOneWidget);

    await tester.tap(find.byKey(const Key('water-minus')));
    await tester.pumpAndSettle();
    expect(find.text('1 of 8 glasses · 250 ml'), findsOneWidget);
  });

  testWidgets('day navigation moves to yesterday and back to today', (
    tester,
  ) async {
    await _openLog(tester);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Yesterday · Mon, 21 Sep'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Today · Tue, 22 Sep'), findsOneWidget);
  });
}
