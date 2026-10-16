import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';
import 'package:steviai/features/barcode/presentation/barcode_scan_screen.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
import 'package:steviai/features/nutrition/domain/nutrition_label.dart';
import 'package:steviai/features/nutrition/presentation/nutrition_confirmation_screen.dart';
import 'package:steviai/shared/widgets/stev_button.dart';

class _PocariLookup implements BarcodeLookup {
  @override
  Future<BarcodeProduct> lookup(String barcode) async => BarcodeProduct(
    barcode: barcode,
    name: 'Pocari Sweat 350 ml',
    sugarGramsPerPortion: 5.6,
    portionLabel: '100 ml',
    portionMl: 100,
    defaultPortions: 3.5,
    source: 'Open Food Facts',
    sourceUrl: '',
  );
}

void main() {
  for (final barcode in [true, false]) {
    testWidgets(
      '250 ml Pocari records 14 g only after volume confirmation (barcode=$barcode)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final log = DrinkLogController();
        addTearDown(log.dispose);
        final router = GoRouter(
          initialLocation: '/confirm',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('Home')),
            ),
            GoRoute(
              path: '/confirm',
              builder: (_, _) => barcode
                  ? BarcodeScanScreen(
                      lookup: _PocariLookup(),
                      enableCamera: false,
                    )
                  : NutritionConfirmationScreen(
                      result: NutritionScanResult(
                        photoBytes: base64Decode(
                          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9qkAAAAASUVORK5CYII=',
                        ),
                        label: const NutritionLabel(
                          productName: 'Pocari Sweat',
                          sugarGrams: 14,
                          basis: NutritionBasis.perServing,
                          servingMl: 250,
                          servingsPerPackage: 1.5,
                          sugarText: 'Gula 14 g',
                          basisText: 'Takaran saji 250 ml',
                          confidence: 0.95,
                        ),
                      ),
                    ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          StevAiApp(router: router, drinkLogController: log),
        );
        if (barcode) {
          await tester.enterText(
            find.byKey(const ValueKey('barcodeInput')),
            '8997035563544',
          );
          await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final volume = find.byKey(
          ValueKey(barcode ? 'barcodeVolume' : 'nutritionVolume'),
        );
        final save = find.byKey(
          ValueKey(barcode ? 'logBarcodeDrink' : 'logNutritionDrink'),
        );
        final ack = find.byKey(
          ValueKey(barcode ? 'confirmBarcodeSize' : 'confirmNutritionLabel'),
        );
        final scrollable = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(volume, 150, scrollable: scrollable);
        if (!barcode) {
          expect(
            tester.widget<TextFormField>(volume).controller!.text,
            isEmpty,
          );
          expect(find.text('Gula yang dicatat: 21 g'), findsNothing);
        }
        await tester.enterText(volume, '250');
        await tester.pump();
        final warning = find.byKey(
          ValueKey(barcode ? 'barcodeVolumeWarning' : 'nutritionVolumeWarning'),
        );
        await tester.scrollUntilVisible(warning, 150, scrollable: scrollable);
        expect(warning, findsOneWidget);
        await tester.scrollUntilVisible(save, 150, scrollable: scrollable);
        expect(
          find.text(barcode ? 'Total: 14 g gula' : 'Gula yang dicatat: 14 g'),
          findsOneWidget,
        );
        expect(tester.widget<StevButton>(save).onPressed, isNull);
        expect(log.entries, isEmpty);
        await tester.ensureVisible(ack);
        await Scrollable.ensureVisible(tester.element(ack), alignment: 0.5);
        await tester.pump();
        await tester.tap(ack);
        await tester.pump();
        expect(tester.widget<StevButton>(save).onPressed, isNotNull);
        await tester.scrollUntilVisible(volume, -150, scrollable: scrollable);
        await tester.enterText(volume, '350');
        await tester.pump();
        await tester.scrollUntilVisible(save, 150, scrollable: scrollable);
        expect(tester.widget<StevButton>(save).onPressed, isNull);
        expect(
          find.text(
            barcode ? 'Total: 19.6 g gula' : 'Gula yang dicatat: 19.6 g',
          ),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(volume, -150, scrollable: scrollable);
        await tester.enterText(volume, '250');
        await tester.pump();
        await tester.scrollUntilVisible(ack, 150, scrollable: scrollable);
        await Scrollable.ensureVisible(tester.element(ack), alignment: 0.5);
        await tester.pump();
        await tester.tap(ack);
        await tester.pump();
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(log.entries.single.grams, closeTo(14, 0.000001));
        expect(
          log.entries.single.drink.validationStatus,
          DrinkValidationStatus.unverified,
        );
        expect(find.text('Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
