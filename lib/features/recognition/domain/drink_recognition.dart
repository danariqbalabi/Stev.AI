import 'dart:typed_data';

import '../../drinks/domain/drink.dart';

class DrinkRecognitionResult {
  DrinkRecognitionResult({
    required this.photoBytes,
    required Iterable<DrinkRecognitionCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates.take(3));

  final Uint8List photoBytes;
  final List<DrinkRecognitionCandidate> candidates;
}

class DrinkRecognitionCandidate {
  const DrinkRecognitionCandidate({
    required this.drink,
    required this.confidence,
  }) : assert(confidence >= 0 && confidence <= 1);

  final Drink drink;
  final double confidence;

  int get confidencePercent => (confidence * 100).round();
}

abstract interface class DrinkRecognitionService {
  Future<List<DrinkRecognitionCandidate>> identify(Uint8List photoBytes);
}

class DrinkRecognitionException implements Exception {
  const DrinkRecognitionException(this.message);

  final String message;

  @override
  String toString() => message;
}
