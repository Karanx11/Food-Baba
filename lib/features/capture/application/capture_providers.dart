import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backend_food_analyzer.dart';
import '../data/mock_food_analyzer.dart';
import '../data/photo_source.dart';
import '../domain/food_analyzer.dart';

/// Backend origin, passed at build time:
/// `flutter run --dart-define=FOOD_BABA_API=https://your-backend`.
/// Empty means no backend, so the demo analyzer is used.
const String kBackendBaseUrl = String.fromEnvironment('FOOD_BABA_API');

/// Where photos come from. Tests override this with a fake source.
final photoSourceProvider = Provider<PhotoSource>(
  (_) => ImagePickerPhotoSource(),
);

/// The AI analyzer: the real backend when one is configured, otherwise the
/// demo. Tests override this.
final foodAnalyzerProvider = Provider<FoodAnalyzer>((ref) {
  if (kBackendBaseUrl.isEmpty) return const MockFoodAnalyzer();
  final analyzer = BackendFoodAnalyzer(baseUrl: kBackendBaseUrl);
  ref.onDispose(analyzer.dispose);
  return analyzer;
});
