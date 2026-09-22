import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_baba/app/app.dart';
import 'package:food_baba/app/theme.dart';
import 'package:food_baba/core/db/app_database.dart';
import 'package:food_baba/features/log/application/log_providers.dart';
import 'package:food_baba/features/profile/application/profile_providers.dart';
import 'package:food_baba/features/profile/data/profile_repository.dart';
import 'package:sembast/sembast_memory.dart';

/// Fixed "now" for tests: a Tuesday at 1 pm, so the default meal is lunch.
final testNow = DateTime(2026, 9, 22, 13);

/// A fresh in-memory database config, isolated per call.
DatabaseConfig memoryDatabase() => DatabaseConfig(
  factory: newDatabaseFactoryMemory(),
  path: () async => 'test.db',
);

/// Wraps [home] (or the full app when null) in a ProviderScope backed by
/// in-memory stores and a fixed clock, so tests never touch the platform.
Widget testApp({
  Widget? home,
  ProfileRepository? repository,
  DatabaseConfig? database,
  DateTime Function()? clock,
}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(
        repository ?? InMemoryProfileRepository(),
      ),
      databaseConfigProvider.overrideWithValue(database ?? memoryDatabase()),
      clockProvider.overrideWithValue(clock ?? () => testNow),
    ],
    child: home == null
        ? const FoodBabaApp()
        : MaterialApp(theme: AppTheme.light(), home: home),
  );
}
