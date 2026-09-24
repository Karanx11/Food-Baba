import 'dart:typed_data';

import 'package:food_guruji/features/capture/data/photo_source.dart';
import 'package:food_guruji/features/capture/domain/detected_food.dart';
import 'package:food_guruji/features/capture/domain/food_analyzer.dart';
import 'package:food_guruji/features/log/domain/nutrition.dart';

/// A 1x1 PNG, enough for `Image.memory` to decode in the review screen.
final kTinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
]);

/// Returns a fixed photo (or nothing, to simulate cancelling), and records
/// which origin was asked for.
class FakePhotoSource implements PhotoSource {
  FakePhotoSource({this.photo});

  /// The photo to return; null simulates the user cancelling.
  CapturedPhoto? photo;
  PhotoOrigin? lastOrigin;

  @override
  Future<CapturedPhoto?> pick(PhotoOrigin origin) async {
    lastOrigin = origin;
    return photo;
  }
}

/// Returns fixed foods, or throws, on demand. Counts its calls.
class FakeFoodAnalyzer implements FoodAnalyzer {
  FakeFoodAnalyzer({
    this.result = _defaultFoods,
    this.error,
    this.isDemo = false,
  });

  List<DetectedFood> result;
  Object? error;
  int calls = 0;

  @override
  final bool isDemo;

  @override
  Future<List<DetectedFood>> analyze(Uint8List bytes, String mimeType) async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

const _defaultFoods = <DetectedFood>[
  DetectedFood(
    name: 'Dal tadka',
    servingLabel: '1 katori',
    gramsPerServing: 150,
    servings: 1,
    perServing: Nutrition(calories: 180, proteinG: 9, carbsG: 22, fatG: 7),
    confidence: 0.8,
  ),
  DetectedFood(
    name: 'Steamed rice',
    servingLabel: '1 katori',
    gramsPerServing: 150,
    servings: 2,
    perServing: Nutrition(calories: 195, proteinG: 4, carbsG: 42, fatG: 0.5),
    confidence: 0.9,
  ),
];
