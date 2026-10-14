import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/onboarding/data/onboarding_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    expect(find.byKey(const ValueKey('riskAssessmentCard')), findsOneWidget);
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

  testWidgets('dashboard personalizes greeting from onboarding profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      OnboardingPreferences.nameKey: 'Danan',
      OnboardingPreferences.drinkTimeKey: 'Sore',
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('personalizedGreeting')), findsOneWidget);
    expect(find.text('Halo, Danan!'), findsOneWidget);
    expect(
      find.text('Sore biasanya waktu kamu beli minum. Cek gulanya dulu, yuk.'),
      findsOneWidget,
    );
  });
}
