import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/app/app.dart';
import 'package:steviai/app/router.dart';
import 'package:steviai/features/drinks/application/drink_log_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/drinks/data/drink_log_preferences.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
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

  testWidgets('profile tab opens the profile screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(StevAiApp(router: router));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const ValueKey('profileScreen')), findsOneWidget);
    expect(find.byKey(const ValueKey('editProfileButton')), findsOneWidget);
  });

  testWidgets('today drink can be deleted after confirmation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final drinkLog = DrinkLogController(
      initialEntries: const [
        DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
      ],
    );
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    addTearDown(drinkLog.dispose);
    await tester.pumpWidget(
      StevAiApp(router: router, drinkLogController: drinkLog),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const ValueKey('deleteDrink-teh-melati-kotak')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hapus minuman?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirmDeleteDrinkButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(drinkLog.entries, isEmpty);
    expect(find.byKey(const ValueKey('emptyDrinkLog')), findsOneWidget);
  });

  testWidgets('past day shows stored drink history', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = DrinkLogPreferences();
    final today = DateTime(2026, 10, 14);
    final yesterday = DateTime(2026, 10, 13);
    await storage.write(yesterday, const [
      DrinkSelection(drink: DrinkCatalog.tehMelatiKotak),
    ]);
    final drinkLog = await DrinkLogController.persistent(
      preferences: storage,
      now: today,
    );
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    addTearDown(drinkLog.dispose);
    await tester.pumpWidget(
      StevAiApp(router: router, drinkLogController: drinkLog),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('weekDay-2026-10-13')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Kemarin'), findsOneWidget);
    expect(find.text('Teh melati kotak'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('deleteDrink-teh-melati-kotak')),
      findsNothing,
    );
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

  testWidgets('newly logged drinks animate into the first dashboard row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final drinkLog = DrinkLogController();
    final router = createAppRouter(onboardingComplete: true);
    addTearDown(router.dispose);
    addTearDown(drinkLog.dispose);
    drinkLog.log(const DrinkSelection(drink: DrinkCatalog.esKopiSusuGulaAren));

    await tester.pumpWidget(
      StevAiApp(router: router, drinkLogController: drinkLog),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(const ValueKey('loggedDrinkFlight')), findsOneWidget);
    expect(find.text('Es kopi susu gula aren'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('loggedDrinkFlight')), findsNothing);
    expect(drinkLog.takePendingLoggedEvent(), isNull);
  });
}
