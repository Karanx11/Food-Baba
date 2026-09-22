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
