import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/drinks/data/drink_log_preferences.dart';
import 'package:steviai/features/drinks/domain/drink.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('weekly screen shows summary, chart, and limit state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/weekly');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('weeklyScreen')), findsOneWidget);
    expect(find.text('Minggu ini hemat'), findsOneWidget);
    expect(find.byKey(const ValueKey('weeklySavedGrams')), findsOneWidget);
    expect(find.text('46'), findsOneWidget);
    expect(find.text('lewat swap'), findsOneWidget);
    expect(find.text('Gula harian'), findsOneWidget);
    expect(find.text('50 g'), findsOneWidget);
    for (final label in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']) {
      expect(find.text(label), findsOneWidget);
    }
    for (var index = 0; index < 7; index++) {
      expect(find.byKey(ValueKey('weeklyBar-$index')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly navigation reaches scan and returns home through tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/weekly');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Beranda'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);

    await tester.tap(find.text('Mingguan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.byKey(const ValueKey('scanButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Arahkan ke minuman atau barcode'), findsOneWidget);
    expect(find.byKey(const ValueKey('photoScanScreen')), findsOneWidget);
    final manual = find.byKey(const ValueKey('manualSearchLink'));
    expect(manual, findsOneWidget);
  });

  testWidgets('weekly screen reads persisted totals and swap savings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = DrinkLogPreferences();
    await storage.write(DateTime(2026, 10, 5), const [
      DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
    ], savedGrams: 8);
    await storage.write(DateTime(2026, 10, 8), const [
      DrinkSelection(drink: DrinkCatalog.kopiSusuKalengNescafe),
      DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
    ], savedGrams: 14);
    final drinkLog = await DrinkLogController.persistent(
      preferences: storage,
      now: DateTime(2026, 10, 8),
    );
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(drinkLog.dispose);
    addTearDown(router.dispose);
    router.go('/weekly');

    await tester.pumpWidget(
      StevAiApp(router: router, drinkLogController: drinkLog),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('weeklySavedGrams')), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Senin 18 gram.*Kamis 48 gram')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
