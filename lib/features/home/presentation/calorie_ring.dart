import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress ring that eases to its new value; [child] sits inside.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.progress,
    this.size = 150,
    this.strokeWidth = 14,
    this.color,
    this.trackColor,
    this.child,
  });

  /// 0..1; values above 1 fill the ring completely.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = color ?? scheme.primary;
    final track = trackColor ?? ringColor.withValues(alpha: 0.14);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => CustomPaint(
        painter: _RingPainter(
          value: value,
          color: ringColor,
          track: track,
          strokeWidth: strokeWidth,
        ),
        child: child,
      ),
      child: SizedBox.square(dimension: size, child: Center(child: child)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawOval(inset, trackPaint);

    if (value <= 0) return;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, -math.pi / 2, 2 * math.pi * value, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}
