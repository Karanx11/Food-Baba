import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/core/food_emoji.dart';

void main() {
  test('matches whole-word prefixes, first rule wins', () {
    expect(foodEmoji('Masala chai (milk, sugar)'), '🍵'); // not curry
    expect(foodEmoji('Steamed rice'), '🍚'); // "tea" inside a word is ignored
    expect(foodEmoji('Dal tadka'), '🍛');
    expect(foodEmoji('Masala dosa'), '🥞');
    expect(foodEmoji('Peanut butter'), '🥜');
    expect(foodEmoji('Sweet potato (boiled)'), '🥔');
    expect(foodEmoji('Cheese pizza'), '🍕');
    expect(foodEmoji('Omelette'), '🥚');
    expect(foodEmoji('Roasted peanuts'), '🥜');
  });

  test('unknown foods get a plate', () {
    expect(foodEmoji('Quinoa'), '🍽️');
    expect(foodEmoji(''), '🍽️');
  });
}
