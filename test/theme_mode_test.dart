import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/app/theme_mode.dart';
import 'package:food_guruji/core/widgets/surfaces.dart';
import 'package:food_guruji/features/home/presentation/home_page.dart';
import 'package:food_guruji/features/shell/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'helpers/test_app.dart';

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(HomePage))).brightness;

void main() {
  group('SharedPrefsThemeModeStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('defaults to following the device', () async {
      expect(await SharedPrefsThemeModeStore().load(), ThemeMode.system);
    });

    test('remembers the last choice', () async {
      await SharedPrefsThemeModeStore().save(ThemeMode.dark);
      expect(await SharedPrefsThemeModeStore().load(), ThemeMode.dark);
    });

    test('unknown stored values fall back to the device setting', () async {
      await SharedPreferencesAsync().setString(
        SharedPrefsThemeModeStore.key,
        'sepia',
      );
      expect(await SharedPrefsThemeModeStore().load(), ThemeMode.system);
    });
  });

  testWidgets('the Home button switches dark and light, and saves it', (
    tester,
  ) async {
    final store = InMemoryThemeModeStore();
    await tester.pumpWidget(
      testApp(home: const HomeShell(), themeStore: store),
    );
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light); // test device is light

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(store.mode, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    // Surfaces follow along.
    expect(
      AppPalette.of(tester.element(find.byType(HomePage))),
      same(AppPalette.dark),
    );

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
    expect(store.mode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
  });

  testWidgets('a saved choice applies from the first frame', (tester) async {
    await tester.pumpWidget(
      testApp(home: const HomeShell(), initialThemeMode: ThemeMode.dark),
    );
    await tester.pump();
    expect(_brightness(tester), Brightness.dark);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
  });

  testWidgets('switching works when following a dark device', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final store = InMemoryThemeModeStore();
    await tester.pumpWidget(
      testApp(home: const HomeShell(), themeStore: store),
    );
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);

    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
    expect(store.mode, ThemeMode.light);
  });
}
