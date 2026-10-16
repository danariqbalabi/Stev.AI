import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';
import 'package:steviai/features/barcode/presentation/barcode_scan_screen.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/shared/widgets/stev_button.dart';

class FakeLookup implements BarcodeLookup {
  int calls = 0;
  bool missing = false;
  DateTime? retryAt;
  BarcodeProduct? product;
  BarcodeLookupException? failure;
  String? lastCode;

  @override
  Future<BarcodeProduct> lookup(String barcode) async {
    calls++;
    lastCode = barcode;
    if (failure != null) throw failure!;
    if (retryAt != null) {
      throw BarcodeLookupException('Pencarian perlu jeda.', retryAt: retryAt);
    }
    if (missing) throw const BarcodeLookupException('Produk belum ditemukan.');
    return product ??
        BarcodeProduct(
          barcode: barcode,
          name: 'Teh uji',
          sugarGramsPerPortion: 6,
          portionLabel: '100 ml',
          portionMl: 100,
          defaultPortions: 3,
          source: 'Open Food Facts — belum diverifikasi Stev.AI',
          sourceUrl: 'https://world.openfoodfacts.org/product/$barcode',
        );
  }
}

void main() {
  testWidgets(
    'known product without sugar offers one main label action, not a false not-found result',
    (tester) async {
      final lookup = FakeLookup()
        ..failure = const BarcodeLookupException(
          'Produk ditemukan, tetapi data gula belum lengkap.',
          productName: 'Ultra Milk Full Cream',
          failure: BarcodeFailure.incompleteNutrition,
        );
      final router = GoRouter(
        initialLocation: '/barcode',
        routes: [
          GoRoute(
            path: '/barcode',
            builder: (_, _) =>
                BarcodeScanScreen(lookup: lookup, enableCamera: false),
          ),
          GoRoute(
            path: '/scan/label',
            builder: (_, _) => const Scaffold(body: Text('Label camera')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(StevAiApp(router: router));
      await tester.enterText(
        find.byKey(const ValueKey('barcodeInput')),
        '8998009010613',
      );
      await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
      await tester.pump();
      expect(
        find.text('Produk ditemukan: Ultra Milk Full Cream'),
        findsOneWidget,
      );
      expect(find.byType(StevButton), findsOneWidget);
      expect(find.text('Foto label gizi'), findsOneWidget);
      expect(find.byKey(const ValueKey('retryBarcodeLookup')), findsNothing);
      final action = find.byKey(const ValueKey('barcodeScanLabel'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Label camera'), findsOneWidget);
    },
  );

  testWidgets(
    'a wrong but valid code can be corrected and unknown category requires drink confirmation',
    (tester) async {
      final lookup = FakeLookup()..missing = true;
      final router = GoRouter(
        initialLocation: '/barcode',
        routes: [
          GoRoute(
            path: '/barcode',
            builder: (_, _) =>
                BarcodeScanScreen(lookup: lookup, enableCamera: false),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(StevAiApp(router: router));
      await tester.enterText(
        find.byKey(const ValueKey('barcodeInput')),
        '8991749000043',
      );
      await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('editBarcodeCode')));
      await tester.pump();
      final input = find.byKey(const ValueKey('barcodeInput'));
      expect(tester.widget<TextField>(input).controller!.text, '8991749000043');
      lookup.missing = false;
      lookup.product = const BarcodeProduct(
        barcode: '8991749000012',
        name: 'Kopi Kenangan Black Aren',
        sugarGramsPerPortion: 14,
        portionLabel: '220 ml',
        portionMl: 220,
        source: 'Open Food Facts',
        sourceUrl: '',
        requiresDrinkConfirmation: true,
      );
      await tester.enterText(input, '8991749000012');
      await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
      await tester.pump();
      expect(lookup.lastCode, '8991749000012');
      expect(lookup.calls, 2);
      final notice = find.byKey(
        const ValueKey('barcodeDrinkConfirmationNotice'),
      );
      await tester.scrollUntilVisible(
        notice,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(notice, findsOneWidget);
      final save = find.byKey(const ValueKey('logBarcodeDrink'));
      await tester.scrollUntilVisible(
        save,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<StevButton>(save).onPressed, isNull);
      expect(
        find.text(
          'Ini minuman siap minum. Varian, ukuran, dan bagian yang diminum sudah sesuai.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rate limit disables retry but manual label stays available', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 16);
    final lookup = FakeLookup()..retryAt = now.add(const Duration(seconds: 10));
    final router = GoRouter(
      initialLocation: '/barcode',
      routes: [
        GoRoute(
          path: '/barcode',
          builder: (_, _) => BarcodeScanScreen(
            lookup: lookup,
            enableCamera: false,
            now: () => now,
          ),
        ),
        GoRoute(
          path: '/nutrition/manual',
          builder: (_, _) => const Scaffold(body: Text('Manual label')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.enterText(
      find.byKey(const ValueKey('barcodeInput')),
      '5449000000996',
    );
    await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
    await tester.pump();
    final retry = find.byKey(const ValueKey('retryBarcodeLookup'));
    expect(tester.widget<TextButton>(retry).onPressed, isNull);
    expect(find.text('Coba lagi dalam 10 dtk'), findsOneWidget);
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<TextButton>(retry).onPressed, isNotNull);
    final manual = find.byKey(const ValueKey('barcodeManualLabel'));
    await tester.ensureVisible(manual);
    await tester.tap(manual);
    await tester.pumpAndSettle();
    expect(find.text('Manual label'), findsOneWidget);
    expect(lookup.calls, 1);
  });

  testWidgets('confirming barcode portions logs only after explicit choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lookup = FakeLookup();
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
              BarcodeScanScreen(lookup: lookup, enableCamera: false),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(log.dispose);
    await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
    await tester.enterText(
      find.byKey(const ValueKey('barcodeInput')),
      '5449000000996',
    );
    await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Teh uji'), findsOneWidget);
    expect(find.text('Total: 18 g gula'), findsOneWidget);
    expect(log.entries, isEmpty);
    await tester.enterText(find.byKey(const ValueKey('barcodeVolume')), '150');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('barcodeSugarTotal')),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Total: 9 g gula'), findsOneWidget);
    final acknowledgement = find.byKey(const ValueKey('confirmBarcodeSize'));
    await tester.ensureVisible(acknowledgement);
    await tester.tap(acknowledgement);
    await tester.pump();
    final confirm = find.byKey(const ValueKey('logBarcodeDrink'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(log.entries.single.grams, 9);
    expect(
      log.entries.single.drink.id,
      startsWith('barcode-5449000000996-size-'),
    );
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('unknown barcode can be scanned again without stale result', (
    tester,
  ) async {
    final lookup = FakeLookup()..missing = true;
    final log = DrinkLogController();
    addTearDown(log.dispose);
    final router = GoRouter(
      initialLocation: '/barcode',
      routes: [
        GoRoute(
          path: '/barcode',
          builder: (_, _) =>
              BarcodeScanScreen(lookup: lookup, enableCamera: false),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
    await tester.enterText(
      find.byKey(const ValueKey('barcodeInput')),
      '5449000000996',
    );
    await tester.tap(find.byKey(const ValueKey('lookupBarcodeButton')));
    await tester.pump();
    expect(find.text('Produk belum ditemukan.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scanBarcodeAgain')));
    await tester.pump();
    expect(find.byKey(const ValueKey('barcodeInput')), findsOneWidget);
    expect(find.byKey(const ValueKey('barcodeError')), findsNothing);
    expect(log.entries, isEmpty);
    expect(lookup.calls, 1);
  });
}
