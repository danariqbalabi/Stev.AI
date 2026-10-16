import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';
import 'package:steviai/features/barcode/data/barcode_lookup_service.dart';
import 'package:steviai/features/barcode/presentation/barcode_scan_screen.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
import 'package:steviai/features/result/presentation/result_screen.dart';
import 'package:steviai/shared/widgets/stev_button.dart';

class FakeLookup implements BarcodeLookup {
  int calls = 0;
  String? lastCode;
  BarcodeLookupException? failure;
  bool missingVolume = false;
  bool needsDrinkConfirmation = false;
  @override
  Future<BarcodeProduct> lookup(String code) async {
    calls++;
    lastCode = code;
    if (failure != null) throw failure!;
    return BarcodeProduct(
      barcode: code,
      name: 'Teh uji',
      sugarGramsPerPortion: 6,
      portionLabel: '100 ml',
      portionMl: missingVolume ? null : 100,
      defaultPortions: 3,
      requiresDrinkConfirmation: needsDrinkConfirmation,
      source: 'Open Food Facts',
      sourceUrl: 'https://world.openfoodfacts.org/product/$code',
    );
  }
}

class FixtureLookup extends FakeLookup {
  @override
  Future<BarcodeProduct> lookup(String code) async {
    final rows = jsonDecode(
      File('test/fixtures/off_barcode_products.json').readAsStringSync(),
    ) as List;
    final row = rows.cast<Map<String, dynamic>>().firstWhere(
      (row) => row['product']['code'] == code,
    );
    return BarcodeLookupService.parseOpenFoodFacts(code, row);
  }
}

Future<({GoRouter router, DrinkLogController log})> mountBarcode(
  WidgetTester tester,
  FakeLookup lookup, {
  DateTime Function()? now,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final log = DrinkLogController();
  final router = GoRouter(
    initialLocation: '/barcode',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/barcode',
        builder: (_, _) =>
            BarcodeScanScreen(lookup: lookup, enableCamera: false, now: now),
      ),
      GoRoute(
        path: '/scan/barcode',
        builder: (_, _) =>
            BarcodeScanScreen(lookup: lookup, enableCamera: false),
      ),
      GoRoute(
        path: '/scan/label',
        builder: (_, state) =>
            Scaffold(body: Text('Label camera ${state.extra}')),
      ),
      GoRoute(
        path: '/nutrition/manual',
        builder: (_, state) => Scaffold(body: Text('Manual ${state.extra}')),
      ),
      GoRoute(
        path: '/result',
        builder: (_, state) => ResultScreen(
          drink: state.extra! as Drink,
          barcodeMl: double.tryParse(
            state.uri.queryParameters['barcodeMl'] ?? '',
          ),
          confirmDrink: state.uri.queryParameters['confirmDrink'] == 'true',
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(log.dispose);
  await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
  return (router: router, log: log);
}

Future<void> lookupCode(
  WidgetTester tester, [
  String code = '8992858527308',
]) async {
  await tester.tap(find.byKey(const ValueKey('revealBarcodeInput')));
  await tester.pump();
  await tester.enterText(find.byKey(const ValueKey('barcodeInput')), code);
  await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets(
    'actual OFF fixture Hydro Coco 250 ml shows 7 g on ResultScreen',
    (tester) async {
      final app = await mountBarcode(tester, FixtureLookup());
      await lookupCode(tester, '8992858527308');
      expect(find.byKey(const ValueKey('resultScreen')), findsOneWidget);
      expect(find.text('250 ml · dari barcode'), findsOneWidget);
      expect(find.text('≈7 g', findRichText: true), findsOneWidget);
      expect(app.log.entries, isEmpty);
    },
  );
  testWidgets(
    'actual OFF fixture Ultra Milk 1 L requests a label, not invented sugar',
    (tester) async {
      final app = await mountBarcode(tester, FixtureLookup());
      await lookupCode(tester, '8998009010613');
      expect(find.byKey(const ValueKey('resultScreen')), findsNothing);
      expect(find.text('Foto label gizi'), findsOneWidget);
      expect(app.log.entries, isEmpty);
    },
  );
  testWidgets(
    'manual input is hidden until requested; invalid checksum never calls lookup',
    (tester) async {
      final lookup = FakeLookup();
      await mountBarcode(tester, lookup);
      expect(find.byKey(const ValueKey('barcodeInput')), findsNothing);
      expect(find.text('Foto label gizi'), findsNothing);
      await lookupCode(tester, '8992858527309');
      expect(lookup.calls, 0);
      expect(
        find.text('Periksa kembali angka barcode pada kemasan.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'found barcode goes directly to result without logging until chosen',
    (tester) async {
      final lookup = FakeLookup()..needsDrinkConfirmation = true;
      final app = await mountBarcode(tester, lookup);
      await lookupCode(tester);
      expect(find.byKey(const ValueKey('resultScreen')), findsOneWidget);
      expect(find.text('300 ml · dari barcode'), findsOneWidget);
      expect(find.text('≈18 g', findRichText: true), findsOneWidget);
      expect(
        find.byKey(const ValueKey('barcodeDrinkConfirmationNotice')),
        findsOneWidget,
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.text('8992858527308'), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
      expect(app.log.entries, isEmpty);
      final choose = find.byKey(const ValueKey('chooseDrinkButton'));
      await tester.ensureVisible(choose);
      await tester.tap(choose);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(app.log.entries.single.grams, 18);
      expect(find.text('Home'), findsOneWidget);
    },
  );
  testWidgets('rescan creates an empty reader and permits another lookup', (
    tester,
  ) async {
    final lookup = FakeLookup();
    await mountBarcode(tester, lookup);
    await lookupCode(tester);
    final again = find.byKey(const ValueKey('scanBarcodeAgain'));
    await tester.ensureVisible(again);
    await tester.tap(again);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('barcodeInput')), findsNothing);
    await lookupCode(tester, '8991749000012');
    expect(lookup.calls, 2);
    expect(lookup.lastCode, '8991749000012');
  });
  for (final known in [false, true]) {
    testWidgets(
      'missing nutrition has one primary label action (known=$known)',
      (tester) async {
        final lookup = FakeLookup()
          ..failure = BarcodeLookupException(
            'Missing',
            failure: BarcodeFailure.incompleteNutrition,
            productName: known ? 'Ultra Milk Full Cream' : null,
          );
        await mountBarcode(tester, lookup);
        await lookupCode(tester);
        expect(
          find.text(known ? 'Ultra Milk Full Cream' : 'Belum ada di data kami'),
          findsOneWidget,
        );
        expect(find.byType(StevButton), findsOneWidget);
        expect(find.byKey(const ValueKey('retryBarcodeLookup')), findsNothing);
        expect(find.textContaining('siapa pun'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('barcodeScanLabel')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text('Label camera 8992858527308'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'unknown package volume is incomplete, never a fabricated result',
    (tester) async {
      final lookup = FakeLookup()..missingVolume = true;
      final app = await mountBarcode(tester, lookup);
      await lookupCode(tester);
      expect(find.text('Teh uji'), findsOneWidget);
      expect(find.byKey(const ValueKey('resultScreen')), findsNothing);
      expect(app.log.entries, isEmpty);
    },
  );
  testWidgets(
    'rate limit retains cooldown with retry as the only primary action',
    (tester) async {
      var now = DateTime(2026, 10, 16, 12);
      final lookup = FakeLookup()
        ..failure = BarcodeLookupException(
          'Rate limit',
          failure: BarcodeFailure.rateLimited,
          retryAt: now.add(const Duration(seconds: 2)),
        );
      await mountBarcode(tester, lookup, now: () => now);
      await lookupCode(tester);
      final retry = find.byKey(const ValueKey('retryBarcodeLookup'));
      expect(tester.widget<StevButton>(retry).onPressed, isNull);
      expect(find.text('Koneksi lagi bermasalah.'), findsOneWidget);
      expect(find.byType(StevButton), findsOneWidget);
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<StevButton>(retry).onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('barcodeManualLabel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Manual 8992858527308'), findsOneWidget);
    },
  );
}
