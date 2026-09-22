import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/nutrition_targets.dart';

/// Calories headline plus protein / carbs / fat pills.
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
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleSmall),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${targets.calories}',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kcal / day',
                style: text.bodyMedium?.copyWith(color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MacroPill(
                label: 'Protein',
                grams: targets.proteinG,
                color: AppColors.protein,
              ),
              const SizedBox(width: 10),
              _MacroPill(
                label: 'Carbs',
                grams: targets.carbsG,
                color: AppColors.carbs,
              ),
              const SizedBox(width: 10),
              _MacroPill(
                label: 'Fat',
                grams: targets.fatG,
                color: AppColors.fat,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'BMR ${targets.bmr.round()} kcal × activity = '
            '${targets.tdee.round()} kcal a day, adjusted for your goal.',
            style: text.bodySmall?.copyWith(color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
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
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: AppColors.soft(color, Theme.of(context).brightness),
            ),
            child: Text(
              '$grams g',
              style: text.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: text.bodyMedium),
        ],
      ),
    );
  }
}
