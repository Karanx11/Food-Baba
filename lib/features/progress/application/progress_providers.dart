import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log/application/log_providers.dart';
import '../data/weight_repository.dart';
import '../domain/weight_entry.dart';

final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => SembastWeightRepository(ref.watch(appDatabaseProvider)),
);

final weightHistoryProvider = StreamProvider<List<WeightEntry>>(
  (ref) => ref.watch(weightRepositoryProvider).watchAll(),
);

/// How much history the weight chart shows.
enum ChartRange {
  weekly('Weekly', 7),
  monthly('Monthly', 30);

  const ChartRange(this.label, this.days);

  final String label;
  final int days;
}

class ChartRangeNotifier extends Notifier<ChartRange> {
  @override
  ChartRange build() => ChartRange.weekly;

  void select(ChartRange range) => state = range;
}

final chartRangeProvider = NotifierProvider<ChartRangeNotifier, ChartRange>(
  ChartRangeNotifier.new,
);
