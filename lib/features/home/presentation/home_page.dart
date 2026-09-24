import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../app/theme_mode.dart';
import '../../../core/dates.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/loaders/burger_loader.dart';
import '../../../core/widgets/surfaces.dart';
import '../../food_search/presentation/food_search_page.dart';
import '../../insights/presentation/daily_breakdown_page.dart';
import '../../log/application/log_providers.dart';
import '../../log/domain/daily_log.dart';
import '../../log/domain/food_entry.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/presentation/profile_form_page.dart';
import '../../shell/shell_tab_provider.dart';
import '../../streak/presentation/streak_card.dart';
import 'meal_card.dart';
import 'today_goal_card.dart';
import 'week_strip.dart';

/// Home: greeting, week strip, the selected day's goal and its meals.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(ref.watch(clockProvider)());
    final selected = ref.watch(selectedDayProvider);
    final dayKey = dayKeyOf(selected);
    final isToday = selected == today;
    final entriesAsync = ref.watch(dayEntriesProvider(dayKey));
    final entries = entriesAsync.value ?? const <FoodEntry>[];
    // Until the day has loaded, zeros would read as "nothing eaten".
    final loading = !entriesAsync.hasValue;
    final window = WeekStrip.windowFor(today);
    final logged =
        ref
            .watch(
              loggedDaysProvider((
                dayKeyOf(window.first),
                dayKeyOf(window.last),
              )),
            )
            .value ??
        const <String>{};
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final targets = ref.watch(targetsProvider);
    final log = DailyLog(dayKey: dayKey, entries: entries);
    final text = Theme.of(context).textTheme;

    void openLog() => ref.read(shellTabProvider.notifier).select(ShellTabs.log);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Clear the floating navigation bar.
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            96 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _Header(
              name: profile?.name ?? '',
              onProfile: () =>
                  ref.read(shellTabProvider.notifier).select(ShellTabs.profile),
              onToggleTheme: () => ref
                  .read(themeModeProvider.notifier)
                  .toggle(Theme.of(context).brightness),
            ),
            const SizedBox(height: 18),
            WeekStrip(
              today: today,
              selected: selected,
              loggedDays: logged,
              onSelect: ref.read(selectedDayProvider.notifier).select,
            ),
            const SizedBox(height: 16),
            if (profileAsync.hasValue && profile == null) ...[
              const _SetupNudge(),
              const SizedBox(height: 8),
            ],
            const StreakCard(),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: BurgerLoader(size: 72)),
              )
            else ...[
              TodayGoalCard(
                totals: log.totals,
                targets: targets,
                isToday: isToday,
                onTap: () =>
                    Navigator.of(context).push(DailyBreakdownPage.route()),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  isToday ? "Today's Meals" : 'Meals on ${shortDate(selected)}',
                  style: text.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              for (final meal in MealType.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: MealCard(
                    meal: meal,
                    entries: log.entriesFor(meal),
                    calories: log.totalsFor(meal).calories.round(),
                    onOpen: openLog,
                    onAdd: () => Navigator.of(context)
                        .push(FoodSearchPage.route(dayKey: dayKey, meal: meal)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.onProfile,
    required this.onToggleTheme,
  });

  final String name;
  final VoidCallback onProfile;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Welcome Back 👋' : 'Welcome back, $name 👋',
                style: text.bodyMedium?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 2),
              // Shrinks rather than wraps next to the three round buttons.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Stay On Track Today', style: text.headlineSmall),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween(begin: 0.75, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: CircleIconButton(
            key: ValueKey('theme-toggle-$isDark'),
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            size: 40,
            onPressed: onToggleTheme,
          ),
        ),
        const SizedBox(width: 8),
        CircleIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Reminders',
          size: 40,
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminders arrive in a later step.')),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Open profile',
          child: GestureDetector(
            onTap: onProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, AppColors.carbs],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: palette.card, width: 2),
              ),
              alignment: Alignment.center,
              child: name.isEmpty
                  ? const Icon(Icons.person_rounded, color: Colors.white)
                  : Text(
                      name.substring(0, 1).toUpperCase(),
                      style: text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupNudge extends StatelessWidget {
  const _SetupNudge();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: Color.alphaBlend(
        AppColors.soft(primary, Theme.of(context).brightness),
        palette.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set your daily targets', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Tell us about yourself to unlock calorie and macro goals.',
                  style: text.bodySmall?.copyWith(color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).push(ProfileFormPage.route()),
            child: const Text('Set up profile'),
          ),
        ],
      ),
    );
  }
}
