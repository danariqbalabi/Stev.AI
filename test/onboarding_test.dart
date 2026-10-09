import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/onboarding/data/onboarding_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch completes onboarding and saves profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: false);
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lihat gula sebelum kamu beli.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboardingStartButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Kenalan dulu, yuk.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('nameField')), 'Danan');
    await tester.tap(find.text('Sore'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('profileStartButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingPreferences.completeKey), isTrue);
    expect(preferences.getString(OnboardingPreferences.nameKey), 'Danan');
    expect(preferences.getString(OnboardingPreferences.drinkTimeKey), 'Sore');
  });

  testWidgets('returning user starts on dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingPreferences.completeKey: true,
    });
    final complete = await OnboardingPreferences.isComplete();
    final router = createAppRouter(onboardingComplete: complete);
    addTearDown(router.dispose);

    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump();

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    expect(find.text('Lihat gula sebelum kamu beli.'), findsNothing);
  });

  testWidgets('skip finishes onboarding without profile details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: false);
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('onboardingStartButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('skipOnboardingButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('dashboardScreen')), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool(OnboardingPreferences.completeKey), isTrue);
    expect(preferences.getString(OnboardingPreferences.nameKey), isNull);
    expect(preferences.getString(OnboardingPreferences.drinkTimeKey), isNull);
  });
}
