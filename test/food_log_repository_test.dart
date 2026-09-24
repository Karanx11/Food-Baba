import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/core/db/app_database.dart';
import 'package:food_guruji/features/log/data/food_log_repository.dart';
import 'package:food_guruji/features/log/domain/food_entry.dart';
import 'package:food_guruji/features/log/domain/nutrition.dart';

import 'helpers/test_app.dart';

FoodEntry _entry(
  String id,
  String name, {
  String dayKey = '2026-09-22',
  MealType meal = MealType.lunch,
  required DateTime at,
}) => FoodEntry(
  id: id,
  dayKey: dayKey,
  meal: meal,
  name: name,
  perServing: const Nutrition(calories: 100),
  createdAt: at,
);

void main() {
  late AppDatabase db;
  late SembastFoodLogRepository repo;

  setUp(() {
    db = AppDatabase(memoryDatabase());
    repo = SembastFoodLogRepository(db);
  });

  tearDown(() => db.close());

  test('watchDay starts empty and reflects upserts and deletes', () async {
    final seen = <List<String>>[];
    final sub = repo
        .watchDay('2026-09-22')
        .listen((entries) => seen.add(entries.map((e) => e.name).toList()));

    await repo.upsert(_entry('1', 'Dal', at: DateTime(2026, 9, 22, 13)));
    await repo.upsert(_entry('2', 'Rice', at: DateTime(2026, 9, 22, 13, 1)));
    await repo.upsert(
      _entry('3', 'Toast', dayKey: '2026-09-21', at: DateTime(2026, 9, 21, 8)),
    );
    await repo.delete('1');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen.first, isEmpty);
    expect(seen.last, ['Rice']); // other day excluded, Dal deleted
    expect(seen, contains(equals(['Dal', 'Rice']))); // ordered by createdAt
  });

  test('watchAllLoggedDays returns the distinct days with any food', () async {
    await repo.upsert(
      _entry('1', 'Dal', dayKey: '2026-09-22', at: DateTime(2026, 9, 22, 13)),
    );
    await repo.upsert(
      _entry('2', 'Rice', dayKey: '2026-09-22', at: DateTime(2026, 9, 22, 14)),
    );
    await repo.upsert(
      _entry('3', 'Poha', dayKey: '2026-09-20', at: DateTime(2026, 9, 20, 8)),
    );
    expect(await repo.watchAllLoggedDays().first, {'2026-09-20', '2026-09-22'});
  });

  test('upsert with the same id replaces the entry', () async {
    final original = _entry('1', 'Dal', at: DateTime(2026, 9, 22, 13));
    await repo.upsert(original);
    await repo.upsert(original.copyWith(servings: 3));

    final entries = await repo.watchDay('2026-09-22').first;
    expect(entries, hasLength(1));
    expect(entries.single.servings, 3);
  });

  test('recent foods are newest first and distinct by name', () async {
    await repo.upsert(_entry('1', 'Dal', at: DateTime(2026, 9, 20, 13)));
    await repo.upsert(_entry('2', 'Rice', at: DateTime(2026, 9, 21, 13)));
    await repo.upsert(_entry('3', 'dal', at: DateTime(2026, 9, 22, 13)));
    await repo.upsert(_entry('4', 'Roti', at: DateTime(2026, 9, 22, 20)));

    final recent = await repo.watchRecent(limit: 2).first;
    expect(recent.map((e) => e.name), ['Roti', 'dal']);

    final all = await repo.watchRecent().first;
    expect(all.map((e) => e.name), ['Roti', 'dal', 'Rice']);
  });

  test('water defaults to zero, persists, and never goes negative', () async {
    expect(await repo.watchWater('2026-09-22').first, 0);

    await repo.setWater('2026-09-22', 3);
    expect(await repo.watchWater('2026-09-22').first, 3);
    expect(await repo.watchWater('2026-09-21').first, 0);

    await repo.setWater('2026-09-22', -2);
    expect(await repo.watchWater('2026-09-22').first, 0);
  });
}
