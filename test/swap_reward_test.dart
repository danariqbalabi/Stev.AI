import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';

void main() {
  testWidgets('reward shows saving, target drink, and contextual confetti', (
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
    await tester.tap(find.byKey(const ValueKey('swapButton')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('swapOptionsSheet')), findsOneWidget);
    expect(find.text('Tukar jadi apa?'), findsOneWidget);
    expect(find.byKey(const ValueKey('swapOption-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('swapOption-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('swapOption-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirmSwapButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.byKey(const ValueKey('swapRewardOverlay')), findsOneWidget);
    expect(find.text('Mantap, hemat 14 g!'), findsOneWidget);
    expect(find.text('Es kopi susu gula aren, less sugar'), findsOneWidget);
    expect(find.text('≈22 g'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.byKey(const ValueKey('confetti-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('confetti-11')), findsOneWidget);
  });

  testWidgets('reward choice logs the swapped drink and returns home', (
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
    await tester.tap(find.byKey(const ValueKey('swapButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('swapOption-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirmSwapButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.tap(find.byKey(const ValueKey('chooseSwapButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    // The route transition completes before Dashboard starts its one-shot
    // 560 ms log flight, so advance that animation separately.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('Es kopi susu gula aren'), findsOneWidget);
    expect(log.entries.single.sugarLevel?.name, 'less');
    expect(log.savedGrams, 14);
  });

  testWidgets('saving below one spoon does not show confetti', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    final log = DrinkLogController();
    addTearDown(router.dispose);
    addTearDown(log.dispose);
    router.go('/result', extra: DrinkCatalog.matcha);

    await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('swapButton')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('swapOption-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirmSwapButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));

    expect(find.text('Mantap, hemat 8 g!'), findsOneWidget);
    expect(find.byKey(const ValueKey('confetti-0')), findsNothing);
  });
}
