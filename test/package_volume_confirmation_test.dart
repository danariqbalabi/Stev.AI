import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/features/nutrition/domain/nutrition_label.dart';

import 'nutrition_confirmation_test.dart'
    show mountLabel, scannedLabel, tapLabel;

void main() {
  for (final ml in [250.0, 350.0]) {
    testWidgets(
      'Pocari net $ml ml overrides rounded 1.5 servings without a warning',
      (tester) async {
        final log = await mountLabel(
          tester,
          scannedLabel(
            NutritionLabel(
              productName: 'Pocari Sweat',
              sugarGrams: 14,
              basis: NutritionBasis.perServing,
              servingMl: 250,
              packageMl: ml,
              servingsPerPackage: 1.5,
              sugarText: 'Gula 14 g',
              basisText: 'Takaran saji 250 ml',
              confidence: .95,
            ),
          ),
          size: const Size(320, 700),
        );
        expect(
          find.byKey(const ValueKey('nutritionVolumeWarning')),
          findsNothing,
        );
        expect(find.text(ml == 250 ? '14 g' : '19,6 g'), findsOneWidget);
        expect(log.entries, isEmpty);
        await tapLabel(tester, 'logNutritionDrink');
        expect(log.entries.single.grams, closeTo(14 / 250 * ml, .000001));
      },
    );
  }
}
