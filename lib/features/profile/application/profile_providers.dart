import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../log/application/log_providers.dart';
import '../../progress/application/progress_providers.dart';
import '../data/profile_repository.dart';
import '../domain/nutrition_targets.dart';
import '../domain/user_profile.dart';

/// Where the profile is stored. Tests override this with an in-memory store.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SharedPrefsProfileRepository(),
);

/// Loads the saved profile once and exposes edits.
class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => ref.watch(profileRepositoryProvider).load();

  /// Saves [profile]. A new or changed body weight is also recorded in the
  /// weight history for today.
  Future<void> save(UserProfile profile) async {
    final previous = state.value;
    await ref.read(profileRepositoryProvider).save(profile);
    state = AsyncData(profile);
    if (previous?.weightKg != profile.weightKg) {
      final today = dayKeyOf(ref.read(clockProvider)());
      await ref.read(weightRepositoryProvider).log(today, profile.weightKg);
    }
  }

  /// Records a new current weight.
  Future<void> updateWeight(double kg) async {
    final profile = state.value;
    if (profile == null) return;
    await save(profile.copyWith(weightKg: kg));
  }

  /// Sets the goal weight, measuring progress from the current weight.
  Future<void> updateGoal(double kg) async {
    final profile = state.value;
    if (profile == null) return;
    await save(
      profile.copyWith(goalWeightKg: kg, goalStartKg: profile.weightKg),
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);

/// Daily targets for the current profile, or null until one is set up.
final targetsProvider = Provider<NutritionTargets?>((ref) {
  final profile = ref.watch(profileProvider).value;
  return profile == null ? null : TargetsCalculator.compute(profile);
});
