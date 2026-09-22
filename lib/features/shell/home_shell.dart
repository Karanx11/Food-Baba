import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/loaders/pan_loader.dart';
import '../analyze/analyze_page.dart';
import '../home/presentation/home_page.dart';
import '../log/presentation/log_page.dart';
import '../profile/presentation/profile_page.dart';
import 'shell_tab_provider.dart';

/// Root scaffold: bottom navigation plus a "Snap" action for the camera.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const List<Widget> _pages = [
    HomePage(),
    LogPage(),
    AnalyzePage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => const _SnapPreviewSheet(),
        ),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Snap'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(shellTabProvider.notifier).select(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Analyze',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
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
              style: text.bodyMedium?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
