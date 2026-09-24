import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/l10n/language_store.dart';
import 'app/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved light/dark and language choices first, so the splash
  // already uses them.
  final themeStore = SharedPrefsThemeModeStore();
  final languageStore = SharedPrefsLanguageStore();
  final themeMode = await themeStore.load();
  final language = await languageStore.load();

  runApp(
    ProviderScope(
      overrides: [
        themeModeStoreProvider.overrideWithValue(themeStore),
        initialThemeModeProvider.overrideWithValue(themeMode),
        languageStoreProvider.overrideWithValue(languageStore),
        initialLanguageProvider.overrideWithValue(language),
      ],
      child: const FoodBabaApp(),
    ),
  );
}
