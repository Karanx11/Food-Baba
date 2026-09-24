import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/profile/data/profile_repository.dart';
import 'package:food_guruji/features/profile/presentation/profile_form_page.dart';
import 'package:food_guruji/features/progress/application/progress_providers.dart';
import 'package:food_guruji/features/progress/presentation/weight_chart.dart';
import 'package:food_guruji/features/shell/home_shell.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

Future<(InMemoryProfileRepository, ProviderContainer)> _openProgress(
  WidgetTester tester, {
  bool withProfile = true,
  Map<String, double> weights = const {},
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repo = InMemoryProfileRepository(withProfile ? asha : null);
  await tester.pumpWidget(testApp(home: const HomeShell(), repository: repo));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(HomeShell)),
  );
  for (final MapEntry(key: day, value: kg) in weights.entries) {
    await container.read(weightRepositoryProvider).log(day, kg);
  }
  await tester.tap(find.byTooltip('Progress'));
  await tester.pumpAndSettle();
  return (repo, container);
}

Future<void> _enterWeight(WidgetTester tester, String kg) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Weight'), kg);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without a profile it asks to set one up', (tester) async {
    await _openProgress(tester, withProfile: false);

    expect(find.text('Track your weight goal'), findsOneWidget);
    await tester.tap(find.text('Set up profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormPage), findsOneWidget);
  });

  testWidgets('shows weights, BMI and an empty trend', (tester) async {
    await _openProgress(tester);

    expect(find.text('—'), findsNWidgets(2)); // no goal, no progress
    expect(find.text('Set a goal weight'), findsOneWidget);
    expect(find.text('70 kg'), findsOneWidget);
    expect(find.text('22.9'), findsOneWidget); // 70 / 1.75²
    expect(find.text('Healthy'), findsNWidgets(2)); // pill and legend
    expect(find.text('Log your weight to see a trend.'), findsOneWidget);
  });

  testWidgets('setting a goal, then a new weight, updates progress and BMI', (
    tester,
  ) async {
    final (repo, container) = await _openProgress(tester);

    await tester.tap(find.byKey(const Key('update-goal')));
    await tester.pumpAndSettle();
    expect(find.text('Goal weight'), findsNWidgets(2)); // dialog + row label
    await _enterWeight(tester, '65');
    expect(find.text('65 kg'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Just started'), findsOneWidget);

    await tester.tap(find.byKey(const Key('update-weight')));
    await tester.pumpAndSettle();
    await _enterWeight(tester, '68');
    expect(find.text('68 kg'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget); // 2 of 5 kg lost
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('22.2'), findsOneWidget);
    expect(
      find.text('Log your weight on another day to see a trend.'),
      findsOneWidget,
    );

    final saved = await repo.load();
    expect(saved?.goalWeightKg, 65);
    expect(saved?.goalStartKg, 70);
    expect(saved?.weightKg, 68);
    // Read what the page is already watching; awaiting a fresh database
    // stream from a widget test body would wait on the fake clock.
    final history = container.read(weightHistoryProvider).value!;
    expect(history.single.dayKey, '2026-09-22');
    expect(history.single.kg, 68);
  });

  testWidgets('out-of-range weights are rejected', (tester) async {
    await _openProgress(tester);

    await tester.tap(find.byKey(const Key('update-weight')));
    await tester.pumpAndSettle();
    await _enterWeight(tester, '5');
    expect(find.text('Enter 25–300'), findsOneWidget);
    expect(find.text('Current weight'), findsNWidgets(2)); // dialog still open
  });

  testWidgets('the chart shows the chosen range of history', (tester) async {
    await _openProgress(
      tester,
      weights: {
        '2026-09-01': 73,
        '2026-09-18': 71,
        '2026-09-20': 70.4,
        '2026-09-22': 70,
      },
    );

    WeightChart chart() => tester.widget<WeightChart>(find.byType(WeightChart));
    expect(chart().entries.map((e) => e.dayKey), [
      '2026-09-18',
      '2026-09-20',
      '2026-09-22',
    ]);
    expect(find.textContaining('to see a trend'), findsNothing);

    await tester.tap(find.byKey(const Key('range-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(chart().entries, hasLength(4));
    expect(chart().days, 30);
  });
}
