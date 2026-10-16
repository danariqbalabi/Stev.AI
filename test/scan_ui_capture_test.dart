// Opt-in documentation captures: flutter test test/scan_ui_capture_test.dart
// --dart-define=CAPTURE_SCAN_UI=true (regenerates after screenshots only)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';
import 'package:steviai/features/barcode/presentation/barcode_scan_screen.dart';
import 'package:steviai/features/nutrition/domain/nutrition_label.dart';
import 'package:steviai/features/nutrition/presentation/nutrition_confirmation_screen.dart';
import 'package:steviai/features/result/presentation/result_screen.dart';
import 'package:steviai/features/drinks/domain/drink.dart';

class _Lookup implements BarcodeLookup {
  _Lookup(this.missing);
  final bool missing;
  @override
  Future<BarcodeProduct> lookup(String code) async {
    if (missing) {
      throw const BarcodeLookupException(
        'Data gula belum lengkap.',
        failure: BarcodeFailure.incompleteNutrition,
      );
    }
    return BarcodeProduct(
      barcode: code,
      name: 'Teh uji',
      sugarGramsPerPortion: 5.6,
      portionLabel: '100 ml',
      portionMl: 100,
      defaultPortions: 3.5,
      source: 'Open Food Facts',
      sourceUrl: '',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('CAPTURE_SCAN_UI')) {
    setUpAll(() async {
      for (final weight in ['Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
        await ui.loadFontFromList(
          File('assets/fonts/Onest-$weight.ttf').readAsBytesSync(),
          fontFamily: 'Onest',
        );
      }
      await ui.loadFontFromList(
        File('build/unit_test_assets/fonts/MaterialIcons-Regular.otf')
            .readAsBytesSync(),
        fontFamily: 'MaterialIcons',
      );
    });
  }
  for (final screen in ['barcode-found', 'barcode-missing', 'label']) {
    testWidgets('capture $screen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = File('assets/drinks/teh_melati_kotak.png')
          .readAsBytesSync();
      final router = GoRouter(
        initialLocation: '/capture',
        routes: [
          GoRoute(
            path: '/capture',
            builder: (_, _) {
              if (screen != 'label') {
                return BarcodeScanScreen(
                  enableCamera: false,
                  lookup: _Lookup(screen == 'barcode-missing'),
                );
              }
              final result = NutritionScanResult(
                photoBytes: bytes,
                label: const NutritionLabel(
                  sugarGrams: 14,
                  basis: NutritionBasis.perServing,
                  servingMl: 250,
                  packageMl: 350,
                  servingsPerPackage: 1.5,
                  productName: 'Teh uji',
                  sugarText: 'Gula 14 g',
                  basisText: 'Per 250 ml',
                  confidence: .95,
                ),
              );
              return NutritionConfirmationScreen(result: result);
            },
          ),
          GoRoute(
            path: '/result',
            builder: (_, state) => ResultScreen(
              drink: state.extra! as Drink,
              barcodeMl: double.tryParse(
                state.uri.queryParameters['barcodeMl'] ?? '',
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: StevAiApp(router: router),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => precacheImage(MemoryImage(bytes), boundaryKey.currentContext!),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      if (screen != 'label') {
        final reveal = find.text('Ketik kode barcode');
        if (reveal.evaluate().isNotEmpty) {
          await tester.tap(reveal);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pump(const Duration(milliseconds: 600));
        }
        await tester.enterText(
          find.byKey(const ValueKey('barcodeInput')),
          '8992858527308',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('lookupBarcodeButton')),
        );
        await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
      }
      const stage = 'after';
      await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/design/scan-redesign/qa/$stage-$screen.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }, skip: !const bool.fromEnvironment('CAPTURE_SCAN_UI'));
  }
}
