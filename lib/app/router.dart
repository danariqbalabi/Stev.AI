import 'package:go_router/go_router.dart';

import '../features/confirmation/presentation/confirmation_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/result/presentation/result_screen.dart';
import '../features/scan/presentation/scan_screen.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
    GoRoute(
      path: '/confirmation',
      builder: (context, state) => const ConfirmationScreen(),
    ),
    GoRoute(path: '/result', builder: (context, state) => const ResultScreen()),
  ],
);
