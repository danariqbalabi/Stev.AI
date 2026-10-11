import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';

void main() {
  testWidgets('main demo flow reaches result and opens swap sheet', (
    tester,
  ) async {
    appRouter.go('/');
    await tester.pumpWidget(const StevAiApp());

    expect(find.text('Stev.AI'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scanButton')));
    // Do not settle indefinitely: the real camera loading state contains an
    // indeterminate progress indicator and requires a platform device.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Scan minuman'), findsOneWidget);
    expect(find.byKey(const ValueKey('galleryButton')), findsOneWidget);

    // The camera plugin requires a real browser or device, so the shell test
    // continues from the route that receives a captured image.
    appRouter.go('/confirmation');
    await tester.pumpAndSettle();
    expect(find.text('Ini minuman apa?'), findsOneWidget);
    expect(find.text('Pilih yang paling cocok'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('showResultButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Kopi susu kaleng Nescafe'), findsOneWidget);
    expect(find.text('30 g'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('swapButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('swapRewardOverlay')), findsOneWidget);
    expect(find.text('Mantap, hemat 8 g!'), findsOneWidget);
  });
}
