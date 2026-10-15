import '../../drinks/domain/drink.dart';

abstract final class CustomDrink {
  static const sugarPerSpoon = 12.5;
  static const sugarPerSyrupPump = 5.0;

  static double sugarGrams({required int spoons, required int syrupPumps}) {
    assert(spoons >= 0);
    assert(syrupPumps >= 0);
    return spoons * sugarPerSpoon + syrupPumps * sugarPerSyrupPump;
  }

  static Drink create({
    required String name,
    required int spoons,
    required int syrupPumps,
    String? id,
  }) {
    final trimmedName = name.trim();
    return Drink(
      id: id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmedName.isEmpty ? 'Minuman racikan' : trimmedName,
      grams: sugarGrams(spoons: spoons, syrupPumps: syrupPumps),
      estimated: true,
      category: DrinkCategory.custom,
      kind: DrinkKind.custom,
      dataType: DrinkDataType.custom,
      photoAsset: 'assets/drinks/es_teh_manis.png',
    );
  }
}
