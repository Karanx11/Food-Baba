import 'package:sembast/sembast.dart';

import '../../../core/db/app_database.dart';
import '../domain/weight_entry.dart';

/// Persistence boundary for the body-weight history.
abstract interface class WeightRepository {
  /// Every recorded weight, oldest day first.
  Stream<List<WeightEntry>> watchAll();

  /// Records [kg] for [dayKey], replacing that day's earlier value.
  Future<void> log(String dayKey, double kg);

  /// Removes all recorded weights, e.g. on account deletion.
  Future<void> clear();
}

/// Sembast store with one document per day, keyed by `yyyy-MM-dd`.
class SembastWeightRepository implements WeightRepository {
  SembastWeightRepository(this._db);

  final AppDatabase _db;

  static final _weights = stringMapStoreFactory.store('weights');

  @override
  Stream<List<WeightEntry>> watchAll() async* {
    final db = await _db.database;
    final query = _weights.query(
      finder: Finder(sortOrders: [SortOrder(Field.key)]),
    );
    yield* query
        .onSnapshots(db)
        .map(
          (snapshots) => [
            for (final s in snapshots)
              WeightEntry(dayKey: s.key, kg: (s.value['kg'] as num).toDouble()),
          ],
        );
  }

  @override
  Future<void> log(String dayKey, double kg) async {
    final db = await _db.database;
    await _weights.record(dayKey).put(db, {'kg': kg});
  }

  @override
  Future<void> clear() async {
    final db = await _db.database;
    await _weights.delete(db);
  }
}
