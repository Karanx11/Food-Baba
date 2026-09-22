import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'surfaces.dart';

/// Circle that fills with water from the bottom, ringed by a progress arc.
class WaterFill extends StatelessWidget {
  const WaterFill({
    super.key,
    required this.progress,
    required this.color,
    this.size = 52,
  });

  final double progress;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => CustomPaint(
        size: Size.square(size),
        painter: _WaterPainter(value, color, palette.track),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter(this.value, this.color, this.track);

  final double value;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const ring = 4.0;
    final outer = (Offset.zero & size).deflate(ring / 2);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(outer, ringPaint..color = track);
    if (value > 0) {
      canvas.drawArc(
        outer,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        ringPaint..color = color,
      );
    }

    final inner = (Offset.zero & size).deflate(ring + 5);
    canvas.save();
    canvas.clipPath(Path()..addOval(inner));
    canvas.drawRect(inner, Paint()..color = color.withValues(alpha: 0.14));
    final level = inner.bottom - inner.height * value;
    canvas.drawRect(
      Rect.fromLTRB(inner.left, level, inner.right, inner.bottom),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterPainter old) =>
      old.value != value || old.color != color || old.track != track;
}
