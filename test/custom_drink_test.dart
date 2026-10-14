import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/custom_drink/domain/custom_drink.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';

void main() {
  test('custom drink calculates spoons and syrup pumps', () {
    expect(CustomDrink.sugarGrams(spoons: 1, syrupPumps: 0), 12.5);
    expect(CustomDrink.sugarGrams(spoons: 2, syrupPumps: 2), 35);

    final drink = CustomDrink.create(
      id: 'custom-test',
      name: '  ',
      spoons: 0,
      syrupPumps: 1,
    );
    expect(drink.name, 'Minuman racikan');
    expect(drink.grams, 5);
    expect(drink.estimated, isTrue);
  });

  testWidgets('custom drink preview updates and saves to dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    final drinkLog = DrinkLogController();
    addTearDown(router.dispose);
    addTearDown(drinkLog.dispose);
    router.go('/manual/add');

    await tester.pumpWidget(
      StevAiApp(router: router, drinkLogController: drinkLog),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('≈12.5'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('customDrinkNameField')),
      'Es kopi racikan',
    );
    await tester.tap(find.byKey(const ValueKey('spoonsPlus')));
    await tester.tap(find.byKey(const ValueKey('syrupPlus')));
    await tester.tap(find.byKey(const ValueKey('syrupPlus')));
    await tester.pump();

    expect(find.text('≈35'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('saveCustomDrinkButton')),
    );
    await tester.tap(find.byKey(const ValueKey('saveCustomDrinkButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    expect(find.text('Es kopi racikan'), findsOneWidget);
    expect(find.text('≈35 g'), findsOneWidget);
    expect(drinkLog.totalGrams, 35);
    expect(tester.takeException(), isNull);
  });
}
