import 'dart:convert';

import '../../../core/format.dart';
import '../../log/domain/nutrition.dart';

/// A named portion of a food, e.g. "1 katori" = 150 g.
class ServingOption {
  const ServingOption({required this.label, required this.grams});

  static const ServingOption hundredGrams = ServingOption(
    label: '100 g',
    grams: 100,
  );

  final String label;
  final double grams;

  /// e.g. "1 katori (150 g)", or just "100 g" when the label already says it.
  String get description {
    final weight = '${compactNumber(grams)} g';
    return label == weight ? label : '$label ($weight)';
  }

  factory ServingOption.fromJson(Map<String, Object?> json) => ServingOption(
    label: json['label'] as String,
    grams: (json['grams'] as num).toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      other is ServingOption && other.label == label && other.grams == grams;

  @override
  int get hashCode => Object.hash(label, grams);

  @override
  String toString() => 'ServingOption($description)';
}

/// A food from the catalog, with nutrition per 100 g as eaten.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.category,
    required this.per100g,
    required this.servings,
  });

  final String id;
  final String name;

  /// Other names people search for, e.g. "chawal" for rice.
  final List<String> aliases;
  final String category;
  final Nutrition per100g;

  /// Serving options; the first one is the default.
  final List<ServingOption> servings;

  Nutrition nutritionFor(double grams) => per100g * (grams / 100);

  /// Parses one catalog entry. Always offers a "100 g" serving at the end.
  factory FoodItem.fromJson(Map<String, Object?> json) {
    final servings = [
      for (final s in (json['servings'] as List? ?? const []))
        ServingOption.fromJson((s as Map).cast<String, Object?>()),
    ];
    if (!servings.contains(ServingOption.hundredGrams)) {
      servings.add(ServingOption.hundredGrams);
    }
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: [
        for (final a in (json['aliases'] as List? ?? const [])) a as String,
      ],
      category: json['category'] as String,
      per100g: Nutrition.fromJson(
        (json['per100g'] as Map).cast<String, Object?>(),
      ),
      servings: List.unmodifiable(servings),
    );
  }

  @override
  String toString() => 'FoodItem($id)';
}

/// Parses the bundled catalog file (`{"foods": [...]}`).
List<FoodItem> parseFoodCatalog(String source) {
  final json = jsonDecode(source) as Map<String, Object?>;
  return List.unmodifiable([
    for (final f in (json['foods'] as List? ?? const []))
      FoodItem.fromJson((f as Map).cast<String, Object?>()),
  ]);
}
