import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/stev_theme.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/supabase_auth_gateway.dart';
import '../features/drinks/application/drink_log_controller.dart';
import '../features/drinks/application/drink_catalog_controller.dart';
import '../features/family/application/family_controller.dart';
import 'router.dart';

class StevAiApp extends StatefulWidget {
  const StevAiApp({
    super.key,
    this.router,
    this.authController,
    this.drinkLogController,
    this.drinkCatalogController,
    this.familyController,
  });

  final GoRouter? router;
  final AuthController? authController;
  final DrinkLogController? drinkLogController;
  final DrinkCatalogController? drinkCatalogController;
  final FamilyController? familyController;

  @override
  State<StevAiApp> createState() => _StevAiAppState();
}

class _StevAiAppState extends State<StevAiApp> with WidgetsBindingObserver {
  late final DrinkLogController _drinkLogController;
  late final AuthController _authController;
  late final bool _ownsAuthController;
  late final bool _ownsDrinkLogController;
  late final DrinkCatalogController _drinkCatalogController;
  late final bool _ownsDrinkCatalogController;
  late final FamilyController _familyController;
  late final bool _ownsFamilyController;
  Timer? _dayRolloverTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsAuthController = widget.authController == null;
    _authController =
        widget.authController ?? AuthController(SupabaseAuthGateway(null));
    _ownsDrinkLogController = widget.drinkLogController == null;
    _drinkLogController =
        widget.drinkLogController ?? DrinkLogController.demo();
    _ownsDrinkCatalogController = widget.drinkCatalogController == null;
    _drinkCatalogController =
        widget.drinkCatalogController ??
        DrinkCatalogController.forBackend(null);
    _ownsFamilyController = widget.familyController == null;
    _familyController = widget.familyController ?? FamilyController();
    _scheduleDayRollover();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshCurrentDate());
    }
  }

  void _scheduleDayRollover() {
    _dayRolloverTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _dayRolloverTimer = Timer(nextDay.difference(now), () {
      unawaited(_refreshCurrentDate());
    });
  }

  Future<void> _refreshCurrentDate() async {
    await _drinkLogController.refreshForCurrentDate();
    if (mounted) _scheduleDayRollover();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayRolloverTimer?.cancel();
    if (_ownsAuthController) _authController.dispose();
    if (_ownsDrinkLogController) _drinkLogController.dispose();
    if (_ownsDrinkCatalogController) _drinkCatalogController.dispose();
    if (_ownsFamilyController) _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _authController,
      child: FamilyScope(
        controller: _familyController,
        child: DrinkCatalogScope(
          controller: _drinkCatalogController,
          child: DrinkLogScope(
            controller: _drinkLogController,
            child: MaterialApp.router(
              title: 'Stev.AI',
              debugShowCheckedModeBanner: false,
              theme: StevTheme.light,
              routerConfig: widget.router ?? appRouter,
              builder: (context, child) {
                return ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
