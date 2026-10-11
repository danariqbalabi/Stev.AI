import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';

void main() {
  testWidgets('confirmation shows the ordered guesses from the handoff', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/confirmation');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('confirmationScreen')), findsOneWidget);
    expect(find.text('Ini minuman apa?'), findsOneWidget);
    expect(find.text('Pilih yang paling cocok'), findsOneWidget);
    expect(find.text('Kopi susu kaleng Nescafe'), findsOneWidget);
    expect(find.text('Es kopi susu gula aren'), findsOneWidget);
    expect(find.text('Boba milk tea'), findsOneWidget);
    expect(find.text('Paling cocok'), findsOneWidget);
    expect(find.text('Normal'), findsNothing);
    expect(find.text('Less sugar'), findsNothing);
    expect(find.text('No sugar'), findsNothing);
  });

  testWidgets('a guess opens result with the selected drink data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/confirmation');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('guess-es-kopi-susu-gula-aren')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Es kopi susu gula aren'), findsOneWidget);
    expect(find.text('≈36 g'), findsOneWidget);
    expect(find.text('estimasi gula · data demo'), findsOneWidget);
  });

  testWidgets('manual search fallback explains that it is coming next', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/confirmation');

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manualSearchButton')));
    await tester.pump();

    expect(find.text('Pencarian manual segera hadir.'), findsOneWidget);
  });
}
