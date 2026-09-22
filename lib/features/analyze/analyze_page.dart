import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

class AnalyzePage extends StatelessWidget {
  const AnalyzePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Insights',
      icon: Icons.insights_rounded,
      subtitle: 'Trends and insights',
    );
  }
}
