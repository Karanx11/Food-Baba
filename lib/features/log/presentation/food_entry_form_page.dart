import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/number_field.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../application/log_providers.dart';
import '../domain/food_entry.dart';
import '../domain/nutrition.dart';
import 'meal_type_ui.dart';

/// Add a food by hand, or edit an existing entry. Pops `true` after a save or
/// delete.
class FoodEntryFormPage extends ConsumerStatefulWidget {
  const FoodEntryFormPage({
    super.key,
    required this.dayKey,
    required this.meal,
    this.existing,
    this.template,
    this.initialName,
  });

  final String dayKey;
  final MealType meal;

  /// Entry being edited. Null when adding.
  final FoodEntry? existing;

  /// Earlier entry whose values pre-fill a new one, e.g. a recent food.
  final FoodEntry? template;

  /// Pre-filled food name for a new entry, e.g. an unmatched search.
  final String? initialName;

  static Route<bool> route({
    required String dayKey,
    required MealType meal,
    FoodEntry? existing,
    FoodEntry? template,
    String? initialName,
  }) => MaterialPageRoute<bool>(
    builder: (_) => FoodEntryFormPage(
      dayKey: dayKey,
      meal: meal,
      existing: existing,
      template: template,
      initialName: initialName,
    ),
  );

  @override
  ConsumerState<FoodEntryFormPage> createState() => _FoodEntryFormPageState();
}

class _FoodEntryFormPageState extends ConsumerState<FoodEntryFormPage> {
  final _formKey = GlobalKey<FormState>();

  FoodEntry? get _seed => widget.existing ?? widget.template;

  late final _name = TextEditingController(
    text: _seed?.name ?? widget.initialName ?? '',
  );
  late final _servingLabel = TextEditingController(
    text: _seed?.servingLabel ?? '1 serving',
  );
  late final _servings = TextEditingController(
    text: compactNumber(_seed?.servings ?? 1, decimals: 2),
  );
  late final _calories = TextEditingController(
    text: _numberText(_seed?.perServing.calories),
  );
  late final _protein = TextEditingController(
    text: _numberText(_seed?.perServing.proteinG),
  );
  late final _carbs = TextEditingController(
    text: _numberText(_seed?.perServing.carbsG),
  );
  late final _fat = TextEditingController(
    text: _numberText(_seed?.perServing.fatG),
  );
  late MealType _meal = widget.existing?.meal ?? widget.meal;
  bool _saving = false;

  static String _numberText(double? v) =>
      v == null ? '' : compactNumber(v, decimals: 2);

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
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Nutrition get _perServing => Nutrition(
    calories: _num(_calories),
    proteinG: _num(_protein),
    carbsG: _num(_carbs),
    fatG: _num(_fat),
  );

  double get _servingCount => _num(_servings);

  void _prefill(FoodEntry e) {
    setState(() {
      _name.text = e.name;
      _servingLabel.text = e.servingLabel;
      _servings.text = compactNumber(e.servings, decimals: 2);
      _calories.text = _numberText(e.perServing.calories);
      _protein.text = _numberText(e.perServing.proteinG);
      _carbs.text = _numberText(e.perServing.carbsG);
      _fat.text = _numberText(e.perServing.fatG);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = ref.read(clockProvider)();
    final existing = widget.existing;
    final label = _servingLabel.text.trim();
    final entry = FoodEntry(
      id: existing?.id ?? FoodEntry.newId(now, Random()),
      dayKey: existing?.dayKey ?? widget.dayKey,
      meal: _meal,
      name: _name.text.trim(),
      servingLabel: label.isEmpty ? '1 serving' : label,
      servings: _servingCount,
      perServing: _perServing,
      source: existing?.source ?? widget.template?.source ?? FoodSource.manual,
      createdAt: existing?.createdAt ?? now,
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

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete this entry?'),
            content: Text(existing.name),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await ref.read(foodLogRepositoryProvider).delete(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    final total = _perServing * _servingCount;
    final servingText = _servingLabel.text.trim();

    return Scaffold(
      appBar: appTopBar(
        context,
        title: isEdit ? 'Edit food' : 'Add food',
        actions: [
          if (isEdit)
            CircleIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Delete',
              size: 42,
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEdit) _RecentFoods(onPick: _prefill),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Food name',
                  hintText: 'e.g. Dal tadka',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Give it a name' : null,
              ),
              const SizedBox(height: 16),
              Text('Meal', style: text.titleSmall),
              const SizedBox(height: 8),
              MealChips(
                selected: _meal,
                onSelected: (m) => setState(() => _meal = m),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _servingLabel,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Serving size',
                        hintText: '1 cup, 100 g, 1 roti',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: NumberField(
                      controller: _servings,
                      label: 'Servings',
                      min: 0.1,
                      max: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Nutrition per serving',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
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
                  Expanded(
                    child: NumberField(
                      controller: _protein,
                      label: 'Protein',
                      suffix: 'g',
                      isRequired: false,
                      min: 0,
                      max: 1000,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      controller: _carbs,
                      label: 'Carbs',
                      suffix: 'g',
                      isRequired: false,
                      min: 0,
                      max: 1000,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NumberField(
                      controller: _fat,
                      label: 'Fat',
                      suffix: 'g',
                      isRequired: false,
                      min: 0,
                      max: 1000,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total for '
                              '${compactNumber(_servingCount, decimals: 2)} × '
                              '${servingText.isEmpty ? 'serving' : servingText}',
                              style: text.labelMedium?.copyWith(
                                color: scheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${total.calories.round()} kcal · '
                              'P ${compactNumber(total.proteinG)} g · '
                              'C ${compactNumber(total.carbsG)} g · '
                              'F ${compactNumber(total.fatG)} g',
                              style: text.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(isEdit ? 'Save changes' : 'Add to ${_meal.label}'),
        ),
      ),
    );
  }
}

/// Horizontal strip of recently logged foods that pre-fill the form.
class _RecentFoods extends ConsumerWidget {
  const _RecentFoods({required this.onPick});

  final ValueChanged<FoodEntry> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentFoodsProvider).value ?? const <FoodEntry>[];
    if (recent.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent', style: text.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry in recent)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.history_rounded, size: 18),
                    label: Text(entry.name),
                    onPressed: () => onPick(entry),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
