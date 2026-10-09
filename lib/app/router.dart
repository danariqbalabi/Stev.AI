import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/stev_tokens.dart';
import '../features/confirmation/presentation/confirmation_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_profile_screen.dart';
import '../features/onboarding/presentation/onboarding_welcome_screen.dart';
import '../features/result/presentation/result_screen.dart';
import '../features/scan/presentation/scan_screen.dart';

GoRouter createAppRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: onboardingComplete ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const OnboardingWelcomeScreen()),
      ),
      GoRoute(
        path: '/onboarding/profile',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const OnboardingProfileScreen()),
      ),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) => const ConfirmationScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
    ],
  );
}

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: StevMotion.screenFade,
    reverseTransitionDuration: StevMotion.screenFade,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

final GoRouter appRouter = createAppRouter(onboardingComplete: true);
