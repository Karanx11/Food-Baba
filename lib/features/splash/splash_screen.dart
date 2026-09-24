import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/loaders/burger_loader.dart';
import '../../core/widgets/surfaces.dart';
import '../auth/presentation/auth_gate.dart';

/// Branded launch screen. Shows the burger loader for [minimumDuration], then
/// fades into the navigation shell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minimumDuration = const Duration(milliseconds: 1800),
  });

  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimumDuration, _enterApp);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        // Custom routes skip the theme's transitions, so add the background here.
        pageBuilder: (_, _, _) => const AppBackground(child: AuthGate()),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BurgerLoader(size: 140),
            const SizedBox(height: 20),
            Text(
              'Food Baba',
              style: text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Snap. Track. Thrive.',
              style: text.bodyMedium?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
