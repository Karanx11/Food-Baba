import 'package:flutter/material.dart';

import '../core/widgets/glass.dart';
import '../core/widgets/surfaces.dart';

/// Accent and data colours. Neutral surfaces and inks are in [AppPalette].
abstract final class AppColors {
  static const Color violet = Color(0xFF9B72F2);
  static const Color violetLight = Color(0xFFB79CFF);

  // Macros, shared by gauges, pills and charts.
  static const Color protein = Color(0xFFF4A25B);
  static const Color carbs = Color(0xFFA47DF4);
  static const Color fat = Color(0xFF4CC58A);

  static const Color flame = Color(0xFFFF7A2F);
  static const Color water = Color(0xFF8E6CF0);
  static const Color success = Color(0xFF34C77B);
  static const Color danger = Color(0xFFE5484D);

  // BMI scale.
  static const Color underweight = Color(0xFF4C8DF6);
  static const Color overweight = Color(0xFFF59E0B);
  static const Color obese = Color(0xFFDC2626);

  /// Pale fill behind a coloured value, e.g. macro pills.
  static Color soft(Color color, Brightness brightness) =>
      color.withValues(alpha: brightness == Brightness.dark ? 0.2 : 0.14);
}

abstract final class AppTheme {
  static ThemeData light() => _base(
    ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.light,
      primary: AppColors.violet,
      surface: AppPalette.light.card,
    ),
  );

  static ThemeData dark() => _base(
    ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
      primary: AppColors.violetLight,
      surface: AppPalette.dark.card,
    ),
  );

  static ThemeData _base(ColorScheme scheme) {
    final p = AppPalette.forBrightness(scheme.brightness);
    final selectedFill = AppColors.soft(scheme.primary, scheme.brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink);

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: color, width: width),
        );
    const rounded28 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    );

    return base.copyWith(
      // Pages are transparent; each route paints the app background.
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: appPageTransitionsTheme,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: p.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: p.ink,
        titleTextStyle: TextStyle(
          color: p.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      // Primary actions are frosted-glass accent pills; the background is
      // painted by GlassSurface via backgroundBuilder.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white,
          ),
          iconColor: const WidgetStatePropertyAll(Colors.white),
          overlayColor: const WidgetStatePropertyAll(Color(0x1FFFFFFF)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundBuilder: glassBackground(scheme.primary),
        ),
      ),
      // Secondary actions are neutral frosted-glass pills.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide.none),
          foregroundColor: WidgetStatePropertyAll(p.ink),
          iconColor: WidgetStatePropertyAll(p.ink),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundBuilder: glassBackground(null),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: outline(p.border),
        enabledBorder: outline(p.border),
        focusedBorder: outline(scheme.primary, 1.6),
        errorBorder: outline(scheme.error),
        focusedErrorBorder: outline(scheme.error, 1.6),
        disabledBorder: outline(p.border.withValues(alpha: 0.5)),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? selectedFill : p.card,
        ),
        side: BorderSide(color: p.border),
        shape: const StadiumBorder(),
        checkmarkColor: scheme.primary,
        labelStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w500),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? selectedFill : p.card,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: p.track,
        thumbColor: scheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: p.track,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: rounded28,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: rounded28,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        modalBackgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.onInk),
        actionTextColor: scheme.brightness == Brightness.dark
            ? AppColors.violet
            : AppColors.violetLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, space: 1),
      listTileTheme: ListTileThemeData(iconColor: p.muted),
    );
  }
}
