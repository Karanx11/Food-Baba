import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'surfaces.dart';

/// Round progress gauge. By default a 270° arc open at the bottom; pass
/// `sweepDegrees: 360` for a full ring that starts at the top. Eases to new
/// values; [child] sits in the middle.
class ArcGauge extends StatelessWidget {
  const ArcGauge({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.sweepDegrees = 270,
    this.knob = false,
    this.child,
  });

  /// 0..1; values above 1 fill the gauge.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final double sweepDegrees;

  /// Draws a round handle at the end of the filled arc.
  final bool knob;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final arc = color ?? palette.ink;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress.isNaN ? 0 : progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => CustomPaint(
        painter: _ArcPainter(
          value: value,
          color: arc,
          track: trackColor ?? palette.track,
          strokeWidth: strokeWidth,
          sweepDegrees: sweepDegrees,
          knob: knob,
          knobCenter: palette.card,
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
    required this.sweepDegrees,
    required this.knob,
    required this.knobCenter,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;
  final double sweepDegrees;
  final bool knob;
  final Color knobCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final knobRadius = strokeWidth * 0.75;
    final inset = knob ? knobRadius : strokeWidth / 2;
    final rect = (Offset.zero & size).deflate(inset);
    final sweep = sweepDegrees * math.pi / 180;
    final start = sweepDegrees >= 360
        ? -math.pi / 2
        : math.pi / 2 + (2 * math.pi - sweep) / 2;

    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, stroke(track));
    if (value > 0) {
      canvas.drawArc(rect, start, sweep * value, false, stroke(color));
    }
    if (knob) {
      final angle = start + sweep * value;
      final center =
          rect.center +
          Offset(math.cos(angle), math.sin(angle)) * (rect.width / 2);
      canvas.drawCircle(center, knobRadius, Paint()..color = color);
      canvas.drawCircle(center, knobRadius * 0.4, Paint()..color = knobCenter);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.strokeWidth != strokeWidth ||
      old.sweepDegrees != sweepDegrees ||
      old.knob != knob ||
      old.knobCenter != knobCenter;
}
