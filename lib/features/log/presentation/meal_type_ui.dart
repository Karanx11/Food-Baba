import 'package:flutter/material.dart';

import '../domain/food_entry.dart';

extension MealTypeUi on MealType {
  IconData get icon => switch (this) {
    MealType.breakfast => Icons.free_breakfast_rounded,
    MealType.lunch => Icons.lunch_dining_rounded,
    MealType.dinner => Icons.dinner_dining_rounded,
    MealType.snack => Icons.cookie_rounded,
  };
}

/// One choice chip per meal.
class MealChips extends StatelessWidget {
  const MealChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MealType selected;
  final ValueChanged<MealType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final meal in MealType.values)
          ChoiceChip(
            avatar: Icon(meal.icon, size: 18),
            label: Text(meal.label),
            selected: meal == selected,
            onSelected: (_) => onSelected(meal),
          ),
      ],
    );
  }
}
