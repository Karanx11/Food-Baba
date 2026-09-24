import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/core/format.dart';
import 'package:food_guruji/features/food_search/domain/food_item.dart';
import 'package:food_guruji/features/food_search/domain/food_search.dart';
import 'package:food_guruji/features/log/domain/nutrition.dart';

FoodItem _food(String id, String name, {List<String> aliases = const []}) =>
    FoodItem(
      id: id,
      name: name,
      aliases: aliases,
      category: 'Test',
      per100g: const Nutrition(calories: 100),
      servings: const [ServingOption.hundredGrams],
    );

void main() {
  final foods = [
    _food('licorice', 'Licorice'),
    _food('pulao', 'Veg pulao', aliases: ['vegetable rice']),
    _food('white-rice', 'White rice (cooked)', aliases: ['chawal']),
    _food('kheer', 'Rice kheer'),
    _food('rice', 'Rice'),
    _food('brown-rice', 'Brown rice (cooked)'),
    _food('dal', 'Dal tadka', aliases: ['toor dal', 'yellow dal']),
  ];

  List<String> ids(String query, {int limit = 30}) =>
      searchFoods(foods, query, limit: limit).map((f) => f.id).toList();

  test('normalizes case and punctuation', () {
    expect(normalizeFoodText('  Rice, WHITE (cooked)! '), 'rice white cooked');
  });

  test('ranks exact, prefix, word, alias word, then substring', () {
    expect(ids('rice'), [
      'rice', // exact
      'kheer', // name starts with "rice"
      'brown-rice', // word prefix, ties broken by shorter name
      'white-rice',
      'pulao', // alias word
      'licorice', // substring
    ]);
  });

  test('every query word must match', () {
    expect(ids('white rice'), ['white-rice']);
    expect(ids('wh ri'), ['white-rice']);
    expect(ids('brown dal'), isEmpty);
  });

  test('aliases find foods by other names', () {
    expect(ids('chawal'), ['white-rice']);
    expect(ids('toor'), ['dal']);
    expect(ids('yellow dal'), ['dal']);
  });

  test('empty or blank queries return nothing', () {
    expect(ids(''), isEmpty);
    expect(ids('   '), isEmpty);
    expect(ids('!!!'), isEmpty);
  });

  test('respects the limit', () {
    expect(ids('rice', limit: 2), ['rice', 'kheer']);
  });

  group('compactNumber', () {
    test('drops trailing zeros', () {
      expect(compactNumber(70), '70');
      expect(compactNumber(70.0), '70');
      expect(compactNumber(72.5), '72.5');
      expect(compactNumber(9.04), '9');
    });

    test('keeps quarter servings with two decimals', () {
      expect(compactNumber(1.25, decimals: 2), '1.25');
      expect(compactNumber(1.5, decimals: 2), '1.5');
      expect(compactNumber(2, decimals: 2), '2');
    });
  });
}
