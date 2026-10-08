import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/app/app.dart';

void main() {
  testWidgets('main demo flow reaches result and opens swap sheet', (
    tester,
  ) async {
    await tester.pumpWidget(const StevAiApp());

    expect(find.text('Stev.AI'), findsOneWidget);
    expect(find.text('12 g lagi'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('scanButton')));
    await tester.pumpAndSettle();
    expect(find.text('Scan minuman'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('captureButton')));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi minuman'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('showResultButton')));
    await tester.pumpAndSettle();
    expect(find.text('24 g'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('swapButton')));
    await tester.pumpAndSettle();
    expect(find.text('Swap ke yang lebih ringan'), findsOneWidget);
  });
}
