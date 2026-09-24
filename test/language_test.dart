import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/app/l10n/app_language.dart';
import 'package:food_guruji/app/l10n/app_strings.dart';
import 'package:food_guruji/app/l10n/language_store.dart';
import 'package:food_guruji/features/profile/presentation/profile_page.dart';

import 'helpers/test_app.dart';

void main() {
  // Bounded pumps: the loaders animate forever, so pumpAndSettle would hang.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  group('AppStrings', () {
    test('resolves the implementation for each language', () {
      expect(AppStrings.of(AppLanguage.english), isA<EnStrings>());
      expect(AppStrings.of(AppLanguage.hindi), isA<HiStrings>());
      expect(AppStrings.of(AppLanguage.hinglish), isA<HinglishStrings>());
    });

    test('each language gives a distinct tagline', () {
      final taglines = {
        for (final l in AppLanguage.values) AppStrings.of(l).tagline,
      };
      expect(taglines, hasLength(AppLanguage.values.length));
    });
  });

  testWidgets('profile starts in the chosen language', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(home: const ProfilePage(), initialLanguage: AppLanguage.hindi),
    );
    await settle(tester);

    expect(find.text('भाषा'), findsOneWidget); // Language
    expect(find.text('खाता'), findsOneWidget); // Account
  });

  testWidgets('switching to Hinglish updates text and persists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final store = InMemoryLanguageStore();
    await tester.pumpWidget(
      testApp(home: const ProfilePage(), languageStore: store),
    );
    await settle(tester);

    // Starts in English.
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    // Pick Hinglish from the selector.
    await tester.tap(find.text('Hinglish'));
    await settle(tester);

    expect(find.text('Log out karo'), findsOneWidget);
    expect(store.language, AppLanguage.hinglish);
  });
}
