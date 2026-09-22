/// Biological sex, used by the BMR formula.
enum Sex {
  male('Male'),
  female('Female');

  const Sex(this.label);

  final String label;
}

/// Activity multipliers applied to BMR to estimate daily energy expenditure.
enum ActivityLevel {
  sedentary(1.2, 'Sedentary', 'Desk job, little or no exercise'),
  light(1.375, 'Lightly active', 'Light exercise 1–3 days a week'),
  moderate(1.55, 'Moderately active', 'Moderate exercise 3–5 days a week'),
  active(1.725, 'Very active', 'Hard exercise 6–7 days a week'),
  athlete(1.9, 'Athlete', 'Very hard exercise or a physical job');

  const ActivityLevel(this.multiplier, this.label, this.description);

  final double multiplier;
  final String label;
  final String description;
}

/// Weight goal, expressed as a daily calorie adjustment on top of TDEE.
enum Goal {
  lose(-500, 'Lose', 'About 0.5 kg a week'),
  maintain(0, 'Maintain', 'Hold your current weight'),
  gain(300, 'Gain', 'Lean muscle gain');

  const Goal(this.calorieDelta, this.label, this.description);

  final int calorieDelta;
  final String label;
  final String description;
}

/// Accepted input ranges for the profile form.
abstract final class ProfileLimits {
  static const int minAge = 13;
  static const int maxAge = 100;
  static const double minHeightCm = 100;
  static const double maxHeightCm = 250;
  static const double minWeightKg = 25;
  static const double maxWeightKg = 300;
}

/// What we know about the user; the input to target calculation.
class UserProfile {
  const UserProfile({
    this.name = '',
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
  });

  final String name;
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;

  UserProfile copyWith({
    String? name,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    Goal? goal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
    );
  }

  Map<String, Object?> toJson() => {
    'name': name,
    'sex': sex.name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'activity': activity.name,
    'goal': goal.name,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      sex: Sex.values.byName(json['sex'] as String),
      age: (json['age'] as num).toInt(),
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      activity: ActivityLevel.values.byName(json['activity'] as String),
      goal: Goal.values.byName(json['goal'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.name == name &&
      other.sex == sex &&
      other.age == age &&
      other.heightCm == heightCm &&
      other.weightKg == weightKg &&
      other.activity == activity &&
      other.goal == goal;

  @override
  int get hashCode =>
      Object.hash(name, sex, age, heightCm, weightKg, activity, goal);

  @override
  String toString() =>
      'UserProfile($name, ${sex.name}, $age y, $heightCm cm, $weightKg kg, '
      '${activity.name}, ${goal.name})';
}
