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

    expect(candidates.map((candidate) => candidate.drink), [
      DrinkCatalog.kopiSusuKalengNescafe,
      DrinkCatalog.esKopiSusuGulaAren,
      DrinkCatalog.bobaMilkTea,
    ]);
    expect(candidates.map((candidate) => candidate.confidence), [
      0.92,
      0.76,
      0.63,
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
            DrinkRecognitionCandidate(
              drink: DrinkCatalog.hydroCoco,
              confidence: 0.94,
            ),
            DrinkRecognitionCandidate(
              drink: DrinkCatalog.spriteBotol,
              confidence: 0.81,
            ),
            DrinkRecognitionCandidate(
              drink: DrinkCatalog.esJeruk,
              confidence: 0.68,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hydro Coco'), findsOneWidget);
    expect(find.text('Sprite botol'), findsOneWidget);
    expect(find.text('Es jeruk'), findsOneWidget);
    expect(find.text('94% cocok'), findsOneWidget);
    expect(find.text('Kopi susu kaleng Nescafe'), findsNothing);
  });
}
