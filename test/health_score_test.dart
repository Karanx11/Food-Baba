import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/insights/domain/health_score.dart';
import 'package:food_guruji/features/log/domain/nutrition.dart';
import 'package:food_guruji/features/profile/domain/nutrition_targets.dart';

/// Asha's targets: 2556 kcal, protein 112 g, carbs 367 g, fat 71 g.
const _targets = NutritionTargets(
  calories: 2556,
  proteinG: 112,
  carbsG: 367,
  fatG: 71,
  bmr: 1648.75,
  tdee: 2555.56,
);

Map<String, NutrientStatus> _statuses(HealthReport r) => {
  for (final c in r.checks) c.label: c.status,
};

void main() {
  test('nothing logged has no score and unknown statuses', () {
    final r = HealthScore.evaluate(Nutrition.zero, _targets);
    expect(r.score, 0);
    expect(r.verdict, 'No data yet');
    expect(_statuses(r).values, everyElement(NutrientStatus.unknown));
    expect(_statuses(r).keys, ['Fiber', 'Net Carbs', 'Sugar', 'Sodium']);
  });

  test('a day on target scores 10', () {
    final r = HealthScore.evaluate(
      const Nutrition(
        calories: 2556,
        proteinG: 112,
        carbsG: 300,
        fiberG: 30,
        sugarG: 40,
        sodiumMg: 2000,
      ),
      _targets,
    );
    expect(r.score, 10);
    expect(r.verdict, 'Great');
    expect(_statuses(r).values, everyElement(NutrientStatus.good));
  });

  test('each signal scores in proportion', () {
    // 75 % of calories 1.25, half the protein 1.25, half the fiber 1.25,
    // sugar and sodium 50 % over their limits 0.625 each: 5.
    final r = HealthScore.evaluate(
      const Nutrition(
        calories: 1917,
        proteinG: 56,
        carbsG: 200,
        fiberG: 12.5,
        sugarG: 75,
        sodiumMg: 3450,
      ),
      _targets,
    );
    expect(r.score, 5);
    expect(r.verdict, 'Fair');
    expect(_statuses(r), {
      'Fiber': NutrientStatus.low,
      'Net Carbs': NutrientStatus.good,
      'Sugar': NutrientStatus.high,
      'Sodium': NutrientStatus.high,
    });
  });

  test('net carbs subtract fiber and are judged against the carb target', () {
    final r = HealthScore.evaluate(
      const Nutrition(calories: 2556, carbsG: 400, fiberG: 10),
      _targets,
    );
    final netCarbs = r.checks.firstWhere((c) => c.label == 'Net Carbs');
    expect(netCarbs.value, 390);
    expect(netCarbs.status, NutrientStatus.high);
  });

  test('without targets it uses general defaults', () {
    final r = HealthScore.evaluate(
      const Nutrition(calories: 2000, proteinG: 50, fiberG: 25, carbsG: 250),
      null,
    );
    expect(r.score, 10);
  });

  test('verdict thresholds', () {
    expect(HealthScore.verdictFor(9), 'Great');
    expect(HealthScore.verdictFor(8), 'Great');
    expect(HealthScore.verdictFor(7), 'Good');
    expect(HealthScore.verdictFor(6), 'Good');
    expect(HealthScore.verdictFor(4), 'Fair');
    expect(HealthScore.verdictFor(3), 'Needs work');
  });
}
