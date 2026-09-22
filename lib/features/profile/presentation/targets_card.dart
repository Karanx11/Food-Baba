import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../domain/nutrition_targets.dart';

/// Calories headline plus protein / carbs / fat tiles.
class TargetsCard extends StatelessWidget {
  const TargetsCard({
    super.key,
    required this.targets,
    this.title = 'Daily targets',
  });

  final NutritionTargets targets;
  final String title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleMedium),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${targets.calories}',
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'kcal / day',
                  style: text.bodyMedium?.copyWith(color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MacroTile(
                  label: 'Protein',
                  grams: targets.proteinG,
                  color: AppColors.protein,
                ),
                const SizedBox(width: 8),
                _MacroTile(
                  label: 'Carbs',
                  grams: targets.carbsG,
                  color: AppColors.carbs,
                ),
                const SizedBox(width: 8),
                _MacroTile(
                  label: 'Fat',
                  grams: targets.fatG,
                  color: AppColors.fat,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'BMR ${targets.bmr.round()} kcal × activity = '
              '${targets.tdee.round()} kcal a day, adjusted for your goal.',
              style: text.bodySmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final int grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$grams g',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
