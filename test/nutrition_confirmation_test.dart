import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
import 'package:steviai/features/nutrition/domain/nutrition_label.dart';
import 'package:steviai/features/nutrition/presentation/nutrition_confirmation_screen.dart';
import 'package:steviai/shared/widgets/stev_button.dart';

void main() {
  for (final known in [true, false]) {
    testWidgets(
      'label confirmation requires valid quantity and acknowledgement (known=$known)',
      (tester) async {
        tester.view.physicalSize = known
            ? const Size(390, 844)
            : const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final log = DrinkLogController();
        final result = NutritionScanResult(
          photoBytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9qkAAAAASUVORK5CYII=',
          ),
          label: NutritionLabel(
            sugarGrams: 9,
            basis: NutritionBasis.perServing,
            servingsPerPackage: known ? 2 : null,
            sugarText: 'Gula 9 g',
            basisText: 'Per sajian',
            confidence: 0.95,
            productName: 'Teh uji',
          ),
        );
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
          ],
        );
        addTearDown(router.dispose);
        addTearDown(log.dispose);
        await tester.pumpWidget(
          StevAiApp(router: router, drinkLogController: log),
        );
        final servings = find.byKey(const ValueKey('nutritionServings'));
        final scrollable = find
            .descendant(
              of: find.byKey(const ValueKey('nutritionFormList')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(servings, 200, scrollable: scrollable);
        if (!known) {
          expect(
            tester.widget<TextFormField>(servings).controller!.text,
            isEmpty,
          );
          await tester.enterText(servings, '2');
          await tester.pump();
        }
        final save = find.byKey(const ValueKey('logNutritionDrink'));
        await tester.scrollUntilVisible(save, 200, scrollable: scrollable);
        expect(find.text('Gula yang dicatat: 18 g'), findsOneWidget);
        expect(tester.widget<StevButton>(save).onPressed, isNull);
        expect(log.entries, isEmpty);
        if (known) {
          final fraction = find.byKey(
            const ValueKey('nutritionConsumedFraction'),
          );
          await tester.ensureVisible(fraction);
          await tester.tap(fraction);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text('Setengah kemasan').last);
          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text('Gula yang dicatat: 9 g'), findsOneWidget);
        }
        final checkbox = find.byKey(const ValueKey('confirmNutritionLabel'));
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pump();
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(log.entries.single.grams, known ? 9 : 18);
        expect(
          log.entries.single.drink.validationStatus,
          DrinkValidationStatus.unverified,
        );
        expect(find.text('Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'manual label stays empty and accessible when camera is unavailable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = createAppRouter(onboardingComplete: true);
      final log = DrinkLogController();
      addTearDown(router.dispose);
      addTearDown(log.dispose);
      router.go('/scan/label');
      await tester.pumpWidget(
        StevAiApp(router: router, drinkLogController: log),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('manualNutritionLabel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Isi label manual'), findsOneWidget);
      final sugar = find.byKey(const ValueKey('nutritionSugar'));
      expect(tester.widget<TextFormField>(sugar).controller!.text, isEmpty);
      expect(log.entries, isEmpty);
      router.go('/');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    },
  );
}
