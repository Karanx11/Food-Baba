import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_language.dart';
import '../../../app/l10n/language_store.dart';
import '../../../core/format.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/loaders/burger_loader.dart';
import '../../../core/widgets/surfaces.dart';
import '../../../core/widgets/top_bar.dart';
import '../../auth/application/auth_providers.dart';
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
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: appTopBar(
        context,
        title: s.yourProfile,
        actions: [
          if (profile != null)
            CircleIconButton(
              icon: Icons.edit_outlined,
              tooltip: s.editProfile,
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
              '${s.couldNotLoadProfile}\n$error',
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(stringsProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Icon(Icons.person_rounded, size: 64, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          s.setUpProfile,
          style: text.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          s.setUpProfileHint,
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.outline),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).push(ProfileFormPage.route()),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(s.getStarted),
          ),
        ),
        const SizedBox(height: 24),
        const _SettingsCard(),
        const SizedBox(height: 16),
        const _AccountCard(),
      ],
    );
  }
}

/// Language picker (and room for future settings).
class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);
    final s = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 18, color: palette.muted),
              const SizedBox(width: 8),
              Text(s.languageLabel, style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<AppLanguage>(
            showSelectedIcon: false,
            segments: [
              for (final l in AppLanguage.values)
                ButtonSegment(
                  value: l,
                  label: Text(l.label, style: text.bodyMedium),
                ),
            ],
            selected: {language},
            onSelectionChanged: (selection) =>
                ref.read(languageProvider.notifier).select(selection.first),
          ),
        ],
      ),
    );
  }
}

/// Signed-in email with log out and delete-account controls.
class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.deleteConfirmTitle),
            content: Text(s.deleteConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(s.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(s.delete),
              ),
            ],
          ),
        ) ??
        false;
    // The gate swaps to signup once the account is gone.
    if (confirmed) {
      await ref.read(authControllerProvider.notifier).deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);
    final s = ref.watch(stringsProvider);
    final email = ref.watch(authControllerProvider).value?.email ?? '';

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.account, style: text.titleMedium),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: palette.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: text.bodyMedium?.copyWith(color: palette.muted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('log-out'),
            onPressed: () => ref.read(authControllerProvider.notifier).logOut(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(s.logOut),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('delete-account'),
            onPressed: () => _confirmDelete(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(s.deleteAccount),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends ConsumerWidget {
  const _ProfileSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(stringsProvider);
    final targets = TargetsCalculator.compute(profile);
    final name = profile.name.isEmpty ? s.profileNamePlaceholder : profile.name;

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
          label: Text(s.editProfile),
        ),
        const SizedBox(height: 16),
        const _SettingsCard(),
        const SizedBox(height: 16),
        const _AccountCard(),
      ],
    );
  }
}
