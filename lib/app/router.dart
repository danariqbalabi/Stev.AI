import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/stev_tokens.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/barcode/presentation/barcode_scan_screen.dart';
import '../features/nutrition/domain/nutrition_label.dart';
import '../features/nutrition/presentation/nutrition_confirmation_screen.dart';
import '../features/confirmation/presentation/confirmation_screen.dart';
import '../features/custom_drink/presentation/custom_drink_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/drinks/data/drink_catalog.dart';
import '../features/drinks/domain/drink.dart';
import '../features/family/presentation/family_screen.dart';
import '../features/manual_search/presentation/manual_search_screen.dart';
import '../features/onboarding/presentation/onboarding_profile_screen.dart';
import '../features/onboarding/presentation/onboarding_welcome_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/result/presentation/result_screen.dart';
import '../features/recognition/domain/drink_recognition.dart';
import '../features/risk_assessment/domain/risk_assessment.dart';
import '../features/risk_assessment/presentation/risk_assessment_screen.dart';
import '../features/risk_assessment/presentation/risk_invite_screen.dart';
import '../features/risk_assessment/presentation/risk_result_screen.dart';
import '../features/scan/presentation/scan_screen.dart';
import '../features/weekly/presentation/weekly_screen.dart';

GoRouter createAppRouter({required bool onboardingComplete}) {
  return GoRouter(
    initialLocation: onboardingComplete ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const AuthScreen()),
      ),
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
      GoRoute(
        path: '/family',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const FamilyScreen()),
      ),
      GoRoute(
        path: '/weekly',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const WeeklyScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const ProfileScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const OnboardingProfileScreen(editing: true),
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) =>
            const ScanScreen(key: ValueKey('photoCamera')),
      ),
      GoRoute(path: '/scan/photo', redirect: (context, state) => '/scan'),
      GoRoute(
        path: '/scan/barcode',
        builder: (context, state) => const BarcodeScanScreen(),
      ),
      GoRoute(
        path: '/scan/label',
        builder: (context, state) =>
            const ScanScreen(key: ValueKey('labelCamera'), labelMode: true),
      ),
      GoRoute(
        path: '/nutrition/manual',
        builder: (context, state) => const NutritionConfirmationScreen(),
      ),
      GoRoute(
        path: '/nutrition/confirm',
        redirect: (context, state) =>
            state.extra is NutritionScanResult ? null : '/scan/label',
        builder: (context, state) => NutritionConfirmationScreen(
          result: state.extra! as NutritionScanResult,
        ),
      ),
      GoRoute(
        path: '/manual',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const ManualSearchScreen()),
      ),
      GoRoute(
        path: '/manual/add',
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const CustomDrinkScreen()),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) {
          final recognition = state.extra is DrinkRecognitionResult
              ? state.extra! as DrinkRecognitionResult
              : null;
          return ConfirmationScreen(
            capturedPhoto:
                recognition?.photoBytes ??
                (state.extra is Uint8List ? state.extra! as Uint8List : null),
            candidates:
                recognition?.candidates ?? ConfirmationScreen.fallbackGuesses,
          );
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => ResultScreen(
          drink: state.extra is Drink
              ? state.extra! as Drink
              : DrinkCatalog.esTehManis,
        ),
      ),
      GoRoute(
        path: '/risk',
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: RiskAssessmentScreen(
            familyMemberId: state.extra is String
                ? state.extra! as String
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '/risk/result',
        builder: (context, state) {
          final result = state.extra;
          if (result is! RiskAssessmentResult) {
            return const RiskAssessmentScreen();
          }
          return RiskResultScreen(result: result);
        },
      ),
      GoRoute(
        path: '/risk/invite',
        pageBuilder: (context, state) {
          final result = state.extra is RiskAssessmentResult
              ? state.extra! as RiskAssessmentResult
              : null;
          return _fadePage(
            state: state,
            child: RiskInviteScreen(
              result:
                  result ??
                  const RiskAssessmentResult(
                    subject: RiskSubject.parent,
                    level: RiskLevel.medium,
                    topFactors: [],
                    score: 12,
                  ),
            ),
          );
        },
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
