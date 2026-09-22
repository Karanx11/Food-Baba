import 'package:flutter/material.dart';

/// Brand palette for Food Baba.
///
/// Mint accent and charcoal ink on a warm off-white canvas, matching the
/// line-art loader reference (grey stroke that fills to mint green).
abstract final class AppColors {
  static const Color mint = Color(0xFF2FE3A0);
  static const Color mintDark = Color(0xFF17B97D);
  static const Color ink = Color(0xFF2B2B2B);
  static const Color canvas = Color(0xFFFDF9FB);
  static const Color canvasDark = Color(0xFF121214);
  static const Color stroke = Color(0xFFE3E3E3);

  // Macro colours, shared by target cards, rings and charts.
  static const Color protein = Color(0xFF17B97D);
  static const Color carbs = Color(0xFFF5A623);
  static const Color fat = Color(0xFFFF6B6B);
}

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.light,
      primary: AppColors.mintDark,
      surface: AppColors.canvas,
    );
    return _base(scheme).copyWith(scaffoldBackgroundColor: AppColors.canvas);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.mint,
      brightness: Brightness.dark,
      primary: AppColors.mint,
      surface: AppColors.canvasDark,
    );
    return _base(
      scheme,
    ).copyWith(scaffoldBackgroundColor: AppColors.canvasDark);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }
}
