import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';

void main() {
  testWidgets('scan chooser works on small screens before opening the camera', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/scan');
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump();

    expect(find.text('Foto Minuman'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Menyiapkan kamera...'), findsNothing);
    expect(find.byKey(const ValueKey('galleryButton')), findsNothing);

    for (final mode in ['label']) {
      final card = find.byKey(ValueKey('scanMode-$mode'));
      await tester.scrollUntilVisible(card, 100);
      final tapTarget = tester.widget<InkWell>(
        find.descendant(of: card, matching: find.byType(InkWell)),
      );
      expect(tapTarget.onTap, isNotNull);
      expect(find.text('Segera hadir'), findsNothing);
    }
    expect(find.text('Label Gizi'), findsOneWidget);

    final manual = find.byKey(const ValueKey('scanModesManualSearch'));
    await tester.scrollUntilVisible(manual, 100);
    await tester.tap(manual);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('manualSearchScreen')), findsOneWidget);
    expect(tester.takeException(), isNull);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('scanModesScreen')), findsOneWidget);
    expect(find.text('Menyiapkan kamera...'), findsNothing);
  });
}
