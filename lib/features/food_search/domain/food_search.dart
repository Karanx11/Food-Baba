import 'food_item.dart';

/// Lower-cases and replaces anything that isn't a letter or digit with a
/// single space, so "Rice, white (cooked)" becomes "rice white cooked".
String normalizeFoodText(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Ranked search over [foods]. Best matches first:
///
/// 0. name equals the query
/// 1. name starts with the query
/// 2. every query word starts a word of the name
/// 3. an alias equals or starts with the query
/// 4. every query word starts a word of the name or an alias
/// 5. every query word appears somewhere in the name or an alias
///
/// Ties go to the shorter name, then alphabetical order.
List<FoodItem> searchFoods(
  Iterable<FoodItem> foods,
  String query, {
  int limit = 30,
}) {
  final q = normalizeFoodText(query);
  if (q.isEmpty) return const [];
  final tokens = q.split(' ');

  final scored = <(int, FoodItem)>[];
  for (final food in foods) {
    final score = _score(food, q, tokens);
    if (score != null) scored.add((score, food));
  }
  scored.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    if (byScore != 0) return byScore;
    final byLength = a.$2.name.length.compareTo(b.$2.name.length);
    if (byLength != 0) return byLength;
    return a.$2.name.compareTo(b.$2.name);
  });
  return [for (final (_, food) in scored.take(limit)) food];
}

int? _score(FoodItem food, String q, List<String> tokens) {
  final name = normalizeFoodText(food.name);
  if (name == q) return 0;
  if (name.startsWith(q)) return 1;

  final nameWords = name.split(' ');
  bool everyTokenStartsA(List<String> words) =>
      tokens.every((t) => words.any((w) => w.startsWith(t)));
  if (everyTokenStartsA(nameWords)) return 2;

  final aliases = food.aliases.map(normalizeFoodText).toList();
  if (aliases.any((a) => a.startsWith(q))) return 3;

  final allWords = [...nameWords, for (final a in aliases) ...a.split(' ')];
  if (everyTokenStartsA(allWords)) return 4;

  final haystack = [name, ...aliases].join(' ');
  if (tokens.every(haystack.contains)) return 5;
  return null;
}
