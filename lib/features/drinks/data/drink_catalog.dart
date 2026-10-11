import 'package:flutter/painting.dart';

import '../domain/drink.dart';

abstract final class DrinkCatalog {
  static const esTehManis = Drink(
    id: 'es-teh-manis',
    name: 'Es teh manis',
    grams: 24,
    estimated: true,
    category: DrinkCategory.tea,
    kind: DrinkKind.tea,
    photoAsset: 'assets/drinks/es_teh_manis.png',
    levels: SugarLevels(normal: 24, less: 14, noSugar: 0),
  );

  static const esKopiSusuGulaAren = Drink(
    id: 'es-kopi-susu-gula-aren',
    name: 'Es kopi susu gula aren',
    grams: 36,
    estimated: true,
    category: DrinkCategory.coffee,
    kind: DrinkKind.coffee,
    photoAsset: 'assets/drinks/es_kopi_susu_gula_aren.png',
    levels: SugarLevels(normal: 36, less: 22, noSugar: 6),
  );

  static const bobaMilkTea = Drink(
    id: 'boba-milk-tea',
    name: 'Boba milk tea',
    grams: 38,
    estimated: true,
    category: DrinkCategory.boba,
    kind: DrinkKind.boba,
    photoAsset: 'assets/drinks/boba_milk_tea.png',
    levels: SugarLevels(normal: 38, less: 25, noSugar: 12),
  );

  static const esJeruk = Drink(
    id: 'es-jeruk',
    name: 'Es jeruk',
    grams: 16,
    estimated: true,
    category: DrinkCategory.juice,
    kind: DrinkKind.juice,
    photoAsset: 'assets/drinks/es_jeruk.png',
  );

  static const matcha = Drink(
    id: 'matcha',
    name: 'Matcha',
    grams: 20,
    estimated: true,
    category: DrinkCategory.tea,
    kind: DrinkKind.tea,
    photoAsset: 'assets/drinks/matcha.png',
    levels: SugarLevels(normal: 20, less: 12, noSugar: 4),
  );

  static const tehMelatiKotak = Drink(
    id: 'teh-melati-kotak',
    name: 'Teh melati kotak',
    grams: 18,
    estimated: false,
    category: DrinkCategory.packaged,
    kind: DrinkKind.tea,
    photoAsset: 'assets/drinks/teh_melati_kotak.png',
    photoFit: BoxFit.contain,
  );

  static const kopiSusuKalengNescafe = Drink(
    id: 'kopi-susu-kaleng-nescafe',
    name: 'Kopi susu kaleng Nescafe',
    grams: 30,
    estimated: false,
    category: DrinkCategory.packaged,
    kind: DrinkKind.coffee,
    photoAsset: 'assets/drinks/kopi_susu_kaleng_nescafe.png',
    photoFit: BoxFit.contain,
  );

  static const susuCokelatKotakUltra = Drink(
    id: 'susu-cokelat-kotak-ultra',
    name: 'Susu cokelat kotak Ultra',
    grams: 22,
    estimated: false,
    category: DrinkCategory.packaged,
    kind: DrinkKind.milk,
    photoAsset: 'assets/drinks/susu_cokelat_ultra.png',
    photoFit: BoxFit.contain,
  );

  static const spriteBotol = Drink(
    id: 'sprite-botol',
    name: 'Sprite botol',
    grams: 25,
    estimated: false,
    category: DrinkCategory.packaged,
    kind: DrinkKind.soda,
    photoAsset: 'assets/drinks/sprite_botol.png',
    photoFit: BoxFit.contain,
  );

  static const hydroCoco = Drink(
    id: 'hydro-coco',
    name: 'Hydro Coco',
    grams: 9,
    estimated: false,
    category: DrinkCategory.packaged,
    kind: DrinkKind.isotonic,
    photoAsset: 'assets/drinks/hydro_coco.png',
    photoFit: BoxFit.contain,
  );

  static const all = [
    esTehManis,
    esKopiSusuGulaAren,
    bobaMilkTea,
    esJeruk,
    matcha,
    tehMelatiKotak,
    kopiSusuKalengNescafe,
    susuCokelatKotakUltra,
    spriteBotol,
    hydroCoco,
  ];

  static Drink? findById(String id) {
    for (final drink in all) {
      if (drink.id == id) return drink;
    }
    return null;
  }
}
