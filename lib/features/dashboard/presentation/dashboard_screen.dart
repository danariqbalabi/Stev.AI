import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import 'widgets/daily_sugar_card.dart';
import 'widgets/drink_row.dart';
import 'widgets/week_strip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            ],
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.home,
        onHome: () {},
        onScan: () => context.push('/scan'),
        onWeekly: () => context.go('/weekly'),
      ),
    );
  }
}
