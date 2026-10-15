import 'package:flutter/painting.dart';

import 'drink.dart';

class SwapOption {
  const SwapOption({required this.selection, required this.savedGrams});

  final DrinkSelection selection;
  final double savedGrams;
}

abstract final class DrinkSwap {
  static const _tehMelatiLess = Drink(
    id: 'teh-melati-kotak-less-sugar',
    logIdentityId: 'teh-melati-kotak',
    name: 'Teh melati kotak',
    grams: 10,
    estimated: false,
    category: DrinkCategory.packaged,
    kind: DrinkKind.tea,
    photoAsset: 'assets/drinks/teh_melati_kotak.png',
    photoFit: BoxFit.contain,
  );

  static const _arenLess = Drink(
    id: 'es-kopi-susu-gula-aren-less',
    name: 'Es kopi susu gula aren, less sugar',
    grams: 22,
    estimated: true,
    category: DrinkCategory.coffee,
    kind: DrinkKind.coffee,
    photoAsset: 'assets/drinks/es_kopi_susu_gula_aren.png',
  );

  static List<SwapOption> optionsFor(DrinkSelection current) {
    final levels = current.drink.levels;
    if (levels != null) return _levelOptions(current);

    final alternative = switch (current.drink.id) {
      'teh-melati-kotak' => _tehMelatiLess,
      'kopi-susu-kaleng-nescafe' => _arenLess,
      _ => null,
    };
    if (alternative == null || alternative.kind != current.drink.kind) {
      return const [];
    }

    return [
      SwapOption(
        selection: DrinkSelection(drink: alternative),
        savedGrams: current.grams - alternative.grams,
      ),
    ];
  }

  static List<SwapOption> _levelOptions(DrinkSelection current) {
    final level = current.sugarLevel ?? SugarLevel.normal;
    final targetLevels = switch (level) {
      SugarLevel.normal => const [SugarLevel.less, SugarLevel.noSugar],
      SugarLevel.less => const [SugarLevel.noSugar],
      SugarLevel.noSugar => const <SugarLevel>[],
    };

    final options = targetLevels
        .map((target) {
          final selection = DrinkSelection(
            drink: current.drink,
            sugarLevel: target,
          );
          return SwapOption(
            selection: selection,
            savedGrams: current.grams - selection.grams,
          );
        })
        .where((option) => option.savedGrams > 0)
        .toList();
    options.sort((a, b) => b.savedGrams.compareTo(a.savedGrams));
    return List.unmodifiable(options);
  }
}
