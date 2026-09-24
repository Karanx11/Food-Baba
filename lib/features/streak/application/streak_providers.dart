import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../log/application/log_providers.dart';
import '../domain/streak.dart';

/// Every day that has food logged, across all history.
final allLoggedDaysProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(foodLogRepositoryProvider).watchAllLoggedDays(),
);

/// The current logging streak. Recomputes when a day is logged or the day
/// rolls over.
final streakProvider = Provider<Streak>((ref) {
  final days = ref.watch(allLoggedDaysProvider).value;
  if (days == null) return Streak.none;
  final today = dateOnly(ref.watch(clockProvider)());
  return StreakCalculator.compute(days, today);
});
