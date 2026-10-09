import 'package:flutter/widgets.dart';

import '../domain/today_drink.dart';

const dashboardDemoDrinks = [
  TodayDrink(
    id: 'teh-melati-manual',
    name: 'Teh melati kotak',
    grams: 18,
    estimated: false,
    photoAsset: 'assets/drinks/teh_melati_kotak.png',
    photoFit: BoxFit.contain,
  ),
  TodayDrink(
    id: 'es-teh-manis-manual',
    name: 'Es teh manis',
    grams: 14,
    estimated: true,
    sugarLevel: 2,
    photoAsset: 'assets/drinks/es_teh_manis.png',
  ),
];
