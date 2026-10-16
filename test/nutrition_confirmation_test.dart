import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
import 'package:steviai/features/nutrition/domain/nutrition_label.dart';
import 'package:steviai/features/nutrition/presentation/nutrition_confirmation_screen.dart';
import 'package:steviai/shared/widgets/stev_button.dart';

NutritionScanResult scannedLabel(NutritionLabel label) => NutritionScanResult(
  barcode: '8992858527308',
  photoBytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9qkAAAAASUVORK5CYII=',
  ),
  label: label,
);

Future<DrinkLogController> mountLabel(
  WidgetTester tester,
  NutritionScanResult? result, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final log = DrinkLogController();
  final router = GoRouter(
    initialLocation: '/confirm',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/confirm',
        builder: (_, _) => NutritionConfirmationScreen(result: result),
      ),
      GoRoute(
        path: '/scan/label',
        builder: (_, _) => const Scaffold(body: Text('Retake camera')),
      ),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(log.dispose);
  await tester.pumpWidget(StevAiApp(router: router, drinkLogController: log));
  await tester.pumpAndSettle();
  return log;
}

Future<void> tapLabel(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'label preview prioritizes net volume quietly; button is the confirmation',
    (tester) async {
      final log = await mountLabel(
        tester,
        scannedLabel(
          const NutritionLabel(
            productName: 'Pocari Sweat',
            sugarGrams: 14,
            basis: NutritionBasis.perServing,
            servingMl: 250,
            packageMl: 350,
            servingsPerPackage: 1.5,
            sugarText: 'Gula 14 g',
            basisText: 'Per 250 ml',
            confidence: .95,
          ),
        ),
      );
      expect(find.text('19,6 g'), findsOneWidget);
      expect(find.text('14 g per 250 ml · isi 350 ml'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.byType(DropdownButtonFormField<double>), findsNothing);
      expect(
        find.byKey(const ValueKey('nutritionVolumeWarning')),
        findsNothing,
      );
      expect(find.text('Teks yang terbaca'), findsNothing);
      expect(find.text('Disimpan untuk kamu saja'), findsOneWidget);
      expect(log.entries, isEmpty);
      await tapLabel(tester, 'logNutritionDrink');
      expect(log.entries.single.grams, closeTo(19.6, .000001));
      expect(
        log.entries.single.drink.validationStatus,
        DrinkValidationStatus.unverified,
      );
      expect(find.text('Home'), findsOneWidget);
    },
  );
  for (final basis in [NutritionBasis.per100Ml, NutritionBasis.perPackage]) {
    testWidgets('correctly previews $basis without exposing a basis selector', (
      tester,
    ) async {
      final log = await mountLabel(
        tester,
        scannedLabel(
          NutritionLabel(
            productName: 'Teh uji',
            sugarGrams: 6,
            basis: basis,
            packageMl: 300,
            sugarText: '6 g',
            basisText: basis.label,
            confidence: .95,
          ),
        ),
      );
      expect(
        find.text(basis == NutritionBasis.per100Ml ? '18 g' : '6 g'),
        findsOneWidget,
      );
      await tapLabel(tester, 'logNutritionDrink');
      expect(
        log.entries.single.grams,
        basis == NutritionBasis.per100Ml ? 18 : 6,
      );
    });
  }
  testWidgets(
    'unknown net volume never defaults to serving or rounded serving count',
    (tester) async {
      final log = await mountLabel(
        tester,
        scannedLabel(
          const NutritionLabel(
            productName: 'Pocari Sweat',
            sugarGrams: 14,
            basis: NutritionBasis.perServing,
            servingMl: 250,
            servingsPerPackage: 1.5,
            sugarText: '14 g',
            basisText: '250 ml',
            confidence: .95,
          ),
        ),
      );
      expect(find.text('21 g'), findsNothing);
      expect(find.text('Lengkapi ukuran kemasan'), findsOneWidget);
      expect(log.entries, isEmpty);
      await tapLabel(tester, 'logNutritionDrink');
      final volume = find.byKey(const ValueKey('nutritionVolume'));
      expect(tester.widget<TextFormField>(volume).controller!.text, isEmpty);
      await tester.ensureVisible(volume);
      await tester.enterText(volume, '250');
      await tester.pump();
      await tapLabel(tester, 'logNutritionDrink');
      expect(log.entries.single.grams, 14);
      expect(log.entries.single.drink.dataType, DrinkDataType.custom);
      expect(find.text('Home'), findsOneWidget);
    },
  );
  testWidgets(
    'editing normalizes per-100ml into four fields, stays private, and can cancel',
    (tester) async {
      final log = await mountLabel(
        tester,
        scannedLabel(
          const NutritionLabel(
            productName: 'Teh',
            sugarGrams: 6,
            basis: NutritionBasis.per100Ml,
            packageMl: 300,
            sugarText: '6 g',
            basisText: '100 ml',
            confidence: .95,
          ),
        ),
      );
      await tapLabel(tester, 'editNutritionNumbers');
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('nutritionServingMl')),
            )
            .controller!
            .text,
        '100',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('18 g'), findsOneWidget);
      expect(log.entries, isEmpty);
      await tapLabel(tester, 'editNutritionNumbers');
      final volume = find.byKey(const ValueKey('nutritionVolume'));
      await tester.ensureVisible(volume);
      await tester.enterText(volume, '150');
      await tester.pump();
      await tapLabel(tester, 'logNutritionDrink');
      expect(log.entries.single.grams, 9);
      expect(log.entries.single.drink.dataType, DrinkDataType.custom);
      expect(find.text('Home'), findsOneWidget);
    },
  );
  testWidgets(
    'manual has four fields; decimal comma, zero sugar, and small screens work',
    (tester) async {
      final log = await mountLabel(tester, null, size: const Size(320, 568));
      expect(find.byType(TextFormField), findsNWidgets(4));
      final button = find.byKey(const ValueKey('logNutritionDrink'));
      expect(tester.widget<StevButton>(button).onPressed, isNull);
      for (final pair in {
        'nutritionName': 'Air uji',
        'nutritionSugar': '0',
        'nutritionServingMl': '100,5',
        'nutritionVolume': '201',
      }.entries) {
        final field = find.byKey(ValueKey(pair.key));
        await tester.ensureVisible(field);
        await tester.enterText(field, pair.value);
        await tester.pump();
      }
      await tapLabel(tester, 'logNutritionDrink');
      expect(log.entries.single.grams, 0);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('manual remains accessible when label camera is unavailable', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          (call) async => call.method == 'availableCameras' ? [] : null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/camera'),
            null,
          ),
    );
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    router.go('/scan/label');
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manualNutritionLabel')));
    await tester.pumpAndSettle();
    expect(find.text('Isi dari label'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('nutritionSugar')))
          .controller!
          .text,
      isEmpty,
    );
  });
}
