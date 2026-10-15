import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';
import 'package:steviai/features/barcode/presentation/barcode_scan_screen.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';

class FakeLookup implements BarcodeLookup {
  int calls = 0;
  bool missing = false;
  DateTime? retryAt;

  @override
  Future<BarcodeProduct> lookup(String barcode) async {
    calls++;
    if (retryAt != null) {
      throw BarcodeLookupException('Pencarian perlu jeda.', retryAt: retryAt);
    }
    if (missing) throw const BarcodeLookupException('Produk belum ditemukan.');
    return BarcodeProduct(
      barcode: barcode,
      name: 'Teh uji',
      sugarGramsPerPortion: 6,
      portionLabel: '100 ml',
      defaultPortions: 3,
      source: 'Open Food Facts — belum diverifikasi Stev.AI',
      sourceUrl: 'https://world.openfoodfacts.org/product/$barcode',
    );
  }
}

void main() {
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
    await tester.enterText(
      find.byKey(const ValueKey('barcodePortions')),
      '1,5',
    );
    await tester.pump();
    expect(find.text('Total: 9 g gula'), findsOneWidget);
    final confirm = find.byKey(const ValueKey('logBarcodeDrink'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(log.entries.single.grams, 9);
    expect(log.entries.single.drink.id, 'barcode-5449000000996');
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
