import '../../log/domain/nutrition.dart';
import '../../profile/domain/nutrition_targets.dart';

enum NutrientStatus { good, low, high, unknown }

/// One line of the health breakdown, e.g. "Fiber 6 g, low".
class NutrientCheck {
  const NutrientCheck({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
  });

  final String label;
  final double value;
  final String unit;
  final NutrientStatus status;
}

class HealthReport {
  const HealthReport({
    required this.score,
    required this.verdict,
    required this.checks,
  });

  /// 0..10.
  final int score;
  final String verdict;

  /// Fiber, net carbs, sugar and sodium, in that order.
  final List<NutrientCheck> checks;
}

/// Scores a day's eating out of 10 from five equally simple signals.
///
/// Each of calories, protein and fiber is worth 2.5 points; sugar and sodium
/// are worth 1.25 each. It is a nudge, not medical advice.
abstract final class HealthScore {
  /// Daily fiber goal for adults.
  static const double fiberGoalG = 25;

  /// WHO upper limit for free sugars, applied to total sugar here.
  static const double sugarLimitG = 50;

  /// WHO / FSSAI upper limit for sodium.
  static const double sodiumLimitMg = 2300;

  // Used when the user has no profile targets yet.
  static const int defaultCalories = 2000;
  static const int defaultProteinG = 50;
  static const int defaultCarbsG = 275;

  static HealthReport evaluate(Nutrition totals, NutritionTargets? targets) {
    final netCarbs = (totals.carbsG - totals.fiberG).clamp(
      0.0,
      double.infinity,
    );
    final carbLimit = targets?.carbsG ?? defaultCarbsG;
    final nothingLogged = totals.calories <= 0;

    NutrientCheck check(
      String label,
      double value,
      String unit,
      NutrientStatus status,
    ) => NutrientCheck(
      label: label,
      value: value,
      unit: unit,
      status: nothingLogged ? NutrientStatus.unknown : status,
    );

    final checks = [
      check(
        'Fiber',
        totals.fiberG,
        'g',
        totals.fiberG >= fiberGoalG ? NutrientStatus.good : NutrientStatus.low,
      ),
      check(
        'Net Carbs',
        netCarbs,
        'g',
        netCarbs <= carbLimit ? NutrientStatus.good : NutrientStatus.high,
      ),
      check(
        'Sugar',
        totals.sugarG,
        'g',
        totals.sugarG <= sugarLimitG
            ? NutrientStatus.good
            : NutrientStatus.high,
      ),
      check(
        'Sodium',
        totals.sodiumMg,
        'mg',
        totals.sodiumMg <= sodiumLimitMg
            ? NutrientStatus.good
            : NutrientStatus.high,
      ),
    ];

    if (nothingLogged) {
      return HealthReport(score: 0, verdict: 'No data yet', checks: checks);
    }

    final calorieTarget = targets?.calories ?? defaultCalories;
    final proteinTarget = targets?.proteinG ?? defaultProteinG;

    // Full marks within target, zero at 50 % over or under.
    final calorieOff = (totals.calories / calorieTarget - 1).abs();
    final calories = 2.5 * (1 - calorieOff / 0.5).clamp(0.0, 1.0);
    final protein = 2.5 * (totals.proteinG / proteinTarget).clamp(0.0, 1.0);
    final fiber = 2.5 * (totals.fiberG / fiberGoalG).clamp(0.0, 1.0);
    // Full marks up to the limit, zero at double the limit.
    double moderation(double value, double limit) =>
        1.25 * (1 - (value - limit) / limit).clamp(0.0, 1.0);
    final sugar = moderation(totals.sugarG, sugarLimitG);
    final sodium = moderation(totals.sodiumMg, sodiumLimitMg);

    final score = (calories + protein + fiber + sugar + sodium).round();
    return HealthReport(
      score: score,
      verdict: verdictFor(score),
      checks: checks,
    );
  }

  static String verdictFor(int score) {
    if (score >= 8) return 'Great';
    if (score >= 6) return 'Good';
    if (score >= 4) return 'Fair';
    return 'Needs work';
  }
}
