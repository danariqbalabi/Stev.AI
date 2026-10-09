import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'features/onboarding/data/onboarding_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final onboardingComplete = await OnboardingPreferences.isComplete();

  runApp(
    StevAiApp(router: createAppRouter(onboardingComplete: onboardingComplete)),
  );
}
