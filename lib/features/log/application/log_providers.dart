import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/platform_database.dart';
import '../data/food_log_repository.dart';
import '../domain/food_entry.dart';

/// Wall clock, overridable in tests.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Local database location and backend. Tests override with an in-memory one.
final databaseConfigProvider = Provider<DatabaseConfig>(
  (_) => platformDatabaseConfig('food_guruji.db'),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(ref.watch(databaseConfigProvider));
  ref.onDispose(db.close);
  return db;
});

final foodLogRepositoryProvider = Provider<FoodLogRepository>(
  (ref) => SembastFoodLogRepository(ref.watch(appDatabaseProvider)),
);

/// The calendar day shown in the log.
class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(ref.watch(clockProvider)());

  void previous() => state = DateTime(state.year, state.month, state.day - 1);
  void next() => state = DateTime(state.year, state.month, state.day + 1);
  void select(DateTime day) => state = dateOnly(day);
  void today() => state = dateOnly(ref.read(clockProvider)());
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

final dayEntriesProvider = StreamProvider.family<List<FoodEntry>, String>(
  (ref, dayKey) => ref.watch(foodLogRepositoryProvider).watchDay(dayKey),
);

/// Days with food logged in an inclusive (from, to) day-key range.
final loggedDaysProvider = StreamProvider.family<Set<String>, (String, String)>(
  (ref, range) =>
      ref.watch(foodLogRepositoryProvider).watchLoggedDays(range.$1, range.$2),
);

final waterProvider = StreamProvider.family<int, String>(
  (ref, dayKey) => ref.watch(foodLogRepositoryProvider).watchWater(dayKey),
);

final recentFoodsProvider = StreamProvider<List<FoodEntry>>(
  (ref) => ref.watch(foodLogRepositoryProvider).watchRecent(),
);
