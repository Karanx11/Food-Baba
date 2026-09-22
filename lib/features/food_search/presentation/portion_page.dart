import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../../log/application/log_providers.dart';
import '../../log/domain/food_entry.dart';
import '../../log/domain/nutrition.dart';
import '../../log/presentation/meal_type_ui.dart';
import '../domain/food_item.dart';
import 'portion_selector.dart';

/// Choose how much of a catalog food was eaten, then log it.
/// Pops `true` once the entry is saved.
class PortionPage extends ConsumerStatefulWidget {
  const PortionPage({
    super.key,
    required this.food,
    required this.dayKey,
    required this.meal,
  });

  final FoodItem food;
  final String dayKey;
  final MealType meal;

  static Route<bool> route({
    required FoodItem food,
    required String dayKey,
    required MealType meal,
  }) => MaterialPageRoute<bool>(
    builder: (_) => PortionPage(food: food, dayKey: dayKey, meal: meal),
  );

  @override
  ConsumerState<PortionPage> createState() => _PortionPageState();
}

class _PortionPageState extends ConsumerState<PortionPage> {
  late ServingOption _serving = widget.food.servings.first;
  double _quantity = 1;
  late MealType _meal = widget.meal;
  bool _saving = false;

  Nutrition get _total => widget.food.nutritionFor(_serving.grams * _quantity);

  Future<void> _save() async {
    final now = ref.read(clockProvider)();
    final entry = FoodEntry(
      id: FoodEntry.newId(now, Random()),
      dayKey: widget.dayKey,
      meal: _meal,
      name: widget.food.name,
      servingLabel: _serving.description,
      servings: _quantity,
      perServing: widget.food.nutritionFor(_serving.grams),
      source: FoodSource.search,
      createdAt: now,
    );

    setState(() => _saving = true);
    try {
      await ref.read(foodLogRepositoryProvider).upsert(entry);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final food = widget.food;

    return Scaffold(
      appBar: appTopBar(context, title: food.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            food.category,
            style: text.labelLarge?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 12),
          _NutritionCard(total: _total),
          const SizedBox(height: 20),
          PortionSelector(
            options: food.servings,
            selected: _serving,
            quantity: _quantity,
            onServingChanged: (s) => setState(() => _serving = s),
            onQuantityChanged: (q) => setState(() => _quantity = q),
          ),
          const SizedBox(height: 20),
          Text('Meal', style: text.titleSmall),
          const SizedBox(height: 8),
          MealChips(
            selected: _meal,
            onSelected: (m) => setState(() => _meal = m),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: scheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Typical values. Actual nutrition varies by recipe and '
                  'brand.',
                  style: text.bodySmall?.copyWith(color: scheme.outline),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text('Add to ${_meal.label}'),
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.total});

  final Nutrition total;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${total.calories.round()}',
                  key: const Key('portion-calories'),
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'kcal',
                  style: text.bodyMedium?.copyWith(color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MacroTile('Protein', total.proteinG, AppColors.protein),
                const SizedBox(width: 8),
                _MacroTile('Carbs', total.carbsG, AppColors.carbs),
                const SizedBox(width: 8),
                _MacroTile('Fat', total.fatG, AppColors.fat),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sugar ${compactNumber(total.sugarG)} g · '
              'Fiber ${compactNumber(total.fiberG)} g · '
              'Sodium ${total.sodiumMg.round()} mg',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile(this.label, this.grams, this.color);

  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '${compactNumber(grams)} g',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
