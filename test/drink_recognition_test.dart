import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/features/confirmation/presentation/confirmation_screen.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/recognition/data/demo_drink_recognition_service.dart';
import 'package:steviai/features/recognition/domain/drink_recognition.dart';

void main() {
  test('demo recognition returns the three ordered candidates', () async {
    const service = DemoDrinkRecognitionService(latency: Duration.zero);

    final candidates = await service.identify(Uint8List.fromList([1]));

    expect(candidates, [
      DrinkCatalog.kopiSusuKalengNescafe,
      DrinkCatalog.esKopiSusuGulaAren,
      DrinkCatalog.bobaMilkTea,
    ]);
  });

  test('demo recognition rejects an empty photo', () async {
    const service = DemoDrinkRecognitionService(latency: Duration.zero);

    expect(
      () => service.identify(Uint8List(0)),
      throwsA(isA<DrinkRecognitionException>()),
    );
  });

  testWidgets('confirmation renders dynamic recognition candidates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ConfirmationScreen(
          candidates: [
            DrinkCatalog.hydroCoco,
            DrinkCatalog.spriteBotol,
            DrinkCatalog.esJeruk,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hydro Coco'), findsOneWidget);
    expect(find.text('Sprite botol'), findsOneWidget);
    expect(find.text('Es jeruk'), findsOneWidget);
    expect(find.text('Kopi susu kaleng Nescafe'), findsNothing);
  });
}
