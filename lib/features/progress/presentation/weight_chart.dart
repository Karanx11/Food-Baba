import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/weight_entry.dart';

/// Smooth weight line with a soft purple fill over [days] days ending at
/// [end]. The latest point carries its value in a pill.
class WeightChart extends StatelessWidget {
  const WeightChart({
    super.key,
    required this.entries,
    required this.end,
    required this.days,
  });

  /// Weights inside the range, oldest first.
  final List<WeightEntry> entries;
  final DateTime end;
  final int days;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    if (entries.length < 2) {
      return Center(
        child: Text(
          entries.isEmpty
              ? 'Log your weight to see a trend.'
              : 'Log your weight on another day to see a trend.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: palette.muted),
        ),
      );
    }
    return SizedBox.expand(
      child: CustomPaint(
        painter: _WeightChartPainter(
          entries: entries,
          start: DateTime(end.year, end.month, end.day - (days - 1)),
          days: days,
          line: Theme.of(context).colorScheme.primary,
          dotFill: palette.card,
          labelStyle: (text.labelSmall ?? const TextStyle()).copyWith(
            color: palette.muted,
          ),
          pillStyle: (text.labelSmall ?? const TextStyle()).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({
    required this.entries,
    required this.start,
    required this.days,
    required this.line,
    required this.dotFill,
    required this.labelStyle,
    required this.pillStyle,
  });

  final List<WeightEntry> entries;
  final DateTime start;
  final int days;
  final Color line;
  final Color dotFill;
  final TextStyle labelStyle;
  final TextStyle pillStyle;

  static const double _left = 48;
  static const double _right = 10;
  static const double _top = 30;
  static const double _bottom = 22;

  TextPainter _label(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _left,
      _top,
      size.width - _right,
      size.height - _bottom,
    );
    final values = [for (final e in entries) e.kg];
    var lo = (values.reduce(math.min) - 1).floorToDouble();
    var hi = (values.reduce(math.max) + 1).ceilToDouble();
    if (hi - lo < 4) {
      final mid = (hi + lo) / 2;
      lo = (mid - 2).floorToDouble();
      hi = lo + 4;
    }

    double xFor(WeightEntry e) =>
        plot.left +
        plot.width * daysBetween(start, parseDayKey(e.dayKey)) / (days - 1);
    double yFor(double kg) => plot.bottom - plot.height * (kg - lo) / (hi - lo);

    // Y axis labels.
    for (var i = 0; i <= 4; i++) {
      final v = lo + (hi - lo) * i / 4;
      final tp = _label('${compactNumber(v)} kg', labelStyle);
      tp.paint(canvas, Offset(0, yFor(v) - tp.height / 2));
    }

    final points = [for (final e in entries) Offset(xFor(e), yFor(e.kg))];

    // Smooth line: horizontal-tangent cubic segments between points.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final midX = (a.dx + b.dx) / 2;
      path.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(path)
      ..lineTo(points.last.dx, plot.bottom)
      ..lineTo(points.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.35), line.withValues(alpha: 0.02)],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Dots and x labels (every point weekly, at most six otherwise).
    final every = math.max(1, (entries.length / 6).ceil());
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4.5, Paint()..color = dotFill);
      canvas.drawCircle(
        points[i],
        4.5,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      if (i % every == 0 || i == points.length - 1) {
        final day = parseDayKey(entries[i].dayKey);
        final tp = _label(
          days <= 7 ? weekdayShort(day) : '${day.day}/${day.month}',
          labelStyle,
        );
        tp.paint(canvas, Offset(points[i].dx - tp.width / 2, plot.bottom + 6));
      }
    }

    // Value pill above the latest point.
    final last = points.last;
    final pill = _label('${compactNumber(entries.last.kg)} kg', pillStyle);
    final pillRect = Rect.fromCenter(
      center: Offset(
        (last.dx).clamp(
          plot.left + pill.width / 2 + 8,
          size.width - pill.width / 2 - 8,
        ),
        math.max(pill.height / 2 + 4, last.dy - 20),
      ),
      width: pill.width + 16,
      height: pill.height + 8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(12)),
      Paint()..color = line,
    );
    pill.paint(
      canvas,
      Offset(
        pillRect.center.dx - pill.width / 2,
        pillRect.center.dy - pill.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.entries != entries ||
      old.start != start ||
      old.days != days ||
      old.line != line ||
      old.dotFill != dotFill ||
      old.labelStyle != labelStyle;
}
