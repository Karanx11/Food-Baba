import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/dates.dart';
import '../../../core/widgets/surfaces.dart';

/// Seven day pills centred on today. The selected day is filled, days with
/// food get a dot, past days without food get a dashed ring, and future days
/// are disabled.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.today,
    required this.selected,
    required this.loggedDays,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime selected;

  /// Day keys that have at least one food entry.
  final Set<String> loggedDays;
  final ValueChanged<DateTime> onSelect;

  /// The days shown: three before [today], today, three after.
  static List<DateTime> windowFor(DateTime today) => [
    for (var i = -3; i <= 3; i++)
      DateTime(today.year, today.month, today.day + i),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in windowFor(today))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _DayPill(
                day: day,
                selected: day == selected,
                future: day.isAfter(today),
                logged: loggedDays.contains(dayKeyOf(day)),
                isToday: day == today,
                onTap: () => onSelect(day),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.selected,
    required this.future,
    required this.logged,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool future;
  final bool logged;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final text = Theme.of(context).textTheme;
    final key = dayKeyOf(day);
    final missed = !logged && !future && !isToday;
    final numberColor = selected
        ? Colors.white
        : future
        ? palette.muted
        : palette.ink;

    Widget number = SizedBox.square(
      dimension: 30,
      child: Center(
        child: Text(
          '${day.day}',
          style: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: numberColor,
          ),
        ),
      ),
    );
    if (selected) {
      number = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
        ),
        child: number,
      );
    } else if (missed) {
      number = CustomPaint(
        key: ValueKey('missed-$key'),
        painter: _DashedCircle(palette.muted.withValues(alpha: 0.6)),
        child: number,
      );
    } else {
      number = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.border),
        ),
        child: number,
      );
    }

    return Semantics(
      button: !future,
      selected: selected,
      label: shortDate(day),
      child: Opacity(
        opacity: future ? 0.55 : 1,
        child: Material(
          key: ValueKey('day-$key'),
          color: selected ? primary : palette.card,
          borderRadius: BorderRadius.circular(24),
          elevation: 0,
          shadowColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: future ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    weekdayShort(day),
                    style: text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : palette.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 6,
                    child: logged
                        ? Container(
                            key: ValueKey('logged-$key'),
                            width: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? Colors.white : primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  number,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  _DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashes = 14;
    const gap = 0.45; // share of each segment left empty
    final rect = (Offset.zero & size).deflate(1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const step = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * step, step * (1 - gap), false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCircle old) => old.color != color;
}
