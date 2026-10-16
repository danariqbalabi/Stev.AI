import '../../drinks/domain/drink.dart';

/// Retail GTINs only; QR URLs and shortened UPC-E values are not product IDs.
String? validRetailBarcode(String raw) {
  final code = raw.trim();
  if (!RegExp(r'^(\d{8}|\d{12}|\d{13}|\d{14})$').hasMatch(code)) return null;
  var sum = 0;
  for (var index = code.length - 2, weight = 3; index >= 0; index--) {
    sum += int.parse(code[index]) * weight;
    weight = weight == 3 ? 1 : 3;
  }
  return (10 - sum % 10) % 10 == int.parse(code[code.length - 1]) ? code : null;
}

class BarcodeProduct {
  const BarcodeProduct({
    required this.barcode,
    required this.name,
    required this.sugarGramsPerPortion,
    required this.portionLabel,
    required this.source,
    required this.sourceUrl,
    this.defaultPortions = 1,
    this.imageUrl,
    this.catalogDrink,
    this.cachedAt,
    this.portionMl,
  });

  final String barcode;
  final String name;
  final double sugarGramsPerPortion;
  final String portionLabel;
  final double defaultPortions;
  final String source;
  final String sourceUrl;
  final String? imageUrl;
  final Drink? catalogDrink;
  final DateTime? cachedAt;
  final double? portionMl;
  double? get packageMl =>
      portionMl == null ? null : portionMl! * defaultPortions;

  bool sizeCorrected(double ml) =>
      packageMl != null && (ml - packageMl!).abs() > 0.001;

  DrinkSelection selectionForVolume(double ml, double fraction) {
    final baseMl = portionMl;
    if (baseMl == null ||
        !baseMl.isFinite ||
        baseMl <= 0 ||
        !ml.isFinite ||
        ml <= 0 ||
        ml > 10000 ||
        !fraction.isFinite ||
        fraction <= 0 ||
        fraction > 1) {
      throw const FormatException(
        'Volume atau bagian yang diminum tidak valid.',
      );
    }
    return selectionFor(
      ml / baseMl * fraction,
      correctedMl: sizeCorrected(ml) ? ml : null,
    );
  }

  BarcodeProduct fromCache(DateTime at) => BarcodeProduct(
    barcode: barcode,
    name: name,
    sugarGramsPerPortion: sugarGramsPerPortion,
    portionLabel: portionLabel,
    source: source,
    sourceUrl: sourceUrl,
    defaultPortions: defaultPortions,
    imageUrl: imageUrl,
    catalogDrink: catalogDrink,
    cachedAt: at,
    portionMl: portionMl,
  );

  DrinkSelection selectionFor(double portions, {double? correctedMl}) {
    if (!portions.isFinite || portions <= 0 || portions > 100) {
      throw const FormatException('Jumlah porsi tidak valid.');
    }
    return DrinkSelection(
      drink: Drink(
        id: correctedMl == null
            ? catalogDrink?.id ?? 'barcode-$barcode'
            : 'barcode-$barcode-size-$correctedMl',
        name: correctedMl == null
            ? name
            : '$name — ukuran dikoreksi: $correctedMl ml',
        grams: sugarGramsPerPortion * portions,
        estimated: correctedMl != null || (catalogDrink?.estimated ?? true),
        category: DrinkCategory.packaged,
        kind: catalogDrink?.kind ?? DrinkKind.custom,
        photoAsset: catalogDrink?.photoAsset ?? '',
        photoUrl: imageUrl,
        dataType: correctedMl != null
            ? DrinkDataType.custom
            : catalogDrink?.dataType ?? DrinkDataType.community,
        validationStatus: correctedMl != null
            ? DrinkValidationStatus.unverified
            : catalogDrink?.validationStatus ??
                  DrinkValidationStatus.unverified,
        sourceUrl: sourceUrl,
      ),
    );
  }
}

class BarcodeLookupException implements Exception {
  const BarcodeLookupException(this.message, {this.retryAt});

  final String message;
  final DateTime? retryAt;
}

abstract interface class BarcodeLookup {
  Future<BarcodeProduct> lookup(String barcode);
}
