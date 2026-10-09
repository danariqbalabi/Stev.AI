import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s5,
              StevSpace.s5,
              33,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StevLogo(markSize: 30),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AnimatedStevMascot(
                            mood: StevMood.cheer,
                            size: StevSize.stevOnboarding,
                            wave: true,
                          ),
                          const SizedBox(height: 43),
                          Text(
                            'Lihat gula sebelum kamu beli.',
                            textAlign: TextAlign.center,
                            style: StevType.onboardingTitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                StevButton(
                  key: const ValueKey('onboardingStartButton'),
                  label: 'Mulai',
                  onPressed: () => context.push('/onboarding/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
