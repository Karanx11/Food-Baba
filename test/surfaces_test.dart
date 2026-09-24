import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/app/theme.dart';
import 'package:food_guruji/core/widgets/surfaces.dart';
import 'package:food_guruji/features/food_search/presentation/food_search_page.dart';
import 'package:food_guruji/features/shell/home_shell.dart';

import 'helpers/test_app.dart';

void _tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('every page route paints the app background', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackground), findsOneWidget);

    await tester.tap(find.byTooltip('Food log'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-lunch')));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(
        of: find.byType(FoodSearchPage),
        matching: find.byType(AppBackground),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tabs use app cards, never plain Material cards', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(testApp(home: const HomeShell()));
    await tester.pumpAndSettle();

    for (final tab in ['Home', 'Food log', 'Progress', 'Profile']) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing, reason: tab);
    }
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(AppCard), findsWidgets);
  });

  testWidgets('the palette follows the theme brightness', (tester) async {
    Future<AppPalette> paletteUnder(ThemeData theme) async {
      AppPalette? seen;
      await tester.pumpWidget(
        Theme(
          data: theme,
          child: Builder(
            builder: (context) {
              seen = AppPalette.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return seen!;
    }

    expect(await paletteUnder(AppTheme.light()), same(AppPalette.light));
    expect(await paletteUnder(AppTheme.dark()), same(AppPalette.dark));
  });

  test('primary buttons are frosted-glass accent pills', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final style = theme.filledButtonTheme.style!;
      // The glass surface paints the fill, so the button itself is clear.
      expect(style.backgroundColor!.resolve({}), Colors.transparent);
      expect(style.backgroundBuilder, isNotNull);
      // White label reads on the accent glass in both themes.
      expect(style.foregroundColor!.resolve({}), Colors.white);
      expect(style.shape!.resolve({}), isA<StadiumBorder>());
    }
    expect(AppTheme.light().colorScheme.primary, AppColors.violet);
  });

  test("the transition wrapper keeps each platform's timing", () {
    const inners = <PageTransitionsBuilder>[
      PredictiveBackPageTransitionsBuilder(),
      CupertinoPageTransitionsBuilder(),
      ZoomPageTransitionsBuilder(),
    ];
    for (final inner in inners) {
      final wrapped = BackgroundPageTransitionsBuilder(inner);
      expect(wrapped.transitionDuration, inner.transitionDuration);
      expect(
        wrapped.reverseTransitionDuration,
        inner.reverseTransitionDuration,
      );
      // Some builders return a fresh closure per call, so compare presence.
      expect(
        wrapped.delegatedTransition == null,
        inner.delegatedTransition == null,
      );
    }
    for (final platform in TargetPlatform.values) {
      expect(
        appPageTransitionsTheme.builders[platform],
        isA<BackgroundPageTransitionsBuilder>(),
        reason: platform.name,
      );
    }
  });
}
