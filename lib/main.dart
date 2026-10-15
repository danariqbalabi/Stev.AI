import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/config/stev_backend_config.dart';
import 'features/drinks/application/drink_catalog_controller.dart';
import 'features/drinks/application/drink_log_controller.dart';
import 'features/home_widget/application/home_widget_bridge.dart';
import 'features/family/application/family_controller.dart';
import 'features/onboarding/data/onboarding_preferences.dart';
import 'features/risk_assessment/data/risk_reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseClient = await StevBackendConfig.initialize();
  final drinkCatalogController = DrinkCatalogController.forBackend(
    supabaseClient,
  );
  unawaited(drinkCatalogController.refresh());
  final onboardingComplete = await OnboardingPreferences.isComplete();
  final drinkLogController = await DrinkLogController.persistent();
  final familyController = await FamilyController.persistent();
  final router = createAppRouter(onboardingComplete: onboardingComplete);
  await LocalRiskReminderScheduler.instance.initialize(
    onOpenRisk: () => router.go('/risk'),
  );
  await HomeWidgetBridge.initialize(router);
  await HomeWidgetBridge.update();
  drinkLogController.addListener(() async {
    await drinkLogController.flush();
    await HomeWidgetBridge.update();
  });

  runApp(
    StevAiApp(
      router: router,
      drinkLogController: drinkLogController,
      drinkCatalogController: drinkCatalogController,
      familyController: familyController,
    ),
  );
}
