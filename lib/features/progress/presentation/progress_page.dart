import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/widgets/loaders/burger_loader.dart';
import '../../../core/widgets/number_field.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../../log/application/log_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_form_page.dart';
import '../application/progress_providers.dart';
import '../domain/body_metrics.dart';
import '../domain/weight_entry.dart';
import 'bmi_bar.dart';
import 'weight_chart.dart';

/// Goal and current weight, the weight trend and BMI.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: appTopBar(context, title: 'Goal Progress'),
      body: profileAsync.when(
        loading: () => const Center(child: BurgerLoader(size: 72)),
        error: (error, _) =>
            Center(child: Text('Could not load your profile.\n$error')),
        data: (profile) =>
            profile == null ? const _NoProfile() : _Content(profile: profile),
      ),
    );
  }
}

class _NoProfile extends StatelessWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('Track your weight goal', style: text.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Set up your profile to see progress and BMI.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).push(ProfileFormPage.route()),
              child: const Text('Set up profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final today = dateOnly(ref.watch(clockProvider)());
    final history =
        ref.watch(weightHistoryProvider).value ?? const <WeightEntry>[];
    final range = ref.watch(chartRangeProvider);
    final notifier = ref.read(profileProvider.notifier);

    final fromKey = dayKeyOf(
      DateTime(today.year, today.month, today.day - (range.days - 1)),
    );
    final toKey = dayKeyOf(today);
    final shown = [
      for (final e in history)
        if (e.dayKey.compareTo(fromKey) >= 0 && e.dayKey.compareTo(toKey) <= 0)
          e,
    ];

    final goal = profile.goalWeightKg;
    final progress = BodyMetrics.goalProgress(
      start: profile.goalStartKg ?? profile.weightKg,
      current: profile.weightKg,
      goal: goal,
    );
    final bmi = BodyMetrics.bmi(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
    );
    final category = BodyMetrics.categoryOf(bmi);

    Future<void> askWeight({
      required String title,
      required double? initial,
      required Future<void> Function(double) save,
    }) async {
      final kg = await showDialog<double>(
        context: context,
        builder: (_) => _WeightDialog(title: title, initial: initial),
      );
      if (kg != null) await save(kg);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _WeightRow(
          value: goal == null ? '—' : '${compactNumber(goal)} kg',
          label: 'Goal weight',
          action: 'Update my goal',
          buttonKey: const Key('update-goal'),
          onPressed: () => askWeight(
            title: 'Goal weight',
            initial: goal,
            save: notifier.updateGoal,
          ),
        ),
        const SizedBox(height: 6),
        _WeightRow(
          value: '${compactNumber(profile.weightKg)} kg',
          label: 'Current weight',
          action: 'Update weight',
          buttonKey: const Key('update-weight'),
          onPressed: () => askWeight(
            title: 'Current weight',
            initial: profile.weightKg,
            save: notifier.updateWeight,
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Goal Progress', style: text.titleMedium),
                  ),
                  _RangeMenu(
                    range: range,
                    onSelect: ref.read(chartRangeProvider.notifier).select,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    progress == null ? '—' : '${(progress * 100).round()}%',
                    style: text.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progress == null
                        ? 'Set a goal weight'
                        : BodyMetrics.progressLabel(progress),
                    style: text.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 190,
                child: WeightChart(
                  entries: shown,
                  end: today,
                  days: range.days,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your BMI (Body Mass Index)', style: text.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(bmi.toStringAsFixed(1), style: text.headlineSmall),
                  const SizedBox(width: 10),
                  Text(
                    'Your weight is',
                    style: text.bodyMedium?.copyWith(color: palette.muted),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: ShapeDecoration(
                      shape: const StadiumBorder(),
                      color: bmiColor(category).withValues(alpha: 0.16),
                    ),
                    child: Text(
                      category.label,
                      style: text.labelMedium?.copyWith(
                        color: bmiColor(category),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BmiBar(bmi: bmi),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final c in BmiCategory.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bmiColor(c),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.label,
                          style: text.labelSmall?.copyWith(
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({
    required this.value,
    required this.label,
    required this.action,
    required this.buttonKey,
    required this.onPressed,
  });

  final String value;
  final String label;
  final String action;
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  label,
                  style: text.labelMedium?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          FilledButton(
            key: buttonKey,
            onPressed: onPressed,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _RangeMenu extends StatelessWidget {
  const _RangeMenu({required this.range, required this.onSelect});

  final ChartRange range;
  final ValueChanged<ChartRange> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return MenuAnchor(
      menuChildren: [
        for (final r in ChartRange.values)
          MenuItemButton(onPressed: () => onSelect(r), child: Text(r.label)),
      ],
      builder: (context, controller, _) => Material(
        key: const Key('range-menu'),
        color: palette.card,
        shape: StadiumBorder(side: BorderSide(color: palette.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(range.label, style: text.labelLarge),
                const Icon(Icons.expand_more_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeightDialog extends StatefulWidget {
  const _WeightDialog({required this.title, required this.initial});

  final String title;
  final double? initial;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

class _WeightDialogState extends State<_WeightDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _kg = TextEditingController(
    text: widget.initial == null ? '' : compactNumber(widget.initial!),
  );

  @override
  void dispose() {
    _kg.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(double.parse(_kg.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: NumberField(
          controller: _kg,
          label: 'Weight',
          suffix: 'kg',
          min: ProfileLimits.minWeightKg,
          max: ProfileLimits.maxWeightKg,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
