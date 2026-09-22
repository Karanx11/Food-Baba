import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../domain/food_item.dart';

/// Pick a serving size and how many of it. Reused later to adjust the
/// portion the AI estimates from a photo.
class PortionSelector extends StatelessWidget {
  const PortionSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.quantity,
    required this.onServingChanged,
    required this.onQuantityChanged,
  });

  static const double minQuantity = 0.25;
  static const double maxQuantity = 5;
  static const double step = 0.25;

  /// Snaps to the nearest [step] inside the allowed range.
  static double snap(double quantity) =>
      ((quantity / step).round() * step).clamp(minQuantity, maxQuantity);

  final List<ServingOption> options;
  final ServingOption selected;
  final double quantity;
  final ValueChanged<ServingOption> onServingChanged;
  final ValueChanged<double> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final amount = compactNumber(quantity, decimals: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Serving size', style: text.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option.description),
                selected: option == selected,
                onSelected: (_) => onServingChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Quantity', style: text.titleSmall),
            const Spacer(),
            Text(
              '$amount × ${selected.label}',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              key: const Key('portion-minus'),
              tooltip: 'Less',
              onPressed: quantity > minQuantity
                  ? () => onQuantityChanged(snap(quantity - step))
                  : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: Slider(
                value: quantity,
                min: minQuantity,
                max: maxQuantity,
                divisions: ((maxQuantity - minQuantity) / step).round(),
                label: amount,
                onChanged: (v) => onQuantityChanged(snap(v)),
              ),
            ),
            IconButton.filledTonal(
              key: const Key('portion-plus'),
              tooltip: 'More',
              onPressed: quantity < maxQuantity
                  ? () => onQuantityChanged(snap(quantity + step))
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        Text(
          '${compactNumber(quantity * selected.grams)} g in total',
          style: text.bodySmall?.copyWith(color: scheme.outline),
        ),
      ],
    );
  }
}
