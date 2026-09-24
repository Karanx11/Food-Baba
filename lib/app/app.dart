import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/splash/splash_screen.dart';
import 'theme.dart';
import 'theme_mode.dart';

/// Root widget: wires the light/dark themes and the launch flow.
class FoodBabaApp extends ConsumerWidget {
  const FoodBabaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Food Guruji',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const SplashScreen(),
    );
  }
}
