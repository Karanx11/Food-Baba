import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/surfaces.dart';
import '../domain/body_metrics.dart';

Color bmiColor(BmiCategory category) => switch (category) {
  BmiCategory.underweight => AppColors.underweight,
  BmiCategory.healthy => AppColors.success,
  BmiCategory.overweight => AppColors.overweight,
  BmiCategory.obese => AppColors.obese,
};

/// Colour scale from underweight to obese with a marker at [bmi].
class BmiBar extends StatelessWidget {
  const BmiBar({super.key, required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final position = BodyMetrics.scalePosition(bmi);
    return SizedBox(
      height: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const markerWidth = 8.0;
          final left = (constraints.maxWidth - markerWidth) * position;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.underweight,
                        AppColors.success,
                        Color(0xFFFACC15),
                        AppColors.overweight,
                        AppColors.obese,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const Key('bmi-marker'),
                left: left,
                top: 0,
                width: markerWidth,
                height: 24,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: palette.card, width: 2),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
