import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/profile/data/profile_repository.dart';
import 'package:food_guruji/features/profile/domain/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  const profile = UserProfile(
    name: 'Asha',
    sex: Sex.female,
    age: 28,
    heightCm: 162.5,
    weightKg: 58,
    activity: ActivityLevel.light,
    goal: Goal.lose,
  );

  late SharedPrefsProfileRepository repo;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repo = SharedPrefsProfileRepository();
  });

  test('load returns null when nothing has been saved', () async {
    expect(await repo.load(), isNull);
  });

  test('save then load round trips the profile', () async {
    await repo.save(profile);
    expect(await repo.load(), profile);
  });

  test('clear removes the saved profile', () async {
    await repo.save(profile);
    await repo.clear();
    expect(await repo.load(), isNull);
  });

  test('unreadable stored data is treated as no profile', () async {
    await SharedPreferencesAsync().setString(
      SharedPrefsProfileRepository.key,
      '{not json',
    );
    expect(await repo.load(), isNull);
  });
}
