import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import 'widgets/daily_sugar_card.dart';
import 'widgets/drink_row.dart';
import 'widgets/week_strip.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  OnboardingProfile _profile = const OnboardingProfile();

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final profile = await OnboardingPreferences.readProfile();
    if (mounted) setState(() => _profile = profile);
  }

  @override
  Widget build(BuildContext context) {
    final drinkLog = DrinkLogScope.watch(context);

    return Scaffold(
      key: const ValueKey('dashboardScreen'),
      extendBody: true,
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s4,
              StevSpace.s5,
              128,
            ),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: StevLogo(markSize: 30),
              ),
              if (_profile.hasDetails) ...[
                const SizedBox(height: StevSpace.s5),
                _PersonalizedGreeting(profile: _profile),
              ],
              const SizedBox(height: StevSpace.s5),
              const WeekStrip(),
              const SizedBox(height: StevSpace.s5),
              DailySugarCard(totalGrams: drinkLog.totalGrams),
              const SizedBox(height: StevSpace.s10),
              Text('Hari ini', style: StevType.heading),
              const SizedBox(height: 14),
              for (var index = 0; index < drinkLog.entries.length; index++) ...[
                if (index > 0) const SizedBox(height: StevSpace.s3),
                DrinkRow(drink: drinkLog.entries[index]),
              ],
              if (drinkLog.entries.isNotEmpty) ...[
                const SizedBox(height: StevSpace.s10),
                const _RiskAssessmentCard(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.home,
        onHome: () {},
        onFamily: () => context.go('/family'),
        onScan: () => context.push('/scan'),
        onWeekly: () => context.go('/weekly'),
      ),
    );
  }
}

class _RiskAssessmentCard extends StatelessWidget {
  const _RiskAssessmentCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: const ValueKey('riskAssessmentCard'),
      padding: const EdgeInsets.all(StevSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cek risiko diabetes keluargamu',
                      style: StevType.heading,
                    ),
                    const SizedBox(height: StevSpace.s2),
                    Text(
                      '8 pertanyaan, 2 menit. Untuk kamu atau orang tuamu.',
                      style: StevType.body.copyWith(color: StevColors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: StevSpace.s3),
              const StevMascot(mood: StevMood.happy, size: 70),
            ],
          ),
          const SizedBox(height: StevSpace.s5),
          StevButton(
            label: 'Mulai cek',
            variant: StevButtonVariant.leaf,
            onPressed: () => context.push('/risk'),
          ),
        ],
      ),
    );
  }
}

class _PersonalizedGreeting extends StatelessWidget {
  const _PersonalizedGreeting({required this.profile});

  final OnboardingProfile profile;

  String get _title =>
      profile.name == null ? 'Halo!' : 'Halo, ${profile.name}!';

  String get _message => switch (profile.drinkTime) {
    'Pagi' => 'Sebelum mulai pagi, cek gula minumanmu dulu, yuk.',
    'Siang' => 'Siang biasanya waktu kamu beli minum. Scan dulu, yuk.',
    'Sore' => 'Sore biasanya waktu kamu beli minum. Cek gulanya dulu, yuk.',
    'Malam' => 'Mau beli minum malam ini? Cek gulanya sebelum pilih.',
    _ => 'Pantau gula minumanmu hari ini bersama Stev.',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$_title $_message',
      child: GlassCard(
        key: const ValueKey('personalizedGreeting'),
        padding: const EdgeInsets.all(StevSpace.s4),
        radius: StevRadius.row,
        child: Row(
          children: [
            const StevMascot(mood: StevMood.happy, size: 54),
            const SizedBox(width: StevSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title, style: StevType.label),
                  const SizedBox(height: StevSpace.s1),
                  Text(
                    _message,
                    style: StevType.caption.copyWith(color: StevColors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
