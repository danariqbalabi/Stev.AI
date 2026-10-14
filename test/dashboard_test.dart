import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';

void main() {
  testWidgets('dashboard shows the reference design demo state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    appRouter.go('/');
    await tester.pumpWidget(const StevAiApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    expect(find.text('32'), findsOneWidget);
    expect(find.text('/50 g'), findsOneWidget);
    expect(find.text('Gula hari ini'), findsOneWidget);
    expect(find.text('Teh melati kotak'), findsOneWidget);
    expect(find.text('18 g'), findsOneWidget);
    expect(find.text('Es teh manis'), findsOneWidget);
    expect(find.text('≈14 g'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Mingguan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly tab opens the weekly dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    appRouter.go('/');
    await tester.pumpWidget(const StevAiApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Mingguan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('weeklyScreen')), findsOneWidget);
    expect(find.text('Gula harian'), findsOneWidget);
  });
}
