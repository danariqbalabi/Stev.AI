import 'package:flutter/material.dart';

import '../core/theme/stev_theme.dart';
import 'router.dart';

class StevAiApp extends StatelessWidget {
  const StevAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stev.AI',
      debugShowCheckedModeBanner: false,
      theme: StevTheme.light,
      routerConfig: appRouter,
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
    );
  }
}
