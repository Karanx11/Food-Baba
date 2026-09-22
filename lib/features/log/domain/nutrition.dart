/// Nutrient amounts. Calories in kcal, macros in grams, sodium in mg.
class Nutrition {
  const Nutrition({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.sugarG = 0,
    this.fiberG = 0,
    this.sodiumMg = 0,
  });

  static const Nutrition zero = Nutrition();

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double sugarG;
  final double fiberG;
  final double sodiumMg;

  Nutrition operator +(Nutrition o) => Nutrition(
    calories: calories + o.calories,
    proteinG: proteinG + o.proteinG,
    carbsG: carbsG + o.carbsG,
    fatG: fatG + o.fatG,
    sugarG: sugarG + o.sugarG,
    fiberG: fiberG + o.fiberG,
    sodiumMg: sodiumMg + o.sodiumMg,
  );

  Nutrition operator *(double k) => Nutrition(
    calories: calories * k,
    proteinG: proteinG * k,
    carbsG: carbsG * k,
    fatG: fatG * k,
    sugarG: sugarG * k,
    fiberG: fiberG * k,
    sodiumMg: sodiumMg * k,
  );

  Map<String, Object?> toJson() => {
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'sugarG': sugarG,
    'fiberG': fiberG,
    'sodiumMg': sodiumMg,
  };

  factory Nutrition.fromJson(Map<String, Object?> json) => Nutrition(
    calories: _num(json['calories']),
    proteinG: _num(json['proteinG']),
    carbsG: _num(json['carbsG']),
    fatG: _num(json['fatG']),
    sugarG: _num(json['sugarG']),
    fiberG: _num(json['fiberG']),
    sodiumMg: _num(json['sodiumMg']),
  );

  static double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

  @override
  bool operator ==(Object other) =>
      other is Nutrition &&
      other.calories == calories &&
      other.proteinG == proteinG &&
      other.carbsG == carbsG &&
      other.fatG == fatG &&
      other.sugarG == sugarG &&
      other.fiberG == fiberG &&
      other.sodiumMg == sodiumMg;

  @override
  int get hashCode => Object.hash(
    calories,
    proteinG,
    carbsG,
    fatG,
    sugarG,
    fiberG,
    sodiumMg,
  );

  @override
  String toString() =>
      'Nutrition($calories kcal, P $proteinG, C $carbsG, F $fatG)';
}
