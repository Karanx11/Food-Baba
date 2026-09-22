import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/dates.dart';
import '../../../core/format.dart';
import '../../../core/widgets/arc_gauge.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../../../core/widgets/water_fill.dart';
import '../../log/application/log_providers.dart';
import '../../log/domain/daily_log.dart';
import '../../log/domain/food_entry.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/presentation/profile_form_page.dart';
import '../../shell/shell_tab_provider.dart';
import '../domain/health_score.dart';

/// Calories, macros, water and a health score for the selected day.
class DailyBreakdownPage extends ConsumerWidget {
  const DailyBreakdownPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const DailyBreakdownPage());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final today = dateOnly(ref.watch(clockProvider)());
    final day = ref.watch(selectedDayProvider);
    final dayKey = dayKeyOf(day);
    final entries =
        ref.watch(dayEntriesProvider(dayKey)).value ?? const <FoodEntry>[];
    final water = ref.watch(waterProvider(dayKey)).value ?? 0;
    final profile = ref.watch(profileProvider).value;
    final targets = ref.watch(targetsProvider);
    final totals = DailyLog(dayKey: dayKey, entries: entries).totals;
    final report = HealthScore.evaluate(totals, targets);

    final eaten = totals.calories.round();
    final target = targets?.calories;
    final over = target != null && eaten > target;
    final friendly = friendlyDay(day, today: today);
    final short = shortDate(day);
    final big = text.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    );

    void openLog() {
      ref.read(shellTabProvider.notifier).select(ShellTabs.log);
      Navigator.of(context).pop();
    }

    void editTargets() =>
        Navigator.of(context).push(ProfileFormPage.route(initial: profile));

    return Scaffold(
      appBar: appTopBar(
        context,
        title: 'Daily Breakdown',
        actions: [_MoreMenu(onOpenLog: openLog, onEditTargets: editTargets)],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 10, 10, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        friendly == short ? short : '$friendly · $short',
                        style: text.bodySmall?.copyWith(color: palette.muted),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit targets',
                      onPressed: editTargets,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ],
                ),
                ArcGauge(
                  key: const Key('breakdown-gauge'),
                  progress: target == null ? 0 : eaten / target,
                  size: 220,
                  strokeWidth: 20,
                  knob: true,
                  color: over ? AppColors.danger : palette.ink,
                  // Keep large numbers inside the ring instead of under it.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '$eaten', style: big),
                                if (target != null)
                                  TextSpan(text: ' / $target', style: big),
                              ],
                            ),
                          ),
                          Text(
                            target == null ? 'Calories eaten' : 'Calories',
                            style: text.bodyLarge?.copyWith(
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      _MacroPill(
                        grams: totals.proteinG,
                        label: 'Protein',
                        color: AppColors.protein,
                        brightness: brightness,
                      ),
                      const SizedBox(width: 10),
                      _MacroPill(
                        grams: totals.carbsG,
                        label: 'Carbs',
                        color: AppColors.carbs,
                        brightness: brightness,
                      ),
                      const SizedBox(width: 10),
                      _MacroPill(
                        grams: totals.fatG,
                        label: 'Fats',
                        color: AppColors.fat,
                        brightness: brightness,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _WaterCard(
            glasses: water,
            onAdd: () =>
                ref.read(foodLogRepositoryProvider).setWater(dayKey, water + 1),
          ),
          const SizedBox(height: 10),
          _HealthCard(report: report),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onOpenLog, required this.onEditTargets});

  final VoidCallback onOpenLog;
  final VoidCallback onEditTargets;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-120, 6),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.menu_book_outlined),
          onPressed: onOpenLog,
          child: const Text('Open food log'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.tune_rounded),
          onPressed: onEditTargets,
          child: const Text('Edit targets'),
        ),
      ],
      builder: (context, controller, _) => CircleIconButton(
        icon: Icons.more_vert_rounded,
        tooltip: 'More',
        size: 42,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.grams,
    required this.label,
    required this.color,
    required this.brightness,
  });

  final double grams;
  final String label;
  final Color color;
  final Brightness brightness;

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
              color: AppColors.soft(color, brightness),
            ),
            child: Text(
              '${compactNumber(grams)} g',
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

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.glasses, required this.onAdd});

  final int glasses;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    const goal = DailyLog.waterGoalGlasses * DailyLog.mlPerGlass;
    final ml = glasses * DailyLog.mlPerGlass;
    return AppCard(
      key: const Key('breakdown-water'),
      onTap: onAdd,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Water',
                  style: text.bodyMedium?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  '$ml/$goal ml',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to add a glass',
                  style: text.labelSmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          WaterFill(progress: ml / goal, color: AppColors.water),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.report});

  final HealthReport report;

  static IconData _iconFor(String label) => switch (label) {
    'Fiber' => Icons.grass_rounded,
    'Net Carbs' => Icons.bakery_dining_outlined,
    'Sugar' => Icons.cake_outlined,
    _ => Icons.grain_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;

    Color statusColor(NutrientStatus status) => switch (status) {
      NutrientStatus.good => AppColors.success,
      NutrientStatus.low || NutrientStatus.high => AppColors.danger,
      NutrientStatus.unknown => palette.track,
    };

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: text.bodyMedium?.copyWith(color: palette.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.verdict,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              ArcGauge(
                progress: report.score / 10,
                sweepDegrees: 360,
                size: 56,
                strokeWidth: 5,
                color: AppColors.success,
                child: Text(
                  '${report.score}/10',
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final check in report.checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(_iconFor(check.label), size: 20, color: palette.muted),
                  const SizedBox(width: 12),
                  Expanded(child: Text(check.label, style: text.bodyLarge)),
                  Text(
                    check.unit == 'mg'
                        ? '${check.value.round()}mg'
                        : '${compactNumber(check.value)}g',
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    key: ValueKey('status-${check.label}-${check.status.name}'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor(check.status),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
