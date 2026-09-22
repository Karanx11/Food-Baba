import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/circle_icon_button.dart';
import '../../core/widgets/loaders/pan_loader.dart';
import '../../core/widgets/surfaces.dart';
import '../home/presentation/home_page.dart';
import '../log/presentation/log_page.dart';
import '../profile/presentation/profile_page.dart';
import '../progress/presentation/progress_page.dart';
import 'shell_tab_provider.dart';

/// Root scaffold: tab pages under a floating row of round buttons, with the
/// camera ("Snap") in the middle.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const List<Widget> _pages = [
    HomePage(),
    LogPage(),
    ProgressPage(),
    ProfilePage(),
  ];

  static void _openSnap(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _SnapPreviewSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    return Scaffold(
      // Pages scroll behind the buttons; they pad by MediaQuery's bottom.
      extendBody: true,
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: _BottomNav(
        index: index,
        onTab: ref.read(shellTabProvider.notifier).select,
        onSnap: () => _openSnap(context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.onTab,
    required this.onSnap,
  });

  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onSnap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    Widget tab(int tab, String tooltip, IconData icon, IconData selectedIcon) {
      final selected = index == tab;
      return CircleIconButton(
        key: Key('nav-$tab'),
        icon: selected ? selectedIcon : icon,
        tooltip: tooltip,
        size: 52,
        selected: selected,
        foreground: selected ? palette.ink : palette.muted,
        onPressed: () => onTab(tab),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          tab(ShellTabs.home, 'Home', Icons.home_outlined, Icons.home_rounded),
          tab(
            ShellTabs.log,
            'Food log',
            Icons.room_service_outlined,
            Icons.room_service_rounded,
          ),
          CircleIconButton(
            key: const Key('nav-snap'),
            icon: Icons.document_scanner_outlined,
            tooltip: 'Snap food',
            size: 52,
            foreground: palette.muted,
            onPressed: onSnap,
          ),
          tab(
            ShellTabs.analyze,
            'Progress',
            Icons.pie_chart_outline_rounded,
            Icons.pie_chart_rounded,
          ),
          tab(
            ShellTabs.profile,
            'Profile',
            Icons.person_outline_rounded,
            Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

/// Stand-in for the capture flow: previews the "analyzing" state.
class _SnapPreviewSheet extends StatelessWidget {
  const _SnapPreviewSheet();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    // Sheets get loose width constraints; fill the width like a real sheet.
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        top: false,
        // Scrollable so the sheet never overflows on short screens.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PanLoader(size: 140),
              const SizedBox(height: 8),
              Text('Analyzing your food…', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Camera capture arrives in a later step.',
                style: text.bodyMedium?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
