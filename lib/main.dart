import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'features/drinks/application/drink_log_controller.dart';
import 'features/home_widget/application/home_widget_bridge.dart';
import 'features/onboarding/data/onboarding_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final onboardingComplete = await OnboardingPreferences.isComplete();
  final drinkLogController = await DrinkLogController.persistent();
  final router = createAppRouter(onboardingComplete: onboardingComplete);
  await HomeWidgetBridge.initialize(router);
  await HomeWidgetBridge.update();
  drinkLogController.addListener(() async {
    await drinkLogController.flush();
    await HomeWidgetBridge.update();
  });

  runApp(StevAiApp(router: router, drinkLogController: drinkLogController));
}
