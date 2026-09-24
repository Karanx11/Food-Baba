import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'app_strings.dart';

/// Persistence for the chosen language.
abstract interface class LanguageStore {
  Future<AppLanguage> load();
  Future<void> save(AppLanguage language);
}

/// Stores the choice in shared preferences (local storage on web).
class SharedPrefsLanguageStore implements LanguageStore {
  SharedPrefsLanguageStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const String key = 'settings.language.v1';

  final SharedPreferencesAsync _prefs;

  @override
  Future<AppLanguage> load() async {
    try {
      final saved = await _prefs.getString(key);
      return AppLanguage.values.asNameMap()[saved] ?? AppLanguage.english;
    } on Object {
      // Unreadable storage should never block the app from starting.
      return AppLanguage.english;
    }
  }

  @override
  Future<void> save(AppLanguage language) =>
      _prefs.setString(key, language.name);
}

/// Keeps the choice in memory only. Used in tests.
class InMemoryLanguageStore implements LanguageStore {
  InMemoryLanguageStore([this.language = AppLanguage.english]);

  AppLanguage language;

  @override
  Future<AppLanguage> load() async => language;

  @override
  Future<void> save(AppLanguage language) async => this.language = language;
}

final languageStoreProvider = Provider<LanguageStore>(
  (_) => SharedPrefsLanguageStore(),
);

/// The saved choice, read in `main` before the first frame so the app never
/// flashes the wrong language.
final initialLanguageProvider = Provider<AppLanguage>(
  (_) => AppLanguage.english,
);

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.watch(initialLanguageProvider);

  Future<void> select(AppLanguage language) async {
    state = language;
    await ref.read(languageStoreProvider).save(language);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);

/// The active string table. Watch this in widgets: `ref.watch(stringsProvider)`.
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings.of(ref.watch(languageProvider)),
);
