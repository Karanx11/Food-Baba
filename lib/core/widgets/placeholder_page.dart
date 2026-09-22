import 'package:flutter/material.dart';

/// Temporary page body used while a feature is not built yet.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(subtitle, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Coming soon',
              style: text.bodySmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
