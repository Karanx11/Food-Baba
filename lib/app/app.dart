import 'package:flutter/material.dart';

import '../features/splash/splash_screen.dart';
import 'theme.dart';

/// Root widget: wires theme and the launch flow.
class FoodBabaApp extends StatelessWidget {
  const FoodBabaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Baba',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
