import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read the saved light/dark choice first, so the splash already uses it.
  final themeStore = SharedPrefsThemeModeStore();
  final themeMode = await themeStore.load();

  runApp(
    ProviderScope(
      overrides: [
        themeModeStoreProvider.overrideWithValue(themeStore),
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const FoodBabaApp(),
    ),
  );
}
