import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../core/widgets/number_field.dart';
import '../../log/domain/nutrition.dart';
import '../domain/detected_food.dart';

/// Bottom sheet to correct a detected food before logging: its name, serving
/// and the per-serving nutrition. Returns the edited food, or null if
/// cancelled. AI estimates are approximate, so this lets the user fix values
/// like an over-counted protein.
class EditFoodSheet extends StatefulWidget {
  const EditFoodSheet({super.key, required this.food});

  final DetectedFood food;

  static Future<DetectedFood?> show(BuildContext context, DetectedFood food) =>
      showModalBottomSheet<DetectedFood>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EditFoodSheet(food: food),
      );

  @override
  State<EditFoodSheet> createState() => _EditFoodSheetState();
}

class _EditFoodSheetState extends State<EditFoodSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.food.name);
  late final _servingLabel = TextEditingController(
    text: widget.food.servingLabel,
  );
  late final _servings = TextEditingController(
    text: compactNumber(widget.food.servings, decimals: 2),
  );
  late final _calories = _num(widget.food.perServing.calories);
  late final _protein = _num(widget.food.perServing.proteinG);
  late final _carbs = _num(widget.food.perServing.carbsG);
  late final _fat = _num(widget.food.perServing.fatG);
  late final _sugar = _num(widget.food.perServing.sugarG);
  late final _fiber = _num(widget.food.perServing.fiberG);
  late final _sodium = _num(widget.food.perServing.sodiumMg);

  static TextEditingController _num(double v) =>
      TextEditingController(text: compactNumber(v, decimals: 2));

  @override
  void dispose() {
    for (final c in [
      _name,
      _servingLabel,
      _servings,
      _calories,
      _protein,
      _carbs,
      _fat,
      _sugar,
      _fiber,
      _sodium,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _read(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final label = _servingLabel.text.trim();
    final edited = widget.food.copyWith(
      name: _name.text.trim(),
      servingLabel: label.isEmpty ? '1 serving' : label,
      servings: _read(_servings),
      perServing: Nutrition(
        calories: _read(_calories),
        proteinG: _read(_protein),
        carbsG: _read(_carbs),
        fatG: _read(_fat),
        sugarG: _read(_sugar),
        fiberG: _read(_fiber),
        sodiumMg: _read(_sodium),
      ),
    );
    Navigator.of(context).pop(edited);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Sit above the keyboard when a field is focused.
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit food', style: text.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Give it a name' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _servingLabel,
                        decoration: const InputDecoration(
                          labelText: 'Serving',
                          hintText: '1 plate, 1 katori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: NumberField(
                        controller: _servings,
                        label: 'Quantity',
                        min: 0.1,
                        max: 50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Nutrition per serving',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                NumberField(
                  controller: _calories,
                  label: 'Calories',
                  suffix: 'kcal',
                  min: 0,
                  max: 5000,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _macro(_protein, 'Protein')),
                    const SizedBox(width: 8),
                    Expanded(child: _macro(_carbs, 'Carbs')),
                    const SizedBox(width: 8),
                    Expanded(child: _macro(_fat, 'Fat')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _macro(_sugar, 'Sugar')),
                    const SizedBox(width: 8),
                    Expanded(child: _macro(_fiber, 'Fiber')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NumberField(
                        controller: _sodium,
                        label: 'Sodium',
                        suffix: 'mg',
                        isRequired: false,
                        min: 0,
                        max: 20000,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _macro(TextEditingController c, String label) => NumberField(
    controller: c,
    label: label,
    suffix: 'g',
    isRequired: false,
    min: 0,
    max: 2000,
  );
}
