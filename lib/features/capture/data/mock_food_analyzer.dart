import 'dart:typed_data';

import '../../log/domain/nutrition.dart';
import '../domain/detected_food.dart';
import '../domain/food_analyzer.dart';

/// Stand-in analyzer used when no backend is configured. It returns a fixed
/// set of foods after a short delay, so the capture flow is fully usable
/// without an API key. The UI labels its results as a demo.
class MockFoodAnalyzer implements FoodAnalyzer {
  const MockFoodAnalyzer({this.delay = const Duration(milliseconds: 1400)});

  final Duration delay;

  @override
  bool get isDemo => true;

  @override
  Future<List<DetectedFood>> analyze(Uint8List bytes, String mimeType) async {
    await Future<void>.delayed(delay);
    return const [
      DetectedFood(
        name: 'Dal tadka',
        servingLabel: '1 katori',
        gramsPerServing: 150,
        servings: 1,
        perServing: Nutrition(
          calories: 188,
          proteinG: 9,
          carbsG: 22.5,
          fatG: 6.8,
          sugarG: 1.5,
          fiberG: 5.3,
          sodiumMg: 450,
        ),
        confidence: 0.82,
        notes: 'Good source of plant protein and fibre.',
      ),
      DetectedFood(
        name: 'Steamed rice',
        servingLabel: '1 katori',
        gramsPerServing: 150,
        servings: 1.5,
        perServing: Nutrition(
          calories: 195,
          proteinG: 4.1,
          carbsG: 42.3,
          fatG: 0.5,
          sugarG: 0.2,
          fiberG: 0.6,
          sodiumMg: 2,
        ),
        confidence: 0.88,
        notes: 'Mostly carbs; pair with protein and veg.',
      ),
      DetectedFood(
        name: 'Roti',
        servingLabel: '1 roti',
        gramsPerServing: 40,
        servings: 2,
        perServing: Nutrition(
          calories: 119,
          proteinG: 3.6,
          carbsG: 18.8,
          fatG: 3.2,
          sugarG: 0.6,
          fiberG: 2,
          sodiumMg: 120,
        ),
        confidence: 0.7,
        notes: 'Whole-wheat; provides fibre and B vitamins.',
      ),
    ];
  }
}
