import 'dart:typed_data';

import '../../drinks/domain/drink.dart';

class DrinkRecognitionResult {
  DrinkRecognitionResult({
    required this.photoBytes,
    required Iterable<Drink> candidates,
  }) : candidates = List.unmodifiable(candidates.take(3));

  final Uint8List photoBytes;
  final List<Drink> candidates;
}

abstract interface class DrinkRecognitionService {
  Future<List<Drink>> identify(Uint8List photoBytes);
}

class DrinkRecognitionException implements Exception {
  const DrinkRecognitionException(this.message);

  final String message;

  @override
  String toString() => message;
}
