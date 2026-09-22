import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/loaders/burger_loader.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../application/profile_providers.dart';
import '../domain/nutrition_targets.dart';
import '../domain/user_profile.dart';
import 'profile_form_page.dart';
import 'targets_card.dart';

/// Profile tab: set-up prompt, or the saved profile with its daily targets.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileProvider);
    final profile = async.value;

    return Scaffold(
      appBar: appTopBar(
        context,
        title: 'Your Profile',
        actions: [
          if (profile != null)
            CircleIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit profile',
              size: 42,
              onPressed: () =>
                  Navigator.of(context)
                      .push(ProfileFormPage.route(initial: profile)),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: BurgerLoader(size: 72)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your profile.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (p) =>
            p == null ? const _EmptyState() : _ProfileSummary(profile: p),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text('Set up your profile', style: text.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Get calorie and macro targets tailored to you.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(ProfileFormPage.route()),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final targets = TargetsCalculator.compute(profile);
    final name = profile.name.isEmpty ? 'Your profile' : profile.name;

    return ListView(
      // Clear the FAB and the floating navigation bar.
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: profile.name.isEmpty
                      ? Icon(Icons.person_rounded, color: scheme.primary)
                      : Text(
                          profile.name.substring(0, 1).toUpperCase(),
                          style: text.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.sex.label} · ${profile.age} years · '
                        '${compactNumber(profile.heightCm)} cm · '
                        '${compactNumber(profile.weightKg)} kg',
                        style: text.bodyMedium?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.directions_run_rounded, size: 18),
              label: Text(profile.activity.label),
            ),
            Chip(
              avatar: const Icon(Icons.flag_rounded, size: 18),
              label: Text('Goal: ${profile.goal.label}'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TargetsCard(targets: targets),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context)
                  .push(ProfileFormPage.route(initial: profile)),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit profile'),
        ),
      ],
    );
  }
}
