import 'dart:typed_data';

import '../../drinks/data/drink_catalog.dart';
import '../../drinks/domain/drink.dart';
import '../domain/drink_recognition.dart';

class DemoDrinkRecognitionService implements DrinkRecognitionService {
  const DemoDrinkRecognitionService({
    this.latency = const Duration(milliseconds: 900),
  });

  final Duration latency;

  @override
  Future<List<Drink>> identify(Uint8List photoBytes) async {
    if (photoBytes.isEmpty) {
      throw const DrinkRecognitionException(
        'Foto kosong. Ambil ulang atau pilih gambar lain.',
      );
    }

    if (latency > Duration.zero) await Future<void>.delayed(latency);

    // Demo adapter. Replace this implementation with the recognition API;
    // the scan and confirmation flow can keep using the same contract.
    return const [
      DrinkCatalog.kopiSusuKalengNescafe,
      DrinkCatalog.esKopiSusuGulaAren,
      DrinkCatalog.bobaMilkTea,
    ];
  }
}
