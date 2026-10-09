import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../data/dashboard_demo_data.dart';
import 'widgets/daily_sugar_card.dart';
import 'widgets/drink_row.dart';
import 'widgets/week_strip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  double get _totalGrams =>
      dashboardDemoDrinks.fold(0, (total, drink) => total + drink.grams);

  @override
  Widget build(BuildContext context) {
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
              DailySugarCard(totalGrams: _totalGrams),
              const SizedBox(height: StevSpace.s10),
              Text('Hari ini', style: StevType.heading),
              const SizedBox(height: 14),
              for (
                var index = 0;
                index < dashboardDemoDrinks.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(height: StevSpace.s3),
                DrinkRow(drink: dashboardDemoDrinks[index]),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.home,
        onHome: () {},
        onScan: () => context.push('/scan'),
        onWeekly: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Text('Grafik mingguan segera hadir.'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.fromLTRB(
                  StevSpace.s5,
                  StevSpace.s5,
                  StevSpace.s5,
                  104,
                ),
                backgroundColor: StevColors.ink,
              ),
            );
        },
      ),
    );
  }
}
