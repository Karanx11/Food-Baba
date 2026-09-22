import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Neutral surfaces and inks for the soft lavender look, one set per
/// brightness. Accent and macro colours live in `AppColors`.
class AppPalette {
  const AppPalette._({
    required this.background,
    required this.glows,
    required this.card,
    required this.cardMuted,
    required this.border,
    required this.shadow,
    required this.ink,
    required this.onInk,
    required this.muted,
    required this.track,
    required this.divider,
  });

  /// Page colour under the glows.
  final Color background;

  /// Top-left, top-right and bottom glows painted over [background].
  final List<Color> glows;

  /// Cards and round buttons.
  final Color card;

  /// Tiles nested inside a card.
  final Color cardMuted;
  final Color border;
  final Color shadow;

  /// Strongest foreground: text, gauges and primary buttons.
  final Color ink;

  /// Text and icons drawn on [ink].
  final Color onInk;

  /// Secondary text and inactive icons.
  final Color muted;

  /// Unfilled part of gauges and bars.
  final Color track;
  final Color divider;

  static const AppPalette light = AppPalette._(
    background: Color(0xFFF2F1F6),
    glows: [Color(0xFFD5C3FB), Color(0xFFEADFFD), Color(0x80DCCFF9)],
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFF5F4F8),
    border: Color(0xFFEAE8F0),
    shadow: Color(0x0F1B1340),
    ink: Color(0xFF141416),
    onInk: Color(0xFFFFFFFF),
    muted: Color(0xFF8B8A95),
    track: Color(0xFFE8E7EE),
    divider: Color(0xFFEFEEF4),
  );

  static const AppPalette dark = AppPalette._(
    background: Color(0xFF0F0F14),
    glows: [Color(0xFF3A2670), Color(0xFF2A1F52), Color(0x66291D55)],
    card: Color(0xFF1B1B22),
    cardMuted: Color(0xFF24242D),
    border: Color(0xFF2B2B35),
    shadow: Color(0x40000000),
    ink: Color(0xFFF4F4F7),
    onInk: Color(0xFF141416),
    muted: Color(0xFF9D9CA8),
    track: Color(0xFF32323C),
    divider: Color(0xFF2A2A33),
  );

  static AppPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static AppPalette of(BuildContext context) =>
      forBrightness(Theme.of(context).brightness);
}

/// Grey page with a lavender glow at the top. Every page route gets one
/// through [BackgroundPageTransitionsBuilder], so pages stay opaque while
/// they transition.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _GlowPainter(palette.glows)),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Sized by width so the glow stays near the top on tall screens.
    final spots = [
      (Offset(w * 0.2, -w * 0.2), w * 1.05),
      (Offset(w * 0.95, -w * 0.05), w * 0.75),
      (Offset(w * 0.5, size.height + w * 0.25), w * 0.9),
    ];
    for (var i = 0; i < spots.length && i < colors.length; i++) {
      final (center, radius) = spots[i];
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [colors[i], colors[i].withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.colors != colors;
}

/// Rounded white card with a soft shadow. [onTap] makes the whole card
/// tappable with an ink ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = const EdgeInsets.all(4),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.color,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);
    if (onTap != null) content = InkWell(onTap: onTap, child: content);

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? palette.card,
          borderRadius: borderRadius,
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Material(type: MaterialType.transparency, child: content),
        ),
      ),
    );
  }
}

/// Wraps a platform page transition so each page carries its own
/// [AppBackground], and forwards the wrapped builder's timing.
class BackgroundPageTransitionsBuilder extends PageTransitionsBuilder {
  const BackgroundPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions<T>(
    route,
    context,
    animation,
    secondaryAnimation,
    AppBackground(child: child),
  );
}

/// Flutter's default transition per platform, each with the app background.
const appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: BackgroundPageTransitionsBuilder(
      PredictiveBackPageTransitionsBuilder(),
    ),
    TargetPlatform.iOS: BackgroundPageTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.macOS: BackgroundPageTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
    TargetPlatform.windows: BackgroundPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.linux: BackgroundPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
    TargetPlatform.fuchsia: BackgroundPageTransitionsBuilder(
      ZoomPageTransitionsBuilder(),
    ),
  },
);
