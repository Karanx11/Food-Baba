import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/core/dates.dart';
import 'package:food_guruji/features/log/domain/daily_log.dart';
import 'package:food_guruji/features/log/domain/food_entry.dart';
import 'package:food_guruji/features/log/domain/nutrition.dart';

void main() {
  const dal = Nutrition(calories: 180, proteinG: 9, carbsG: 27, fatG: 4);

  group('Nutrition', () {
    test('adds field by field', () {
      const rice = Nutrition(calories: 200, proteinG: 4, carbsG: 45, fatG: 0.5);
      final sum = dal + rice;
      expect(sum.calories, 380);
      expect(sum.proteinG, 13);
      expect(sum.carbsG, 72);
      expect(sum.fatG, 4.5);
    });

    test('scales by servings', () {
      final scaled = dal * 1.5;
      expect(scaled.calories, 270);
      expect(scaled.proteinG, 13.5);
    });

    test('JSON round trip', () {
      const full = Nutrition(
        calories: 1,
        proteinG: 2,
        carbsG: 3,
        fatG: 4,
        sugarG: 5,
        fiberG: 6,
        sodiumMg: 7,
      );
      expect(Nutrition.fromJson(full.toJson()), full);
    });

    test('missing JSON fields default to zero', () {
      expect(
        Nutrition.fromJson({'calories': 50}),
        const Nutrition(calories: 50),
      );
    });
  });

  group('FoodEntry', () {
    final entry = FoodEntry(
      id: 'a',
      dayKey: '2026-09-22',
      meal: MealType.lunch,
      name: 'Dal',
      servingLabel: '1 cup',
      servings: 2,
      perServing: dal,
      createdAt: DateTime(2026, 9, 22, 13, 5),
    );

    test('total multiplies per-serving nutrition by servings', () {
      expect(entry.total.calories, 360);
      expect(entry.total.proteinG, 18);
    });

    test('JSON round trip preserves every field', () {
      expect(FoodEntry.fromJson(entry.toJson()), entry);
    });

    test('ids are unique and sort by time', () {
      final random = Random(1);
      final earlier = FoodEntry.newId(DateTime(2026, 1, 1), random);
      final later = FoodEntry.newId(DateTime(2026, 1, 2), random);
      expect(earlier, isNot(later));
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('meal suggestion follows the hour', () {
      expect(MealType.forHour(8), MealType.breakfast);
      expect(MealType.forHour(13), MealType.lunch);
      expect(MealType.forHour(19), MealType.dinner);
      expect(MealType.forHour(23), MealType.snack);
      expect(MealType.forHour(2), MealType.snack);
    });
  });

  group('DailyLog', () {
    final breakfast = FoodEntry(
      id: 'b',
      dayKey: '2026-09-22',
      meal: MealType.breakfast,
      name: 'Poha',
      perServing: const Nutrition(calories: 250, carbsG: 40),
      createdAt: DateTime(2026, 9, 22, 8),
    );
    final lunch = FoodEntry(
      id: 'l',
      dayKey: '2026-09-22',
      meal: MealType.lunch,
      name: 'Dal',
      perServing: dal,
      servings: 2,
      createdAt: DateTime(2026, 9, 22, 13),
    );
    final log = DailyLog(dayKey: '2026-09-22', entries: [lunch, breakfast]);

    test('totals across meals', () {
      expect(log.totals.calories, 610);
      expect(log.totals.carbsG, 94);
    });

    test('entries per meal are ordered by time', () {
      expect(log.entriesFor(MealType.lunch).map((e) => e.name), ['Dal']);
      expect(log.entriesFor(MealType.dinner), isEmpty);
      expect(log.totalsFor(MealType.breakfast).calories, 250);
    });
  });

  group('dates', () {
    test('day keys are zero padded and parse back', () {
      expect(dayKeyOf(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(parseDayKey('2026-01-05'), DateTime(2026, 1, 5));
    });

    test('friendly day names', () {
      final today = DateTime(2026, 9, 22, 13);
      expect(friendlyDay(DateTime(2026, 9, 22), today: today), 'Today');
      expect(friendlyDay(DateTime(2026, 9, 21), today: today), 'Yesterday');
      expect(friendlyDay(DateTime(2026, 9, 23), today: today), 'Tomorrow');
      expect(friendlyDay(DateTime(2026, 9, 1), today: today), 'Tue, 1 Sep');
      // Month boundary.
      expect(
        friendlyDay(DateTime(2026, 9, 30), today: DateTime(2026, 10, 1)),
        'Yesterday',
      );
    });
  });
}
