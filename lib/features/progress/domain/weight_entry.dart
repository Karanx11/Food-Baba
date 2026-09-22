/// Body weight recorded on one calendar day (one entry per day).
class WeightEntry {
  const WeightEntry({required this.dayKey, required this.kg});

  final String dayKey;
  final double kg;

  @override
  bool operator ==(Object other) =>
      other is WeightEntry && other.dayKey == dayKey && other.kg == kg;

  @override
  int get hashCode => Object.hash(dayKey, kg);

  @override
  String toString() => 'WeightEntry($dayKey, $kg kg)';
}
