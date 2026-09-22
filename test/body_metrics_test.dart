import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/progress/domain/body_metrics.dart';

void main() {
  group('BMI', () {
    test('weight over height squared', () {
      expect(
        BodyMetrics.bmi(weightKg: 70, heightCm: 175),
        closeTo(22.857, 0.001),
      );
    });

    test('WHO bands, with lower bounds inclusive', () {
      expect(BodyMetrics.categoryOf(18.4), BmiCategory.underweight);
      expect(BodyMetrics.categoryOf(18.5), BmiCategory.healthy);
      expect(BodyMetrics.categoryOf(24.9), BmiCategory.healthy);
      expect(BodyMetrics.categoryOf(25), BmiCategory.overweight);
      expect(BodyMetrics.categoryOf(29.9), BmiCategory.overweight);
      expect(BodyMetrics.categoryOf(30), BmiCategory.obese);
    });

    test('scale position runs 15 to 35 and clamps', () {
      expect(BodyMetrics.scalePosition(15), 0);
      expect(BodyMetrics.scalePosition(25), 0.5);
      expect(BodyMetrics.scalePosition(35), 1);
      expect(BodyMetrics.scalePosition(10), 0);
      expect(BodyMetrics.scalePosition(50), 1);
    });
  });

  group('goal progress', () {
    test('works for losing and gaining', () {
      expect(BodyMetrics.goalProgress(start: 80, current: 75, goal: 70), 0.5);
      expect(BodyMetrics.goalProgress(start: 60, current: 65, goal: 70), 0.5);
    });

    test('moving away counts as zero; passing the goal as done', () {
      expect(BodyMetrics.goalProgress(start: 80, current: 82, goal: 70), 0);
      expect(BodyMetrics.goalProgress(start: 80, current: 69, goal: 70), 1);
    });

    test('no goal is null; a goal equal to the start is done', () {
      expect(
        BodyMetrics.goalProgress(start: 70, current: 70, goal: null),
        null,
      );
      expect(BodyMetrics.goalProgress(start: 70, current: 70, goal: 70), 1);
    });

    test('labels', () {
      expect(BodyMetrics.progressLabel(0), 'Just started');
      expect(BodyMetrics.progressLabel(0.2), 'On the way');
      expect(BodyMetrics.progressLabel(0.4), 'Good');
      expect(BodyMetrics.progressLabel(0.8), 'Great');
      expect(BodyMetrics.progressLabel(1), 'Goal reached');
    });
  });
}
