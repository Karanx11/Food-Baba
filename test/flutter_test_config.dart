import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

/// Runs once before every test file in this folder.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Sembast pauses long operations with a short timer, based on a real-time
  // stopwatch. Inside widget tests timers only fire when the test pumps, so a
  // database write awaited directly from a test body would wait forever.
  // Must run before any database is opened.
  disableSembastCooperator();

  // Widget tests default to a 10-minute limit, which turns a hang into a
  // stalled suite. Every test here finishes in seconds, so fail fast instead.
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is AutomatedTestWidgetsFlutterBinding) {
    binding.defaultTestTimeout = const Timeout(Duration(seconds: 60));
  }

  await testMain();
}
