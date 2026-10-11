import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
import 'package:steviai/features/drinks/domain/drink_swap.dart';

void main() {
  group('drink catalog', () {
    test('contains the ten drinks from the design handoff', () {
      expect(DrinkCatalog.all, hasLength(10));
      expect(
        DrinkCatalog.all.map((drink) => drink.id),
        containsAll([
          'es-teh-manis',
          'es-kopi-susu-gula-aren',
          'boba-milk-tea',
          'es-jeruk',
          'matcha',
          'teh-melati-kotak',
          'kopi-susu-kaleng-nescafe',
          'susu-cokelat-kotak-ultra',
          'sprite-botol',
          'hydro-coco',
        ]),
      );
      expect(DrinkCatalog.findById('matcha'), DrinkCatalog.matcha);
      expect(DrinkCatalog.findById('unknown'), isNull);
    });

    test('formats estimated and label-based sugar values differently', () {
      const tea = DrinkSelection(
        drink: DrinkCatalog.esTehManis,
        sugarLevel: SugarLevel.less,
      );
      const packaged = DrinkSelection(drink: DrinkCatalog.tehMelatiKotak);

      expect(tea.displayGrams, '≈14 g');
      expect(packaged.displayGrams, '18 g');
    });
  });

  group('swap rules', () {
    test('sorts non-packaged alternatives by highest saving', () {
      const current = DrinkSelection(
        drink: DrinkCatalog.esKopiSusuGulaAren,
        sugarLevel: SugarLevel.normal,
      );

      final options = DrinkSwap.optionsFor(current);

      expect(options, hasLength(2));
      expect(options[0].selection.sugarLevel, SugarLevel.noSugar);
      expect(options[0].selection.grams, 6);
      expect(options[0].savedGrams, 30);
      expect(options[1].selection.sugarLevel, SugarLevel.less);
      expect(options[1].selection.grams, 22);
      expect(options[1].savedGrams, 14);
    });

    test('offers only no sugar after less sugar', () {
      const current = DrinkSelection(
        drink: DrinkCatalog.esTehManis,
        sugarLevel: SugarLevel.less,
      );

      final options = DrinkSwap.optionsFor(current);

      expect(options, hasLength(1));
      expect(options.single.selection.sugarLevel, SugarLevel.noSugar);
      expect(options.single.savedGrams, 14);
    });

    test('uses explicit same-product swaps for supported packaged drinks', () {
      const current = DrinkSelection(drink: DrinkCatalog.kopiSusuKalengNescafe);

      final options = DrinkSwap.optionsFor(current);

      expect(options, hasLength(1));
      expect(options.single.selection.grams, 22);
      expect(options.single.savedGrams, 8);
      expect(options.single.selection.identityId, current.identityId);
      expect(options.single.selection.drink.kind, current.drink.kind);
    });

    test('does not offer a swap when the handoff defines none', () {
      expect(
        DrinkSwap.optionsFor(
          const DrinkSelection(drink: DrinkCatalog.spriteBotol),
        ),
        isEmpty,
      );
      expect(
        DrinkSwap.optionsFor(
          const DrinkSelection(
            drink: DrinkCatalog.matcha,
            sugarLevel: SugarLevel.noSugar,
          ),
        ),
        isEmpty,
      );
    });
  });

  group('daily drink log', () {
    test('starts with the 32 gram dashboard demo state', () {
      final log = DrinkLogController.demo();
      addTearDown(log.dispose);

      expect(log.totalGrams, 32);
      expect(log.entries.first.drink, DrinkCatalog.tehMelatiKotak);
      expect(log.entries.last.sugarLevel, SugarLevel.less);
    });

    test('keeps the newest selection and replaces the same drink', () {
      final log = DrinkLogController.demo();
      addTearDown(log.dispose);

      log.log(
        const DrinkSelection(
          drink: DrinkCatalog.esKopiSusuGulaAren,
          sugarLevel: SugarLevel.less,
        ),
      );
      expect(log.totalGrams, 54);
      expect(log.entries.first.drink, DrinkCatalog.esKopiSusuGulaAren);

      log.log(
        const DrinkSelection(
          drink: DrinkCatalog.esKopiSusuGulaAren,
          sugarLevel: SugarLevel.noSugar,
        ),
      );
      expect(log.entries, hasLength(3));
      expect(log.totalGrams, 38);
      expect(log.entries.first.sugarLevel, SugarLevel.noSugar);
    });
  });
}
