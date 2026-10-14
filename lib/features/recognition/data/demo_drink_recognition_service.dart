import 'dart:typed_data';

import '../../drinks/data/drink_catalog.dart';
import '../domain/drink_recognition.dart';

class DemoDrinkRecognitionService implements DrinkRecognitionService {
  const DemoDrinkRecognitionService({
    this.latency = const Duration(milliseconds: 900),
  });

  final Duration latency;

  @override
  Future<List<DrinkRecognitionCandidate>> identify(Uint8List photoBytes) async {
    if (photoBytes.isEmpty) {
      throw const DrinkRecognitionException(
        'Foto kosong. Ambil ulang atau pilih gambar lain.',
      );
    }

    if (latency > Duration.zero) await Future<void>.delayed(latency);

    // Demo adapter. Replace this implementation with the recognition API;
    // the scan and confirmation flow can keep using the same contract.
    return const [
      DrinkRecognitionCandidate(
        drink: DrinkCatalog.kopiSusuKalengNescafe,
        confidence: 0.92,
      ),
      DrinkRecognitionCandidate(
        drink: DrinkCatalog.esKopiSusuGulaAren,
        confidence: 0.76,
      ),
      DrinkRecognitionCandidate(
        drink: DrinkCatalog.bobaMilkTea,
        confidence: 0.63,
      ),
    ];
  }
}
