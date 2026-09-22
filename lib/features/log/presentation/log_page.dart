import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/loaders/burger_loader.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../../food_search/presentation/food_search_page.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/nutrition_targets.dart';
import '../application/log_providers.dart';
import '../data/food_log_repository.dart';
import '../domain/daily_log.dart';
import '../domain/food_entry.dart';
import '../domain/nutrition.dart';
import 'food_entry_form_page.dart';
import 'meal_type_ui.dart';

/// Daily food diary: day picker, totals, meals and water.
class LogPage extends ConsumerWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final today = dateOnly(ref.watch(clockProvider)());
    final dayKey = dayKeyOf(day);
    final entries = ref.watch(dayEntriesProvider(dayKey));
    final water = ref.watch(waterProvider(dayKey)).value ?? 0;
    final targets = ref.watch(targetsProvider);
    final isToday = day == today;

    Future<void> pickDay() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: day,
        firstDate: DateTime(2020),
        lastDate: today,
      );
      if (picked != null) ref.read(selectedDayProvider.notifier).select(picked);
    }

    return Scaffold(
      appBar: appTopBar(
        context,
        title: 'Food Log',
        actions: [
          if (!isToday)
            TextButton(
              onPressed: () => ref.read(selectedDayProvider.notifier).today(),
              child: const Text('Today'),
            ),
        ],
      ),
      body: Column(
        children: [
          _DayNavigator(
            day: day,
            today: today,
            onPrevious: () => ref.read(selectedDayProvider.notifier).previous(),
            onNext: isToday
                ? null
                : () => ref.read(selectedDayProvider.notifier).next(),
            onPick: pickDay,
          ),
          Expanded(
            child: entries.when(
              loading: () => const Center(child: BurgerLoader(size: 72)),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load the log.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (list) => _DayContent(
                log: DailyLog(
                  dayKey: dayKey,
                  entries: list,
                  waterGlasses: water,
                ),
                targets: targets,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.day,
    required this.today,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime day;
  final DateTime today;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final friendly = friendlyDay(day, today: today);
    final short = shortDate(day);
    final label = friendly == short ? short : '$friendly · $short';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous day',
            size: 40,
            onPressed: onPrevious,
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          CircleIconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next day',
            size: 40,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Meals and water for the day. Keeps swiped-away entries out of the tree
/// until the store confirms the delete, so Dismissible never sees a stale row.
class _DayContent extends ConsumerStatefulWidget {
  const _DayContent({required this.log, required this.targets});

  final DailyLog log;
  final NutritionTargets? targets;

  @override
  ConsumerState<_DayContent> createState() => _DayContentState();
}

class _DayContentState extends ConsumerState<_DayContent> {
  final Set<String> _dismissed = {};

  Future<void> _delete(FoodEntry entry) async {
    setState(() => _dismissed.add(entry.id));
    final repo = ref.read(foodLogRepositoryProvider);
    await repo.delete(entry.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Removed ${entry.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _restore(repo, entry),
        ),
      ),
    );
  }

  void _restore(FoodLogRepository repo, FoodEntry entry) {
    if (mounted) setState(() => _dismissed.remove(entry.id));
    repo.upsert(entry);
  }

  /// Adding starts at food search; editing goes straight to the form.
  void _openForm(MealType meal, [FoodEntry? existing]) {
    final dayKey = widget.log.dayKey;
    Navigator.of(context).push(
      existing == null
          ? FoodSearchPage.route(dayKey: dayKey, meal: meal)
          : FoodEntryFormPage.route(
              dayKey: dayKey,
              meal: meal,
              existing: existing,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stored = widget.log.entries;
    _dismissed.removeWhere((id) => !stored.any((e) => e.id == id));
    final log = DailyLog(
      dayKey: widget.log.dayKey,
      entries: stored.where((e) => !_dismissed.contains(e.id)).toList(),
      waterGlasses: widget.log.waterGlasses,
    );
    final repo = ref.watch(foodLogRepositoryProvider);

    return ListView(
      // Clear the FAB and the floating navigation bar.
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _SummaryCard(totals: log.totals, targets: widget.targets),
        const SizedBox(height: 12),
        for (final meal in MealType.values) ...[
          _MealSection(
            meal: meal,
            entries: log.entriesFor(meal),
            subtotal: log.totalsFor(meal),
            onAdd: () => _openForm(meal),
            onEdit: (e) => _openForm(e.meal, e),
            onDelete: _delete,
          ),
          const SizedBox(height: 12),
        ],
        _WaterCard(
          glasses: log.waterGlasses,
          onChanged: (g) => repo.setWater(log.dayKey, g),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals, required this.targets});

  final Nutrition totals;
  final NutritionTargets? targets;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final eaten = totals.calories.round();
    final target = targets?.calories;
    final over = target != null && eaten > target;

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
                  '$eaten',
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: over ? AppColors.fat : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  target == null ? 'kcal eaten' : '/ $target kcal',
                  style: text.bodyMedium?.copyWith(color: scheme.outline),
                ),
              ],
            ),
            if (target != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (eaten / target).clamp(0.0, 1.0),
                  minHeight: 8,
                  color: over ? AppColors.fat : scheme.primary,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroChip(
                  label: 'Protein',
                  value: totals.proteinG,
                  target: targets?.proteinG,
                  color: AppColors.protein,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: 'Carbs',
                  value: totals.carbsG,
                  target: targets?.carbsG,
                  color: AppColors.carbs,
                ),
                const SizedBox(width: 8),
                _MacroChip(
                  label: 'Fat',
                  value: totals.fatG,
                  target: targets?.fatG,
                  color: AppColors.fat,
                ),
              ],
            ),
            if (target == null) ...[
              const SizedBox(height: 10),
              Text(
                'Set up your profile to get daily targets.',
                style: text.bodySmall?.copyWith(color: scheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final int? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final amount = compactNumber(value);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.soft(color, Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              target == null ? '$amount g' : '$amount / $target g',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.subtotal,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final MealType meal;
  final List<FoodEntry> entries;
  final Nutrition subtotal;
  final VoidCallback onAdd;
  final ValueChanged<FoodEntry> onEdit;
  final ValueChanged<FoodEntry> onDelete;

  static String _describe(FoodEntry e) =>
      '${compactNumber(e.servings, decimals: 2)} × ${e.servingLabel} · '
      'P ${compactNumber(e.total.proteinG)} · '
      'C ${compactNumber(e.total.carbsG)} · '
      'F ${compactNumber(e.total.fatG)} g';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppPalette.of(context).cardMuted,
              child: Icon(meal.icon, color: scheme.primary),
            ),
            title: Text(
              meal.label,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              entries.isEmpty
                  ? 'Nothing logged yet'
                  : '${subtotal.calories.round()} kcal',
            ),
            trailing: TextButton.icon(
              key: Key('add-${meal.name}'),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            ),
          ),
          if (entries.isNotEmpty) const Divider(height: 1),
          for (final entry in entries)
            Dismissible(
              key: ValueKey('entry-${entry.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: scheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: scheme.onError,
                ),
              ),
              onDismissed: (_) => onDelete(entry),
              child: ListTile(
                title: Text(entry.name),
                subtitle: Text(_describe(entry)),
                trailing: Text(
                  '${entry.total.calories.round()} kcal',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                onTap: () => onEdit(entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.glasses, required this.onChanged});

  static const Color _blue = AppColors.water;

  final int glasses;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_rounded, color: _blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Water',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$glasses of ${DailyLog.waterGoalGlasses} glasses · '
                        '${glasses * DailyLog.mlPerGlass} ml',
                        style: text.bodySmall?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('water-minus'),
                  tooltip: 'Remove a glass',
                  onPressed: glasses > 0 ? () => onChanged(glasses - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  key: const Key('water-plus'),
                  tooltip: 'Add a glass',
                  onPressed: () => onChanged(glasses + 1),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < DailyLog.waterGoalGlasses; i++)
                  Expanded(
                    child: Icon(
                      i < glasses
                          ? Icons.water_drop_rounded
                          : Icons.water_drop_outlined,
                      size: 22,
                      color: i < glasses ? _blue : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
