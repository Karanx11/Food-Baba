import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/profile/domain/nutrition_targets.dart';
import 'package:food_baba/features/profile/domain/user_profile.dart';

void main() {
  const base = UserProfile(
    sex: Sex.male,
    age: 30,
    heightCm: 175,
    weightKg: 70,
    activity: ActivityLevel.moderate,
    goal: Goal.maintain,
  );

  group('BMR (Mifflin-St Jeor)', () {
    test('male: 10w + 6.25h - 5a + 5', () {
      expect(TargetsCalculator.bmr(base), closeTo(1648.75, 0.001));
    });

    test('female: 10w + 6.25h - 5a - 161', () {
      expect(
        TargetsCalculator.bmr(base.copyWith(sex: Sex.female)),
        closeTo(1482.75, 0.001),
      );
    });
  });

  group('targets', () {
    test('maintain: TDEE with 1.6 g/kg protein and 25% fat', () {
      final t = TargetsCalculator.compute(base);
      expect(t.tdee, closeTo(2555.5625, 0.001));
      expect(t.calories, 2556);
      expect(t.proteinG, 112); // 1.6 * 70
      expect(t.fatG, 71); // 2556 * 0.25 / 9
      expect(t.carbsG, 367); // (2556 - 448 - 639) / 4
    });

    test('lose: 500 kcal deficit and 2.0 g/kg protein', () {
      final t = TargetsCalculator.compute(base.copyWith(goal: Goal.lose));
      expect(t.calories, 2056);
      expect(t.proteinG, 140);
    });

    test('gain: 300 kcal surplus and 1.8 g/kg protein', () {
      final t = TargetsCalculator.compute(base.copyWith(goal: Goal.gain));
      expect(t.calories, 2856);
      expect(t.proteinG, 126);
    });

    test('activity multiplier scales TDEE', () {
      final sedentary = TargetsCalculator.compute(
        base.copyWith(activity: ActivityLevel.sedentary),
      );
      final athlete = TargetsCalculator.compute(
        base.copyWith(activity: ActivityLevel.athlete),
      );
      expect(sedentary.calories, 1979); // 1648.75 * 1.2
      expect(athlete.calories, 3133); // 1648.75 * 1.9
    });

    test('never drops below the safe calorie floor', () {
      const small = UserProfile(
        sex: Sex.female,
        age: 25,
        heightCm: 155,
        weightKg: 45,
        activity: ActivityLevel.sedentary,
        goal: Goal.lose,
      );
      // TDEE 1359 - 500 = 859, floored to 1200.
      expect(TargetsCalculator.compute(small).calories, 1200);
      expect(
        TargetsCalculator.compute(small.copyWith(sex: Sex.male)).calories,
        1500,
      );
    });

    test('carbs never go negative when protein and fat exceed calories', () {
      const heavy = UserProfile(
        sex: Sex.female,
        age: 100,
        heightCm: 100,
        weightKg: 300,
        activity: ActivityLevel.sedentary,
        goal: Goal.lose,
      );
      expect(TargetsCalculator.compute(heavy).carbsG, 0);
    });
  });

  group('UserProfile', () {
    test('JSON round trip preserves every field', () {
      final withName = base.copyWith(name: 'Asha', weightKg: 72.5);
      expect(UserProfile.fromJson(withName.toJson()), withName);
    });

    test('copyWith only changes the given fields', () {
      final changed = base.copyWith(age: 31);
      expect(changed.age, 31);
      expect(changed.weightKg, base.weightKg);
      expect(changed, isNot(base));
    });
  });
}
