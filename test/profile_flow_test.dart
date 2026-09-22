import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/features/profile/data/profile_repository.dart';
import 'package:food_baba/features/profile/domain/user_profile.dart';
import 'package:food_baba/features/profile/presentation/profile_form_page.dart';
import 'package:food_baba/features/profile/presentation/profile_page.dart';
import 'package:food_baba/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('set up a profile from the Profile tab and see targets', (
    tester,
  ) async {
    final repo = InMemoryProfileRepository();
    await tester.pumpWidget(testApp(home: const HomeShell(), repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Set up your profile'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileFormPage), findsOneWidget);

    await tester.enterText(_field('Age'), '30');
    await tester.enterText(_field('Height'), '175');
    await tester.enterText(_field('Weight'), '70');
    await tester.pump();

    // Live preview with the defaults: male, moderately active, maintain.
    expect(find.text('2556'), findsOneWidget);
    expect(find.text('112 g'), findsOneWidget);

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    // Back on the Profile tab, now showing the summary and targets.
    expect(find.byType(ProfileFormPage), findsNothing);
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('2556'), findsOneWidget);
    expect(find.text('Moderately active'), findsOneWidget);

    final saved = await repo.load();
    expect(saved?.age, 30);
    expect(saved?.heightCm, 175);
    expect(saved?.weightKg, 70);
    expect(saved?.goal, Goal.maintain);
  });

  testWidgets('out-of-range values block saving', (tester) async {
    final repo = InMemoryProfileRepository();
    await tester.pumpWidget(
      testApp(home: const ProfileFormPage(), repository: repo),
    );

    await tester.enterText(_field('Age'), '5');
    await tester.enterText(_field('Height'), '175');
    await tester.enterText(_field('Weight'), '70');
    await tester.pump();
    expect(find.text('2556'), findsNothing);

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Enter 13–100'), findsOneWidget);
    expect(find.byType(ProfileFormPage), findsOneWidget);
    expect(await repo.load(), isNull);
  });

  testWidgets('existing profile shows a summary and edits update targets', (
    tester,
  ) async {
    final repo = InMemoryProfileRepository(
      const UserProfile(
        name: 'Asha',
        sex: Sex.male,
        age: 30,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.moderate,
        goal: Goal.maintain,
      ),
    );
    await tester.pumpWidget(
      testApp(home: const ProfilePage(), repository: repo),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('2556'), findsOneWidget);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget); // app bar title
    expect(_field('Asha'), findsOneWidget); // pre-filled name

    await tester.enterText(_field('Weight'), '80');
    await tester.pump();
    expect(find.text('2711'), findsOneWidget); // BMR 1748.75 * 1.55

    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('2711'), findsOneWidget);
    expect((await repo.load())?.weightKg, 80);
  });
}
