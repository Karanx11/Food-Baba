import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/arc_gauge.dart';
import '../../../core/widgets/surfaces.dart';
import '../../log/domain/nutrition.dart';
import '../../profile/domain/nutrition_targets.dart';

/// Calories against the daily goal, plus how much of each macro is left.
class TodayGoalCard extends StatelessWidget {
  const TodayGoalCard({
    super.key,
    required this.totals,
    required this.targets,
    required this.isToday,
    this.onTap,
  });

  final Nutrition totals;
  final NutritionTargets? targets;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final eaten = totals.calories.round();
    final target = targets?.calories;
    final remaining = target == null ? null : target - eaten;
    final over = remaining != null && remaining < 0;
    final big = text.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    );

    return AppCard(
      key: const Key('today-goal-card'),
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? "Today's Goal" : 'Daily Goal',
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$eaten', style: big),
                          if (target != null)
                            TextSpan(
                              text: ' / $target',
                              style: big?.copyWith(color: palette.muted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining == null
                          ? 'kcal eaten'
                          : over
                          ? '${-remaining} kcal over'
                          : '$remaining kcal left',
                      style: text.bodySmall?.copyWith(
                        color: over ? AppColors.danger : palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              ArcGauge(
                progress: target == null ? 0 : eaten / target,
                size: 72,
                strokeWidth: 8,
                color: over ? AppColors.danger : palette.ink,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: over ? AppColors.danger : palette.ink,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: palette.onInk,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              _MacroTile(
                name: 'Protein',
                eaten: totals.proteinG,
                target: targets?.proteinG,
                color: AppColors.protein,
                icon: Icons.egg_alt_rounded,
              ),
              const SizedBox(width: 8),
              _MacroTile(
                name: 'Carbs',
                eaten: totals.carbsG,
                target: targets?.carbsG,
                color: AppColors.carbs,
                icon: Icons.bakery_dining_rounded,
              ),
              const SizedBox(width: 8),
              _MacroTile(
                name: 'Fat',
                eaten: totals.fatG,
                target: targets?.fatG,
                color: AppColors.fat,
                icon: Icons.water_drop_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.name,
    required this.eaten,
    required this.target,
    required this.color,
    required this.icon,
  });

  final String name;
  final double eaten;
  final int? target;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final grams = eaten.round();
    final goal = target;
    final left = goal == null ? null : goal - grams;
    final value = left == null ? '${grams}g' : '${left.abs()}g';
    final label = left == null
        ? name
        : left >= 0
        ? '$name left'
        : '$name over';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
        decoration: BoxDecoration(
          color: palette.cardMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 10),
            ArcGauge(
              progress: goal == null || goal == 0 ? 0 : eaten / goal,
              size: 48,
              strokeWidth: 5,
              color: color,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.soft(color, Theme.of(context).brightness),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
