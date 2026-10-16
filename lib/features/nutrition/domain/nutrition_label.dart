import 'dart:typed_data';

import '../../drinks/domain/drink.dart';

enum NutritionBasis {
  perServing('per_serving', 'Per sajian'),
  per100Ml('per_100ml', 'Per 100 ml'),
  perPackage('per_package', 'Per kemasan');

  const NutritionBasis(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class NutritionLabel {
  const NutritionLabel({
    required this.sugarGrams,
    required this.basis,
    required this.sugarText,
    required this.basisText,
    required this.confidence,
    this.productName,
    this.servingMl,
    this.servingsPerPackage,
    this.packageMl,
  });

  final String? productName;
  final double sugarGrams;
  final NutritionBasis basis;
  final double? servingMl;
  final double? servingsPerPackage;
  final double? packageMl;
  final String sugarText;
  final String basisText;
  final double confidence;

  factory NutritionLabel.fromJson(Map<String, dynamic> json) {
    final basis = NutritionBasis.values
        .where((value) => value.apiValue == json['basis'])
        .firstOrNull;
    final sugar = _number(json['sugarGrams']);
    final confidence = _number(json['confidence']);
    final sugarText = json['sugarText'];
    final basisText = json['basisText'];
    if (basis == null ||
        sugar == null ||
        sugar < 0 ||
        sugar > (basis == NutritionBasis.per100Ml ? 100 : 1000) ||
        confidence == null ||
        confidence < 0.75 ||
        confidence > 1 ||
        sugarText is! String ||
        sugarText.trim().isEmpty ||
        sugarText.length > 400 ||
        basisText is! String ||
        basisText.trim().isEmpty ||
        basisText.length > 400) {
      throw const NutritionLabelException(
        'Hasil pembacaan label tidak lengkap. Foto ulang atau isi manual.',
      );
    }
    final name = json['productName'];
    return NutritionLabel(
      productName: name is String
          ? name.substring(0, name.length.clamp(0, 120))
          : null,
      sugarGrams: sugar,
      basis: basis,
      servingMl: _optional(json['servingMl'], 10000),
      servingsPerPackage: _optional(json['servingsPerPackage'], 100),
      packageMl: _optional(json['packageMl'], 10000),
      sugarText: sugarText,
      basisText: basisText,
      confidence: confidence,
    );
  }

  static double? _number(Object? raw) =>
      raw is num && raw.isFinite ? raw.toDouble() : null;
  static double? _optional(Object? raw, double max) {
    if (raw == null) return null;
    final value = _number(raw);
    if (value == null || value <= 0 || value > max) {
      throw const NutritionLabelException(
        'Takaran saji tidak valid. Foto ulang label.',
      );
    }
    return value;
  }
}

/// Pure calculation shared by confirmation and logging; AI never supplies totals.
double nutritionSugarFor({
  required double sugarGrams,
  required NutritionBasis basis,
  required double consumedFraction,
  double? servingsPerPackage,
  double? packageMl,
  double? servingMl,
}) {
  if (!sugarGrams.isFinite ||
      sugarGrams < 0 ||
      sugarGrams > (basis == NutritionBasis.per100Ml ? 100 : 1000) ||
      !consumedFraction.isFinite ||
      consumedFraction <= 0 ||
      consumedFraction > 1) {
    throw const FormatException(
      'Angka gula atau bagian yang diminum tidak valid.',
    );
  }
  final double multiplier;
  switch (basis) {
    case NutritionBasis.perServing:
      if (packageMl != null || servingMl != null) {
        if (packageMl == null ||
            servingMl == null ||
            !packageMl.isFinite ||
            !servingMl.isFinite ||
            packageMl <= 0 ||
            packageMl > 10000 ||
            servingMl <= 0 ||
            servingMl > 10000) {
          throw const FormatException(
            'Isi volume kemasan dan takaran saji dalam ml.',
          );
        }
        multiplier = packageMl / servingMl;
        break;
      }
      if (servingsPerPackage == null ||
          !servingsPerPackage.isFinite ||
          servingsPerPackage <= 0 ||
          servingsPerPackage > 100) {
        throw const FormatException('Isi jumlah sajian per kemasan.');
      }
      multiplier = servingsPerPackage;
    case NutritionBasis.per100Ml:
      if (packageMl == null ||
          !packageMl.isFinite ||
          packageMl <= 0 ||
          packageMl > 10000) {
        throw const FormatException('Isi volume kemasan dalam ml.');
      }
      multiplier = packageMl / 100;
    case NutritionBasis.perPackage:
      multiplier = 1;
  }
  return sugarGrams * multiplier * consumedFraction;
}

bool nutritionVolumeMismatch({
  double? servingMl,
  double? servingsPerPackage,
  double? packageMl,
}) {
  if (servingMl == null ||
      servingsPerPackage == null ||
      packageMl == null ||
      !servingMl.isFinite ||
      !servingsPerPackage.isFinite ||
      !packageMl.isFinite ||
      servingMl <= 0 ||
      servingsPerPackage <= 0 ||
      packageMl <= 0) {
    return false;
  }
  return (servingMl * servingsPerPackage - packageMl).abs() > 0.5;
}

DrinkSelection nutritionSelection({
  required String name,
  required String identity,
  required double grams,
  bool fromPhoto = true,
}) => DrinkSelection(
  drink: Drink(
    id: 'label-$identity',
    name: name.trim(),
    grams: grams,
    estimated: true,
    category: DrinkCategory.packaged,
    kind: DrinkKind.custom,
    dataType: fromPhoto ? DrinkDataType.label : DrinkDataType.custom,
    validationStatus: DrinkValidationStatus.unverified,
  ),
);

class NutritionScanResult {
  const NutritionScanResult({required this.photoBytes, required this.label});
  final Uint8List photoBytes;
  final NutritionLabel label;
}

class NutritionLabelException implements Exception {
  const NutritionLabelException(this.message);
  final String message;
}

abstract interface class NutritionLabelReader {
  Future<NutritionLabel> read(Uint8List photoBytes);
}
