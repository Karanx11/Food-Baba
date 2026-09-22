import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Single-stroke burger outline with a mint highlight that travels along it.
///
/// Leave [progress] null for the indeterminate travelling highlight. Pass a
/// value in 0..1 to fill the stroke from the start up to that fraction.
class BurgerLoader extends StatefulWidget {
  const BurgerLoader({
    super.key,
    this.size = 120,
    this.progress,
    this.strokeColor,
    this.accentColor,
  });

  final double size;
  final double? progress;
  final Color? strokeColor;
  final Color? accentColor;

  @override
  State<BurgerLoader> createState() => _BurgerLoaderState();
}

class _BurgerLoaderState extends State<BurgerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.progress == null) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant BurgerLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.progress != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stroke =
        widget.strokeColor ??
        (isDark ? const Color(0xFF3A3A3E) : AppColors.stroke);
    final accent = widget.accentColor ?? AppColors.mint;

    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _BurgerPainter(
            t: _controller.value,
            progress: widget.progress,
            stroke: stroke,
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _BurgerPainter extends CustomPainter {
  _BurgerPainter({
    required this.t,
    required this.progress,
    required this.stroke,
    required this.accent,
  });

  final double t;
  final double? progress;
  final Color stroke;
  final Color accent;

  /// Fraction of the total stroke covered by the travelling highlight.
  static const double _segmentFraction = 0.28;

  /// One continuous contour in a 100x100 design space:
  /// top bun arc -> three zig-zag layers -> bottom bun.
  static final Path _unitPath = _buildPath();

  static Path _buildPath() {
    const deg = math.pi / 180;
    return Path()
      // Top bun: start upper-right, sweep counter-clockwise over the top.
      ..arcTo(
        Rect.fromCircle(center: const Offset(52, 46), radius: 26),
        -25 * deg,
        -155 * deg,
        true,
      )
      // Layer 1, U-turn on the right.
      ..lineTo(74, 46)
      ..arcToPoint(const Offset(74, 58), radius: const Radius.circular(6))
      // Layer 2, U-turn on the left.
      ..lineTo(30, 58)
      ..arcToPoint(
        const Offset(30, 70),
        radius: const Radius.circular(6),
        clockwise: false,
      )
      // Layer 3 flows into the bottom bun.
      ..lineTo(76, 70)
      ..lineTo(76, 78)
      ..arcToPoint(const Offset(66, 88), radius: const Radius.circular(10))
      ..lineTo(38, 88)
      ..arcToPoint(const Offset(28, 78), radius: const Radius.circular(10))
      ..lineTo(28, 76);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);

    final basePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_unitPath, basePaint);

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final metric = _unitPath.computeMetrics().first;
    final total = metric.length;

    if (progress != null) {
      final end = progress!.clamp(0.0, 1.0) * total;
      if (end > 0) canvas.drawPath(metric.extractPath(0, end), accentPaint);
    } else {
      final start = t * total;
      final end = start + total * _segmentFraction;
      if (end <= total) {
        canvas.drawPath(metric.extractPath(start, end), accentPaint);
      } else {
        // Wrap the highlight around the closing gap of the stroke.
        canvas.drawPath(metric.extractPath(start, total), accentPaint);
        canvas.drawPath(metric.extractPath(0, end - total), accentPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BurgerPainter old) =>
      old.t != t ||
      old.progress != progress ||
      old.stroke != stroke ||
      old.accent != accent;
}
