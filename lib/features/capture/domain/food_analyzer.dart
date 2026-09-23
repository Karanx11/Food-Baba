import 'dart:typed_data';

import 'detected_food.dart';

/// Identifies the foods in a photo and estimates their nutrition.
abstract interface class FoodAnalyzer {
  /// True for a stand-in that returns sample data rather than real analysis,
  /// so the UI can say so.
  bool get isDemo;

  /// Analyzes [bytes] (a JPEG or PNG named by [mimeType]) and returns the
  /// foods found. Throws [AnalyzerException] on failure.
  Future<List<DetectedFood>> analyze(Uint8List bytes, String mimeType);
}

/// A readable failure the capture flow can show to the user.
class AnalyzerException implements Exception {
  const AnalyzerException(this.message);

  final String message;

  @override
  String toString() => message;
}
