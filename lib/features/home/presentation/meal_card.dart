import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/food_emoji.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/surfaces.dart';
import '../../log/domain/food_entry.dart';

/// One meal on the home screen: calories, food thumbnails and a quick add.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.entries,
    required this.calories,
    required this.onAdd,
    required this.onOpen,
  });

  final MealType meal;
  final List<FoodEntry> entries;
  final int calories;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final empty = entries.isEmpty;

    return AppCard(
      key: ValueKey('meal-card-${meal.name}'),
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.label, style: text.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.soft(
                          AppColors.flame,
                          Theme.of(context).brightness,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: AppColors.flame,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      empty ? 'No food yet' : '$calories Kcal',
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: empty ? palette.muted : palette.ink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!empty) _Thumbnails(names: [for (final e in entries) e.name]),
          const SizedBox(width: 8),
          CircleIconButton(
            key: Key('home-add-${meal.name}'),
            icon: Icons.add_rounded,
            tooltip: 'Add to ${meal.label}',
            size: 36,
            background: palette.cardMuted,
            elevated: false,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// Up to three overlapping round thumbnails.
class _Thumbnails extends StatelessWidget {
  const _Thumbnails({required this.names});

  static const double _size = 36;
  static const double _step = 24;

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shown = names.take(3).toList();
    return SizedBox(
      width: _size + (shown.length - 1) * _step,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.cardMuted,
                  border: Border.all(color: palette.card, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  foodEmoji(shown[i]),
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
