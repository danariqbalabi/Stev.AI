import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';

void main() {
  testWidgets('level picker updates grams and swap availability', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    final log = DrinkLogController();
    addTearDown(router.dispose);
    addTearDown(log.dispose);
    router.go('/result', extra: DrinkCatalog.esKopiSusuGulaAren);

    await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Hasil scan'), findsOneWidget);
    expect(find.text('Data demo — belum divalidasi'), findsOneWidget);
    expect(find.text('Es kopi susu gula aren'), findsOneWidget);
    expect(find.text('≈36 g'), findsOneWidget);
    expect(find.text('Masih aman, nih!'), findsOneWidget);
    expect(find.byKey(const ValueKey('swapButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sugarLevel-less')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('≈22 g'), findsOneWidget);
    expect(find.byKey(const ValueKey('swapButton')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sugarLevel-noSugar')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('≈6 g'), findsOneWidget);
    expect(find.byKey(const ValueKey('swapButton')), findsNothing);
  });

  testWidgets('daily total drives warning and choosing logs the drink', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    final log = DrinkLogController.demo();
    addTearDown(router.dispose);
    addTearDown(log.dispose);
    router.go('/result', extra: DrinkCatalog.kopiSusuKalengNescafe);

    await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('30 g'), findsOneWidget);
    expect(find.text('Waduh, lewat 12 g!', findRichText: true), findsOneWidget);
    expect(find.byKey(const ValueKey('swapButton')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('chooseDrinkButton')));
    await tester.tap(find.byKey(const ValueKey('chooseDrinkButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 600));
    // The dashboard counter animation starts after the route transition, so
    // advance it separately before asserting the settled daily total.
    await tester.pump(const Duration(milliseconds: 600));
    // The dashboard counter animation starts after the route transition, so
    // advance it separately before asserting the settled daily total.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
    expect(find.text('Kopi susu kaleng Nescafe'), findsOneWidget);
  });

  testWidgets('drink without a valid alternative hides swap', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/result', extra: DrinkCatalog.spriteBotol);

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Sprite botol'), findsOneWidget);
    expect(find.byKey(const ValueKey('swapButton')), findsNothing);
    expect(find.byKey(const ValueKey('chooseDrinkButton')), findsOneWidget);
  });
}
