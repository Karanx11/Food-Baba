import 'dart:ui';

import 'package:flutter/material.dart';

import 'surfaces.dart';

/// A frosted "glass" surface used behind buttons: a real backdrop blur, a
/// diagonal translucent gradient, a hairline top highlight and a soft glow.
///
/// [tint] non-null makes a vivid primary surface (the accent shows through);
/// null makes a neutral frosted surface for secondary buttons. Drive [pressed]
/// and [disabled] from a button's `WidgetState`s so it reacts to touch.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.tint,
    this.shape = BoxShape.rectangle,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.pressed = false,
    this.disabled = false,
    this.blur = 14,
    this.glow = true,
  });

  final Widget child;

  /// Accent colour for a primary surface; null for a neutral frosted one.
  final Color? tint;
  final BoxShape shape;
  final BorderRadius borderRadius;
  final bool pressed;
  final bool disabled;
  final double blur;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = AppPalette.of(context);
    final primary = tint != null;

    final List<Color> fill;
    final Color borderColor;
    final Color highlight;
    final List<BoxShadow> shadows;

    if (primary) {
      final base = tint!;
      final top = Color.lerp(base, Colors.white, dark ? 0.12 : 0.26)!;
      fill = [top.withValues(alpha: 0.95), base.withValues(alpha: 0.82)];
      borderColor = Colors.white.withValues(alpha: dark ? 0.24 : 0.42);
      highlight = Colors.white.withValues(alpha: dark ? 0.30 : 0.55);
      shadows = glow
          ? [
              BoxShadow(
                color: base.withValues(alpha: dark ? 0.50 : 0.38),
                blurRadius: 24,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
            ]
          : const [];
    } else {
      fill = dark
          ? [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.04),
            ]
          : [
              Colors.white.withValues(alpha: 0.78),
              Colors.white.withValues(alpha: 0.48),
            ];
      borderColor = Colors.white.withValues(alpha: dark ? 0.16 : 0.70);
      highlight = Colors.white.withValues(alpha: dark ? 0.18 : 0.85);
      shadows = glow
          ? [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : const [];
    }

    final isCircle = shape == BoxShape.circle;
    final radius = isCircle ? null : borderRadius;

    Widget frosted = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: fill,
          ),
          border: Border.all(color: borderColor, width: 1),
        ),
        // A faint top sheen sells the glass without a second element.
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [highlight, Colors.transparent],
            ),
          ),
          child: child,
        ),
      ),
    );

    frosted = isCircle
        ? ClipOval(child: frosted)
        : ClipRRect(borderRadius: borderRadius, child: frosted);

    Widget result = DecoratedBox(
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: frosted,
    );

    if (disabled) result = Opacity(opacity: 0.5, child: result);

    return AnimatedScale(
      scale: pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: result,
    );
  }
}

/// A button [ButtonStyle.backgroundBuilder] backed by [GlassSurface]. Pass the
/// accent [tint] for primary buttons, or null for neutral (secondary) ones.
Widget Function(BuildContext, Set<WidgetState>, Widget?) glassBackground(
  Color? tint,
) {
  return (context, states, child) => GlassSurface(
    tint: tint,
    pressed: states.contains(WidgetState.pressed),
    disabled: states.contains(WidgetState.disabled),
    child: child ?? const SizedBox.shrink(),
  );
}
