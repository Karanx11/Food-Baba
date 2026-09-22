import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../log/application/log_providers.dart';
import '../../log/domain/daily_log.dart';
import '../../log/domain/food_entry.dart';
import '../../log/domain/nutrition.dart';
import '../../log/presentation/food_entry_form_page.dart';
import '../../log/presentation/meal_type_ui.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/nutrition_targets.dart';
import '../../profile/presentation/profile_form_page.dart';
import '../../shell/shell_tab_provider.dart';
import 'calorie_ring.dart';

/// Today at a glance: calorie ring, macros, meals and water.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static String greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final todayKey = dayKeyOf(now);
    final entries =
        ref.watch(dayEntriesProvider(todayKey)).value ?? const <FoodEntry>[];
    final water = ref.watch(waterProvider(todayKey)).value ?? 0;
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final targets = ref.watch(targetsProvider);
    final repo = ref.watch(foodLogRepositoryProvider);
    final log = DailyLog(
      dayKey: todayKey,
      entries: entries,
      waterGlasses: water,
    );

    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final name = profile?.name ?? '';
    final greeting = name.isEmpty
        ? greetingFor(now.hour)
        : '${greetingFor(now.hour)}, $name';

    void addTo(MealType meal) => Navigator.of(
      context,
    ).push(FoodEntryFormPage.route(dayKey: todayKey, meal: meal));

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Text(
            greeting,
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            shortDate(now),
            style: text.bodyMedium?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 16),
          if (profileAsync.hasValue && profile == null) ...[
            const _SetupNudge(),
            const SizedBox(height: 12),
          ],
          _CalorieCard(totals: log.totals, targets: targets),
          const SizedBox(height: 12),
          _MacrosCard(totals: log.totals, targets: targets),
          const SizedBox(height: 12),
          _MealsCard(
            log: log,
            onAdd: addTo,
            onSeeAll: () =>
                ref.read(shellTabProvider.notifier).select(ShellTabs.log),
          ),
          const SizedBox(height: 12),
          _WaterRow(
            glasses: water,
            onAdd: () => repo.setWater(todayKey, water + 1),
          ),
        ],
      ),
    );
  }
}

class _SetupNudge extends StatelessWidget {
  const _SetupNudge();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Set your daily targets',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tell us about yourself to unlock calorie and macro goals.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () =>
                    Navigator.of(context).push(ProfileFormPage.route()),
                child: const Text('Set up profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({required this.totals, required this.targets});

  final Nutrition totals;
  final NutritionTargets? targets;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final eaten = totals.calories.round();
    final target = targets?.calories;
    final remaining = target == null ? null : target - eaten;
    final over = remaining != null && remaining < 0;
    final ringColor = over ? AppColors.fat : scheme.primary;

    final centerValue = remaining == null ? '$eaten' : '${remaining.abs()}';
    final centerLabel = remaining == null
        ? 'kcal eaten'
        : over
        ? 'kcal over'
        : 'kcal left';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CalorieRing(
              progress: target == null ? 0 : eaten / target,
              color: ringColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerValue,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: text.labelMedium?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Stat(
                    label: 'Eaten',
                    value: '$eaten kcal',
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 14),
                  _Stat(
                    label: 'Target',
                    value: target == null ? '—' : '$target kcal',
                    color: scheme.outlineVariant,
                  ),
                  const SizedBox(height: 14),
                  _Stat(
                    label: over ? 'Over' : 'Left',
                    value: remaining == null ? '—' : '${remaining.abs()} kcal',
                    color: over ? AppColors.fat : AppColors.protein,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.labelMedium?.copyWith(color: scheme.outline),
            ),
            Text(
              value,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({required this.totals, required this.targets});

  final Nutrition totals;
  final NutritionTargets? targets;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Macros', style: text.titleMedium),
            const SizedBox(height: 14),
            _MacroBar(
              label: 'Protein',
              value: totals.proteinG,
              target: targets?.proteinG,
              color: AppColors.protein,
            ),
            const SizedBox(height: 12),
            _MacroBar(
              label: 'Carbs',
              value: totals.carbsG,
              target: targets?.carbsG,
              color: AppColors.carbs,
            ),
            const SizedBox(height: 12),
            _MacroBar(
              label: 'Fat',
              value: totals.fatG,
              target: targets?.fatG,
              color: AppColors.fat,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
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
    final goal = target;
    final ratio = goal == null || goal == 0 ? 0.0 : value / goal;
    final amount = compactNumber(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: text.labelLarge),
            Text(
              goal == null ? '$amount g' : '$amount / $goal g',
              style: text.labelMedium?.copyWith(color: scheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealsCard extends StatelessWidget {
  const _MealsCard({
    required this.log,
    required this.onAdd,
    required this.onSeeAll,
  });

  final DailyLog log;
  final ValueChanged<MealType> onAdd;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            title: Text('Meals', style: text.titleMedium),
            trailing: TextButton(
              onPressed: onSeeAll,
              child: const Text('See full log'),
            ),
          ),
          const Divider(height: 1),
          for (final meal in MealType.values)
            _MealRow(
              meal: meal,
              entries: log.entriesFor(meal),
              calories: log.totalsFor(meal).calories.round(),
              onAdd: () => onAdd(meal),
              scheme: scheme,
              text: text,
            ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.entries,
    required this.calories,
    required this.onAdd,
    required this.scheme,
    required this.text,
  });

  final MealType meal;
  final List<FoodEntry> entries;
  final int calories;
  final VoidCallback onAdd;
  final ColorScheme scheme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final names = entries.map((e) => e.name).join(', ');
    return ListTile(
      leading: Icon(meal.icon, color: scheme.primary),
      title: Text(meal.label),
      subtitle: Text(
        names.isEmpty ? 'Nothing yet' : names,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: scheme.outline),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entries.isNotEmpty)
            Text(
              '$calories kcal',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          IconButton(
            key: Key('home-add-${meal.name}'),
            tooltip: 'Add to ${meal.label}',
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _WaterRow extends StatelessWidget {
  const _WaterRow({required this.glasses, required this.onAdd});

  static const Color _blue = Color(0xFF4FC3F7);

  final int glasses;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.water_drop_rounded, color: _blue),
        title: Text('Water', style: text.titleMedium),
        subtitle: Text(
          '$glasses of ${DailyLog.waterGoalGlasses} glasses · '
          '${glasses * DailyLog.mlPerGlass} ml',
        ),
        trailing: IconButton.filledTonal(
          key: const Key('home-water-plus'),
          tooltip: 'Add a glass',
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
