import 'food_entry.dart';
import 'nutrition.dart';

/// Everything logged on one calendar day.
class DailyLog {
  const DailyLog({
    required this.dayKey,
    required this.entries,
    this.waterGlasses = 0,
  });

  static const int waterGoalGlasses = 8;
  static const int mlPerGlass = 250;

  final String dayKey;
  final List<FoodEntry> entries;
  final int waterGlasses;

  Nutrition get totals =>
      entries.fold(Nutrition.zero, (sum, e) => sum + e.total);

  List<FoodEntry> entriesFor(MealType meal) =>
      entries.where((e) => e.meal == meal).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Nutrition totalsFor(MealType meal) =>
      entriesFor(meal).fold(Nutrition.zero, (sum, e) => sum + e.total);
}
