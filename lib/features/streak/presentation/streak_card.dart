import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/surfaces.dart';
import '../application/streak_providers.dart';
import '../domain/streak.dart';

/// Compact flame card on Home: current streak, a nudge when it's at risk, and
/// the milestone badges (7 / 30 / 100 days).
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final active = streak.current > 0;
    final flame = AppColors.flame;

    final (String title, String subtitle) = switch (streak) {
      Streak(current: 0) => ('Start a streak', 'Log a meal today to begin.'),
      Streak(atRisk: true, current: final c) => (
        '$c-day streak at risk',
        'Log today to keep it alive.',
      ),
      Streak(current: final c) => (
        '$c-day streak',
        streak.daysToNextMilestone == null
            ? 'Longest: ${streak.longest} days'
            : '${streak.daysToNextMilestone} days to your '
                  '${streak.nextMilestone}-day badge',
      ),
    };

    return AppCard(
      key: const Key('streak-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FlameBadge(count: streak.current, color: flame, active: active),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.bodySmall?.copyWith(
                        color: streak.atRisk ? flame : palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final milestone in kStreakMilestones)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MilestoneBadge(
                      days: milestone,
                      reached: streak.current >= milestone,
                      color: flame,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlameBadge extends StatelessWidget {
  const _FlameBadge({
    required this.count,
    required this.color,
    required this.active,
  });

  final int count;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? LinearGradient(
                colors: [color, const Color(0xFFFFB020)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: active ? null : palette.cardMuted,
      ),
      child: active
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                Text(
                  '$count',
                  style: text.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            )
          : Icon(
              Icons.local_fire_department_outlined,
              color: palette.muted,
              size: 26,
            ),
    );
  }
}

class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({
    required this.days,
    required this.reached,
    required this.color,
  });

  final int days;
  final bool reached;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: reached
            ? AppColors.soft(color, Theme.of(context).brightness)
            : palette.cardMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            reached ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            size: 18,
            color: reached ? color : palette.muted,
          ),
          const SizedBox(height: 2),
          Text(
            '${days}d',
            style: text.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: reached ? color : palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
