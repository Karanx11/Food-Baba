import 'dart:math' as math;

import 'user_profile.dart';

/// Daily calorie and macro targets derived from a [UserProfile].
class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.bmr,
    required this.tdee,
  });

  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  /// Basal metabolic rate in kcal, before activity and goal adjustments.
  final double bmr;

  /// Total daily energy expenditure in kcal (BMR x activity multiplier).
  final double tdee;

  @override
  String toString() =>
      'NutritionTargets($calories kcal, P $proteinG g, C $carbsG g, F $fatG g)';
}

/// Mifflin-St Jeor based target calculator.
abstract final class TargetsCalculator {
  /// Calorie floors so an aggressive goal never produces an unsafe target.
  static const int minCaloriesFemale = 1200;
  static const int minCaloriesMale = 1500;

  /// Share of calories that comes from fat.
  static const double fatShare = 0.25;

  /// Basal metabolic rate (Mifflin-St Jeor, 1990).
  static double bmr(UserProfile p) {
    final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  /// Total daily energy expenditure.
  static double tdee(UserProfile p) => bmr(p) * p.activity.multiplier;

  /// Protein per kg of body weight. Higher while cutting to protect muscle.
  static double proteinPerKg(Goal goal) => switch (goal) {
    Goal.lose => 2.0,
    Goal.maintain => 1.6,
    Goal.gain => 1.8,
  };

  static NutritionTargets compute(UserProfile p) {
    final basal = bmr(p);
    final expenditure = tdee(p);
    final floor = p.sex == Sex.male ? minCaloriesMale : minCaloriesFemale;
    final calories = math.max(
      floor,
      (expenditure + p.goal.calorieDelta).round(),
    );

    final protein = (proteinPerKg(p.goal) * p.weightKg).round();
    final fat = (calories * fatShare / 9).round();
    final carbs = math.max(0, ((calories - protein * 4 - fat * 9) / 4).round());

    return NutritionTargets(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      bmr: basal,
      tdee: expenditure,
    );
  }
}
