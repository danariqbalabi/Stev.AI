import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/stev_theme.dart';
import '../features/drinks/application/drink_log_controller.dart';
import 'router.dart';

class StevAiApp extends StatefulWidget {
  const StevAiApp({super.key, this.router, this.drinkLogController});

  final GoRouter? router;
  final DrinkLogController? drinkLogController;

  @override
  State<StevAiApp> createState() => _StevAiAppState();
}

class _StevAiAppState extends State<StevAiApp> {
  late final DrinkLogController _drinkLogController;
  late final bool _ownsDrinkLogController;

  @override
  void initState() {
    super.initState();
    _ownsDrinkLogController = widget.drinkLogController == null;
    _drinkLogController =
        widget.drinkLogController ?? DrinkLogController.demo();
  }

  @override
  void dispose() {
    if (_ownsDrinkLogController) _drinkLogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrinkLogScope(
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
    );
  }
}
