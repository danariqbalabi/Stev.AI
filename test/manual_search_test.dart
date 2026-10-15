import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';

void main() {
  testWidgets('search filters catalog names case-insensitively', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/manual');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    final searchField = tester.widget<TextField>(
      find.byKey(const ValueKey('manualSearchField')),
    );
    expect(searchField.textAlignVertical, TextAlignVertical.center);
    expect(searchField.decoration?.isDense, isTrue);
    expect(searchField.decoration?.contentPadding, EdgeInsets.zero);
    await tester.enterText(
      find.byKey(const ValueKey('manualSearchField')),
      'KOPI',
    );
    await tester.pump();

    expect(find.text('Es kopi susu gula aren'), findsOneWidget);
    expect(find.text('Kopi susu kaleng Nescafe'), findsOneWidget);
    expect(find.text('Es teh manis'), findsNothing);
    expect(find.text('Boba milk tea'), findsNothing);
  });

  testWidgets('category and query filters work together', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/manual');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-packaged')));
    await tester.pump();

    expect(find.text('Kopi susu kaleng Nescafe'), findsOneWidget);
    expect(find.text('Susu cokelat kotak Ultra'), findsOneWidget);
    expect(find.text('Sprite botol'), findsOneWidget);
    expect(find.text('Hydro Coco'), findsOneWidget);
    expect(find.text('Teh melati kotak'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('manualSearchField')),
      'sprite',
    );
    await tester.pump();
    expect(find.text('Sprite botol'), findsOneWidget);
    expect(find.text('Hydro Coco'), findsNothing);
  });

  testWidgets('selecting a result opens its dynamic result screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/manual');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manualSearchField')),
      'matcha',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('manualDrink-matcha')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const ValueKey('resultScreen')), findsOneWidget);
    expect(find.text('Matcha'), findsOneWidget);
    expect(find.text('≈20 g'), findsOneWidget);
    expect(find.byKey(const ValueKey('sugarLevel-normal')), findsOneWidget);
  });

  testWidgets('empty state can open the custom drink form', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/manual');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manualSearchField')),
      'tidak ada',
    );
    await tester.pump();

    expect(find.text('Minuman belum ditemukan.'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('addCustomDrinkButton')),
    );
    await tester.tap(find.byKey(const ValueKey('addCustomDrinkButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('customDrinkScreen')), findsOneWidget);
  });
}
