import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/core/db/app_database.dart';
import 'package:food_guruji/features/log/application/log_providers.dart';
import 'package:food_guruji/features/profile/application/profile_providers.dart';
import 'package:food_guruji/features/profile/data/profile_repository.dart';
import 'package:food_guruji/features/progress/application/progress_providers.dart';
import 'package:food_guruji/features/progress/data/weight_repository.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

void main() {
  group('SembastWeightRepository', () {
    late AppDatabase db;
    late SembastWeightRepository repo;

    setUp(() {
      db = AppDatabase(memoryDatabase());
      repo = SembastWeightRepository(db);
    });

    tearDown(() => db.close());

    test('returns weights oldest day first', () async {
      await repo.log('2026-09-22', 70);
      await repo.log('2026-09-01', 73);
      await repo.log('2026-09-15', 71.5);
      final all = await repo.watchAll().first;
      expect(all.map((e) => e.dayKey), [
        '2026-09-01',
        '2026-09-15',
        '2026-09-22',
      ]);
      expect(all.map((e) => e.kg), [73, 71.5, 70]);
    });

    test('a second weight on the same day replaces the first', () async {
      await repo.log('2026-09-22', 70);
      await repo.log('2026-09-22', 69.5);
      final all = await repo.watchAll().first;
      expect(all.single.kg, 69.5);
    });
  });

  group('ProfileNotifier weight tracking', () {
    late ProviderContainer container;
    late InMemoryProfileRepository profiles;

    setUp(() async {
      profiles = InMemoryProfileRepository(asha);
      container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(profiles),
          databaseConfigProvider.overrideWithValue(memoryDatabase()),
          clockProvider.overrideWithValue(() => testNow),
        ],
      );
      await container.read(profileProvider.future);
    });

    tearDown(() => container.dispose());

    Future<List<double>> history() async => [
      for (final e
          in await container.read(weightRepositoryProvider).watchAll().first)
        e.kg,
    ];

    test(
      'setting a goal records the start weight, not a new weigh-in',
      () async {
        await container.read(profileProvider.notifier).updateGoal(65);
        final p = container.read(profileProvider).value!;
        expect(p.goalWeightKg, 65);
        expect(p.goalStartKg, 70);
        expect(await history(), isEmpty);
      },
    );

    test('a new weight is saved and logged for today', () async {
      await container.read(profileProvider.notifier).updateWeight(68);
      expect(container.read(profileProvider).value!.weightKg, 68);
      expect((await profiles.load())!.weightKg, 68);
      expect(await history(), [68]);
    });

    test('saving other fields leaves the history alone', () async {
      final notifier = container.read(profileProvider.notifier);
      await notifier.save(asha.copyWith(age: 31));
      expect(await history(), isEmpty);
    });
  });
}
