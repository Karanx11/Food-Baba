import 'package:sembast/sembast.dart';

import '../../../core/db/app_database.dart';
import '../domain/food_entry.dart';

/// Persistence boundary for food entries and water intake.
abstract interface class FoodLogRepository {
  /// Entries for one day, oldest first. Emits again whenever the day changes.
  Stream<List<FoodEntry>> watchDay(String dayKey);

  Future<void> upsert(FoodEntry entry);
  Future<void> delete(String id);

  /// Day keys between [fromKey] and [toKey] (inclusive) that have food.
  Stream<Set<String>> watchLoggedDays(String fromKey, String toKey);

  /// Every day key that has at least one food entry, for streak counting.
  Stream<Set<String>> watchAllLoggedDays();

  /// Most recently logged foods, one per distinct name.
  Stream<List<FoodEntry>> watchRecent({int limit = 8});

  Stream<int> watchWater(String dayKey);
  Future<void> setWater(String dayKey, int glasses);
}

/// Sembast-backed store. Entries are documents keyed by id; water is one
/// document per day.
class SembastFoodLogRepository implements FoodLogRepository {
  SembastFoodLogRepository(this._db);

  final AppDatabase _db;

  static final _entries = stringMapStoreFactory.store('food_entries');
  static final _water = stringMapStoreFactory.store('water');

  @override
  Stream<List<FoodEntry>> watchDay(String dayKey) async* {
    final db = await _db.database;
    final query = _entries.query(
      finder: Finder(
        filter: Filter.equals('dayKey', dayKey),
        sortOrders: [SortOrder('createdAtMs')],
      ),
    );
    yield* query.onSnapshots(db).map(_toEntries);
  }

  @override
  Future<void> upsert(FoodEntry entry) async {
    final db = await _db.database;
    await _entries.record(entry.id).put(db, entry.toJson());
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db.database;
    await _entries.record(id).delete(db);
  }

  @override
  Stream<Set<String>> watchAllLoggedDays() async* {
    final db = await _db.database;
    yield* _entries
        .query()
        .onSnapshots(db)
        .map(
          (snapshots) => {
            for (final s in snapshots) s.value['dayKey']! as String,
          },
        );
  }

  @override
  Stream<Set<String>> watchLoggedDays(String fromKey, String toKey) async* {
    final db = await _db.database;
    final query = _entries.query(
      finder: Finder(
        filter: Filter.and([
          Filter.greaterThanOrEquals('dayKey', fromKey),
          Filter.lessThanOrEquals('dayKey', toKey),
        ]),
      ),
    );
    yield* query
        .onSnapshots(db)
        .map(
          (snapshots) => {
            for (final s in snapshots) s.value['dayKey']! as String,
          },
        );
  }

  @override
  Stream<List<FoodEntry>> watchRecent({int limit = 8}) async* {
    final db = await _db.database;
    final query = _entries.query(
      finder: Finder(sortOrders: [SortOrder('createdAtMs', false)], limit: 200),
    );
    yield* query.onSnapshots(db).map((snapshots) {
      final seen = <String>{};
      final recent = <FoodEntry>[];
      for (final entry in _toEntries(snapshots)) {
        if (!seen.add(entry.name.trim().toLowerCase())) continue;
        recent.add(entry);
        if (recent.length == limit) break;
      }
      return recent;
    });
  }

  @override
  Stream<int> watchWater(String dayKey) async* {
    final db = await _db.database;
    yield* _water
        .record(dayKey)
        .onSnapshot(db)
        .map((s) => (s?.value['glasses'] as num?)?.toInt() ?? 0);
  }

  @override
  Future<void> setWater(String dayKey, int glasses) async {
    final db = await _db.database;
    await _water.record(dayKey).put(db, {'glasses': glasses.clamp(0, 99)});
  }

  static List<FoodEntry> _toEntries(
    List<RecordSnapshot<String, Map<String, Object?>>> snapshots,
  ) => [for (final s in snapshots) FoodEntry.fromJson(s.value)];
}
