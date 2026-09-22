import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Frying-pan loader: the pan hops, tosses a mint pancake that flips in the
/// air, and a soft shadow underneath shrinks as the pan lifts.
class PanLoader extends StatefulWidget {
  const PanLoader({
    super.key,
    this.size = 140,
    this.panColor,
    this.accentColor,
    this.shadowColor,
  });

  final double size;
  final Color? panColor;
  final Color? accentColor;
  final Color? shadowColor;

  @override
  State<PanLoader> createState() => _PanLoaderState();
}

class _PanLoaderState extends State<PanLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pan =
        widget.panColor ?? (isDark ? const Color(0xFFEDEDED) : AppColors.ink);
    final shadow =
        widget.shadowColor ??
        (isDark ? const Color(0xFF2A2A2E) : AppColors.stroke);
    final accent = widget.accentColor ?? AppColors.mint;

    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _PanPainter(
            t: _controller.value,
            pan: pan,
            shadow: shadow,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _PanPainter extends CustomPainter {
  _PanPainter({
    required this.t,
    required this.pan,
    required this.shadow,
    required this.accent,
  });

  final double t;
  final Color pan;
  final Color shadow;
  final Color accent;

  static const double _panLift = 9; // how high the pan hops (design units)
  static const double _tossHeight = 34; // pancake apex above the pan

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);

    // Pan hop: quick rise and fall during the first 40% of the cycle.
    final hop = t < 0.4 ? math.sin(math.pi * (t / 0.4)) : 0.0;
    final panDy = -_panLift * hop;

    // Pancake flight: launched shortly after the pan starts rising.
    const launch = 0.08;
    const land = 0.88;
    final inFlight = t >= launch && t <= land;
    final s = inFlight ? (t - launch) / (land - launch) : 0.0;
    final tossDy = inFlight ? -_tossHeight * 4 * s * (1 - s) : 0.0;
    // One full flip while airborne: the disc turns edge-on at the apex.
    final flip = inFlight ? math.cos(math.pi * s).abs() : 1.0;

    // Shadow: shrinks and fades while the pan is off the ground.
    final shadowScale = 1 - 0.3 * hop;
    final shadowPaint = Paint()
      ..color = shadow.withValues(alpha: 1 - 0.4 * hop);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(46, 78),
          width: 44 * shadowScale,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      shadowPaint,
    );

    // Pancake, drawn before the pan so it sits "inside" when resting.
    final discCenter = Offset(45, 48 + panDy + tossDy);
    final discPaint = Paint()..color = accent;
    canvas.drawOval(
      Rect.fromCenter(
        center: discCenter,
        width: 22,
        height: math.max(1.5, 7 * flip),
      ),
      discPaint,
    );

    // Pan body: shallow trapezoid with rounded bottom corners.
    canvas.translate(0, panDy);
    final panPaint = Paint()..color = pan;
    final body = Path()
      ..moveTo(22, 50)
      ..lineTo(68, 50)
      ..lineTo(64, 59)
      ..quadraticBezierTo(63, 61, 61, 61)
      ..lineTo(29, 61)
      ..quadraticBezierTo(27, 61, 26, 59)
      ..close();
    canvas.drawPath(body, panPaint);

    // Handle: slight upward tilt, rounded end.
    final handlePaint = Paint()
      ..color = pan
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(72, 52.5), const Offset(93, 50), handlePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PanPainter old) =>
      old.t != t ||
      old.pan != pan ||
      old.shadow != shadow ||
      old.accent != accent;
}
