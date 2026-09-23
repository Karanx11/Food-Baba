import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/detected_food.dart';
import '../domain/food_analyzer.dart';

/// Sends the photo to the Food Baba backend, which calls the AI model with
/// the API key kept server-side. See `backend/README.md`.
class BackendFoodAnalyzer implements FoodAnalyzer {
  BackendFoodAnalyzer({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  /// Backend origin, e.g. `https://food-baba-api.onrender.com`.
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  @override
  bool get isDemo => false;

  @override
  Future<List<DetectedFood>> analyze(Uint8List bytes, String mimeType) async {
    final uri = Uri.parse('$baseUrl/analyze');
    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mimeType': mimeType,
              'imageBase64': base64Encode(bytes),
            }),
          )
          .timeout(timeout);
    } on Object {
      throw const AnalyzerException(
        "Couldn't reach the server. Check your connection and try again.",
      );
    }

    if (response.statusCode != 200) {
      throw AnalyzerException(_errorFor(response));
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on Object {
      throw const AnalyzerException('The server sent an unexpected response.');
    }
    final foods = (decoded is Map ? decoded['foods'] : null) as List?;
    if (foods == null) {
      throw const AnalyzerException('The server sent an unexpected response.');
    }
    return [
      for (final f in foods)
        DetectedFood.fromJson((f as Map).cast<String, Object?>()),
    ];
  }

  String _errorFor(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final message = body is Map ? body['error'] : null;
      if (message is String && message.isNotEmpty) return message;
    } on Object {
      // Fall through to a generic message.
    }
    if (response.statusCode == 422) {
      return "The photo didn't look like food. Try another shot.";
    }
    return 'The server had a problem (${response.statusCode}). Try again.';
  }

  void dispose() => _client.close();
}
