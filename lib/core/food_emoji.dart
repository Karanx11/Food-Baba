/// An emoji for a logged food's name, used as its thumbnail until real food
/// photos exist. Matches whole-word prefixes, first rule wins.
String foodEmoji(String name) {
  final words =
      ' ${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()}';
  for (final (keys, emoji) in _rules) {
    if (keys.any((k) => words.contains(' $k'))) return emoji;
  }
  return '🍽️';
}

const _rules = <(List<String>, String)>[
  // Drinks first, so "masala chai" is tea rather than curry.
  (['chai', 'tea'], '🍵'),
  (['coffee', 'latte', 'espresso', 'americano'], '☕'),
  (['orange juice', 'juice'], '🧃'),
  (['cola', 'soda', 'soft drink'], '🥤'),
  (['coconut'], '🥥'),
  (
    [
      'lassi',
      'milk',
      'curd',
      'dahi',
      'yogurt',
      'yoghurt',
      'buttermilk',
      'chaas',
    ],
    '🥛',
  ),
  (['egg', 'omelet', 'anda'], '🥚'),
  (
    ['biryani', 'biriyani', 'pulao', 'pulav', 'khichdi', 'rice', 'chawal'],
    '🍚',
  ),
  (['roti', 'chapati', 'paratha', 'parantha', 'naan', 'phulka'], '🫓'),
  (['dosa', 'idli', 'idly', 'uttapam'], '🥞'),
  (
    ['poha', 'upma', 'oats', 'oatmeal', 'cornflakes', 'cereal', 'porridge'],
    '🥣',
  ),
  (['pasta', 'noodle', 'maggi', 'spaghetti', 'ramen'], '🍝'),
  (['pizza'], '🍕'),
  (['burger'], '🍔'),
  (['fries', 'french fries'], '🍟'),
  (['sweet potato', 'potato', 'aloo'], '🥔'),
  (['chicken', 'murgh'], '🍗'),
  (['fish', 'rohu', 'tilapia'], '🐟'),
  (
    [
      'dal',
      'daal',
      'sambar',
      'sambhar',
      'curry',
      'chole',
      'rajma',
      'masala',
      'sabzi',
      'paneer',
      'palak',
    ],
    '🍛',
  ),
  (['salad', 'sprout', 'kachumber'], '🥗'),
  (['bread', 'toast'], '🍞'),
  (['banana', 'kela'], '🍌'),
  (['apple'], '🍎'),
  (['mango', 'aam'], '🥭'),
  (['orange', 'santra'], '🍊'),
  (['grape', 'angoor'], '🍇'),
  (['watermelon'], '🍉'),
  (['papaya'], '🍈'),
  (['cheese'], '🧀'),
  (['chocolate'], '🍫'),
  (['biscuit', 'cookie'], '🍪'),
  (['gulab', 'jamun', 'kheer', 'halwa', 'sweet'], '🍮'),
  (['samosa', 'pakora', 'pakoda', 'bhajiya'], '🥟'),
  (['chips', 'wafer', 'crisps'], '🥔'),
  (['almond', 'badam', 'peanut', 'groundnut', 'nut', 'cashew'], '🥜'),
  (['ghee', 'butter'], '🧈'),
  (['tofu', 'soya', 'soy'], '🫘'),
];
