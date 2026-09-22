import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/food_search/data/food_catalog_repository.dart';
import 'package:food_baba/features/food_search/domain/food_item.dart';
import 'package:food_baba/features/log/domain/nutrition.dart';

/// Energy implied by the macros (Atwater factors, fiber counted at 2 kcal/g).
double _impliedCalories(Nutrition n) =>
    4 * n.proteinG + 4 * (n.carbsG - n.fiberG) + 2 * n.fiberG + 9 * n.fatG;

void main() {
  final foods = parseFoodCatalog(
    File(AssetFoodCatalogRepository.defaultPath).readAsStringSync(),
  );

  group('bundled catalog', () {
    test('has a useful number of foods with unique ids', () {
      expect(foods.length, greaterThanOrEqualTo(70));
      final ids = foods.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate ids');
      for (final f in foods) {
        expect(f.id, matches(RegExp(r'^[a-z0-9-]+$')), reason: f.id);
        expect(f.name.trim(), isNotEmpty, reason: f.id);
        expect(f.category.trim(), isNotEmpty, reason: f.id);
      }
    });

    test('every food has servings, ending with a 100 g option', () {
      for (final f in foods) {
        expect(f.servings, isNotEmpty, reason: f.id);
        expect(f.servings.last, ServingOption.hundredGrams, reason: f.id);
        for (final s in f.servings) {
          expect(s.grams, greaterThan(0), reason: '${f.id} ${s.label}');
        }
      }
    });

    test('nutrient values are physically plausible', () {
      final problems = <String>[];
      for (final f in foods) {
        final n = f.per100g;
        final values = [
          n.calories,
          n.proteinG,
          n.carbsG,
          n.fatG,
          n.sugarG,
          n.fiberG,
          n.sodiumMg,
        ];
        if (values.any((v) => v < 0)) problems.add('${f.id}: negative value');
        if (n.proteinG + n.carbsG + n.fatG > 100.5) {
          problems.add('${f.id}: macros exceed 100 g per 100 g');
        }
        if (n.sugarG + n.fiberG > n.carbsG + 0.5) {
          problems.add('${f.id}: sugar + fiber exceed carbs');
        }
        final implied = _impliedCalories(n);
        final tolerance = n.calories * 0.2 < 15 ? 15 : n.calories * 0.2;
        if ((implied - n.calories).abs() > tolerance) {
          problems.add(
            '${f.id}: ${n.calories} kcal listed, macros imply '
            '${implied.round()} kcal',
          );
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('is declared as an app asset and loads through the bundle', () async {
      final loaded = await AssetFoodCatalogRepository(rootBundle).loadAll();
      expect(loaded.map((f) => f.id), foods.map((f) => f.id));
    });
  });

  group('FoodItem', () {
    test('scales nutrition by grams', () {
      final rice = foods.firstWhere((f) => f.id == 'white-rice');
      final katori = rice.servings.first;
      expect(katori.description, '1 katori (150 g)');
      final n = rice.nutritionFor(katori.grams);
      expect(n.calories, closeTo(195, 0.001));
      expect(n.proteinG, closeTo(4.05, 0.001));
    });

    test('a "100 g" serving describes itself without repeating the weight', () {
      expect(ServingOption.hundredGrams.description, '100 g');
    });

    test('an explicit 100 g serving is not duplicated', () {
      final food = FoodItem.fromJson({
        'id': 'x',
        'name': 'X',
        'category': 'Test',
        'per100g': {'calories': 10},
        'servings': [
          {'label': '100 g', 'grams': 100},
        ],
      });
      expect(food.servings, [ServingOption.hundredGrams]);
    });
  });
}
