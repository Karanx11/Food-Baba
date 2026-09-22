import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/core/widgets/loaders/burger_loader.dart';
import 'package:food_baba/core/widgets/loaders/pan_loader.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('BurgerLoader animates through a full cycle without errors', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const BurgerLoader()));
    expect(find.byType(BurgerLoader), findsOneWidget);
    await _pumpFrames(tester, 20); // 2s > one 1.8s cycle, exercises the wrap
    expect(tester.takeException(), isNull);
  });

  testWidgets('BurgerLoader accepts a determinate progress', (tester) async {
    await tester.pumpWidget(_host(const BurgerLoader(progress: 0.5)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_host(const BurgerLoader(progress: 1.0)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PanLoader animates through a full cycle without errors', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const PanLoader()));
    expect(find.byType(PanLoader), findsOneWidget);
    await _pumpFrames(tester, 16); // 1.6s > one 1.5s cycle
    expect(tester.takeException(), isNull);
  });
}
