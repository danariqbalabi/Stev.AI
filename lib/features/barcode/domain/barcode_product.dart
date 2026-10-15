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

  DrinkSelection selectionFor(double portions) {
    if (!portions.isFinite || portions <= 0 || portions > 100) {
      throw const FormatException('Jumlah porsi tidak valid.');
    }
    return DrinkSelection(
      drink: Drink(
        id: catalogDrink?.id ?? 'barcode-$barcode',
        name: name,
        grams: sugarGramsPerPortion * portions,
        estimated: catalogDrink?.estimated ?? true,
        category: DrinkCategory.packaged,
        kind: catalogDrink?.kind ?? DrinkKind.custom,
        photoAsset: catalogDrink?.photoAsset ?? '',
        photoUrl: imageUrl,
        dataType: catalogDrink?.dataType ?? DrinkDataType.community,
        validationStatus:
            catalogDrink?.validationStatus ?? DrinkValidationStatus.unverified,
        sourceUrl: sourceUrl,
      ),
    );
  }
}

class BarcodeLookupException implements Exception {
  const BarcodeLookupException(this.message);

  final String message;
}

abstract interface class BarcodeLookup {
  Future<BarcodeProduct> lookup(String barcode);
}
