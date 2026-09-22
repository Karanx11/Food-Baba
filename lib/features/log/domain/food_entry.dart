import 'dart:math';

import 'nutrition.dart';

enum MealType {
  breakfast('Breakfast'),
  lunch('Lunch'),
  dinner('Dinner'),
  snack('Snacks');

  const MealType(this.label);

  final String label;

  /// Best-guess meal for an hour of the day (0-23).
  static MealType forHour(int hour) {
    if (hour >= 5 && hour < 11) return breakfast;
    if (hour >= 11 && hour < 16) return lunch;
    if (hour >= 16 && hour < 22) return dinner;
    return snack;
  }
}

/// Where an entry's numbers came from.
enum FoodSource { manual, photo, barcode, label, search }

/// One logged food: nutrition per serving times how many servings.
class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.dayKey,
    required this.meal,
    required this.name,
    this.servingLabel = '1 serving',
    this.servings = 1,
    required this.perServing,
    this.source = FoodSource.manual,
    required this.createdAt,
  });

  final String id;
  final String dayKey;
  final MealType meal;
  final String name;

  /// Human description of one serving, e.g. "1 cup" or "100 g".
  final String servingLabel;
  final double servings;
  final Nutrition perServing;
  final FoodSource source;
  final DateTime createdAt;

  Nutrition get total => perServing * servings;

  /// Time-ordered, collision-resistant id without an extra dependency.
  static String newId(DateTime now, Random random) =>
      '${now.microsecondsSinceEpoch.toRadixString(36)}-'
      '${random.nextInt(0x7fffffff).toRadixString(36)}';

  FoodEntry copyWith({
    String? id,
    String? dayKey,
    MealType? meal,
    String? name,
    String? servingLabel,
    double? servings,
    Nutrition? perServing,
    FoodSource? source,
    DateTime? createdAt,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      meal: meal ?? this.meal,
      name: name ?? this.name,
      servingLabel: servingLabel ?? this.servingLabel,
      servings: servings ?? this.servings,
      perServing: perServing ?? this.perServing,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'dayKey': dayKey,
    'meal': meal.name,
    'name': name,
    'servingLabel': servingLabel,
    'servings': servings,
    'perServing': perServing.toJson(),
    'source': source.name,
    'createdAtMs': createdAt.millisecondsSinceEpoch,
  };

  factory FoodEntry.fromJson(Map<String, Object?> json) => FoodEntry(
    id: json['id'] as String,
    dayKey: json['dayKey'] as String,
    meal: MealType.values.byName(json['meal'] as String),
    name: json['name'] as String,
    servingLabel: json['servingLabel'] as String? ?? '1 serving',
    servings: (json['servings'] as num?)?.toDouble() ?? 1,
    perServing: Nutrition.fromJson(
      (json['perServing'] as Map?)?.cast<String, Object?>() ?? const {},
    ),
    source: FoodSource.values.byName(json['source'] as String? ?? 'manual'),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['createdAtMs'] as num).toInt(),
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is FoodEntry &&
      other.id == id &&
      other.dayKey == dayKey &&
      other.meal == meal &&
      other.name == name &&
      other.servingLabel == servingLabel &&
      other.servings == servings &&
      other.perServing == perServing &&
      other.source == source &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    dayKey,
    meal,
    name,
    servingLabel,
    servings,
    perServing,
    source,
    createdAt,
  );

  @override
  String toString() => 'FoodEntry($name, ${meal.name}, $dayKey, x$servings)';
}
