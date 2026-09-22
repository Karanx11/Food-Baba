import 'dart:math' as math;

/// WHO adult BMI bands.
enum BmiCategory {
  underweight('Underweight', 18.5),
  healthy('Healthy', 25),
  overweight('Overweight', 30),
  obese('Obese', double.infinity);

  const BmiCategory(this.label, this.upperBound);

  final String label;

  /// BMI values below this belong to the band (the previous band excluded).
  final double upperBound;
}

abstract final class BodyMetrics {
  /// Range drawn on the BMI bar.
  static const double scaleMin = 15;
  static const double scaleMax = 35;

  static double bmi({required double weightKg, required double heightCm}) =>
      weightKg / math.pow(heightCm / 100, 2);

  static BmiCategory categoryOf(double bmi) =>
      BmiCategory.values.firstWhere((c) => bmi < c.upperBound);

  /// Where [bmi] sits on the bar, 0 (left) to 1 (right).
  static double scalePosition(double bmi) =>
      ((bmi - scaleMin) / (scaleMax - scaleMin)).clamp(0.0, 1.0);

  /// Share of the way from [start] to [goal] weight, 0..1. Works for losing
  /// and gaining; moving away from the goal counts as 0. Null without a goal.
  static double? goalProgress({
    required double start,
    required double current,
    required double? goal,
  }) {
    if (goal == null) return null;
    final total = start - goal;
    if (total.abs() < 0.05) return 1;
    return ((start - current) / total).clamp(0.0, 1.0);
  }

  static String progressLabel(double progress) {
    if (progress >= 1) return 'Goal reached';
    if (progress >= 0.75) return 'Great';
    if (progress >= 0.4) return 'Good';
    if (progress > 0) return 'On the way';
    return 'Just started';
  }
}
