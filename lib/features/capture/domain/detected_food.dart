import '../../log/domain/nutrition.dart';

/// One food the analyzer found in a photo, with an estimated portion and its
/// nutrition for that portion.
class DetectedFood {
  const DetectedFood({
    required this.name,
    required this.servingLabel,
    required this.gramsPerServing,
    this.servings = 1,
    required this.perServing,
    this.confidence,
    this.notes,
  });

  final String name;

  /// Human description of one serving, e.g. "1 bowl" or "2 rotis".
  final String servingLabel;

  /// Weight of one serving in grams; used when the portion is rescaled.
  final double gramsPerServing;

  /// How many servings the analyzer estimated are on the plate.
  final double servings;

  /// Nutrition for a single serving.
  final Nutrition perServing;

  /// 0..1, if the analyzer reported how sure it was.
  final double? confidence;

  /// A short note on notable micronutrients or health facts, e.g.
  /// "High in calcium and vitamin B12". Null when the analyzer gave none.
  final String? notes;

  Nutrition get total => perServing * servings;

  DetectedFood copyWith({double? servings}) => DetectedFood(
    name: name,
    servingLabel: servingLabel,
    gramsPerServing: gramsPerServing,
    servings: servings ?? this.servings,
    perServing: perServing,
    confidence: confidence,
    notes: notes,
  );

  factory DetectedFood.fromJson(Map<String, Object?> json) {
    double toNum(Object? v) => (v as num?)?.toDouble() ?? 0;
    final grams = toNum(json['gramsPerServing']);
    return DetectedFood(
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Food',
      servingLabel: (json['servingLabel'] as String?)?.trim().isNotEmpty == true
          ? (json['servingLabel'] as String).trim()
          : '1 serving',
      gramsPerServing: grams > 0 ? grams : 100,
      servings: toNum(json['servings']) > 0 ? toNum(json['servings']) : 1,
      perServing: Nutrition(
        calories: toNum(json['calories']),
        proteinG: toNum(json['proteinG']),
        carbsG: toNum(json['carbsG']),
        fatG: toNum(json['fatG']),
        sugarG: toNum(json['sugarG']),
        fiberG: toNum(json['fiberG']),
        sodiumMg: toNum(json['sodiumMg']),
      ),
      confidence: json['confidence'] == null ? null : toNum(json['confidence']),
      notes: (json['notes'] as String?)?.trim().isNotEmpty == true
          ? (json['notes'] as String).trim()
          : null,
    );
  }

  @override
  String toString() => 'DetectedFood($name, x$servings)';
}
