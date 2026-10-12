import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';

void main() {
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
    expect(find.text('Scan minuman'), findsOneWidget);
    expect(find.byKey(const ValueKey('manualSearchLink')), findsOneWidget);
  });
}
