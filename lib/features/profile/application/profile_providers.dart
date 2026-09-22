import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> save(UserProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = AsyncData(profile);
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
