import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistence for the light/dark choice.
abstract interface class ThemeModeStore {
  Future<ThemeMode> load();
  Future<void> save(ThemeMode mode);
}

/// Stores the choice in shared preferences (local storage on web).
class SharedPrefsThemeModeStore implements ThemeModeStore {
  SharedPrefsThemeModeStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String key = 'settings.themeMode';

  final SharedPreferencesAsync _prefs;

  @override
  Future<ThemeMode> load() async {
    try {
      final saved = await _prefs.getString(key);
      return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
    } on Object {
      // Unreadable storage should never block the app from starting.
      return ThemeMode.system;
    }
  }

  @override
  Future<void> save(ThemeMode mode) => _prefs.setString(key, mode.name);
}

/// Keeps the choice in memory only. Used in tests.
class InMemoryThemeModeStore implements ThemeModeStore {
  InMemoryThemeModeStore([this.mode = ThemeMode.system]);

  ThemeMode mode;

  @override
  Future<ThemeMode> load() async => mode;

  @override
  Future<void> save(ThemeMode mode) async => this.mode = mode;
}

final themeModeStoreProvider = Provider<ThemeModeStore>(
  (_) => SharedPrefsThemeModeStore(),
);

/// The saved choice, read in `main` before the first frame so the app never
/// flashes the wrong theme. Follows the device until the user picks one.
final initialThemeModeProvider = Provider<ThemeMode>((_) => ThemeMode.system);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModeStoreProvider).save(mode);
  }

  /// Switches to the opposite of what is on screen, [current].
  Future<void> toggle(Brightness current) =>
      select(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
