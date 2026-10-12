import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';

class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key});

  static const savedGrams = 46;
  static const days = <WeeklySugarDay>[
    WeeklySugarDay(label: 'Sen', grams: 38),
    WeeklySugarDay(label: 'Sel', grams: 55),
    WeeklySugarDay(label: 'Rab', grams: 41),
    WeeklySugarDay(label: 'Kam', grams: 42),
    WeeklySugarDay(label: 'Jum'),
    WeeklySugarDay(label: 'Sab'),
    WeeklySugarDay(label: 'Min'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('weeklyScreen'),
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
            children: const [
              Align(
                alignment: Alignment.centerLeft,
                child: StevLogo(markSize: 30),
              ),
              SizedBox(height: StevSpace.s10),
              _WeeklySummary(savedGrams: savedGrams),
              SizedBox(height: 38),
              _WeeklyChartCard(days: days),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.weekly,
        onHome: () => context.go('/'),
        onScan: () => context.push('/scan'),
        onWeekly: () {},
      ),
    );
  }
}

class WeeklySugarDay {
  const WeeklySugarDay({required this.label, this.grams});

  final String label;
  final double? grams;
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.savedGrams});

  final int savedGrams;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minggu ini hemat', style: StevType.heading),
        const SizedBox(height: StevSpace.s1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$savedGrams',
              key: const ValueKey('weeklySavedGrams'),
              style: StevType.number.copyWith(fontFeatures: StevType.tabular),
            ),
            const SizedBox(width: 2),
            Text(
              'g',
              style: StevType.unitHome.copyWith(color: StevColors.ink2),
            ),
          ],
        ),
        const SizedBox(height: StevSpace.s1),
        Text(
          'lewat swap',
          style: StevType.caption.copyWith(color: StevColors.ink2),
        ),
      ],
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.days});

  final List<WeeklySugarDay> days;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gula harian', style: StevType.heading),
                const SizedBox(height: StevSpace.s5),
                Expanded(child: _WeeklyBarChart(days: days)),
              ],
            ),
          ),
        ),
        const Positioned(
          top: -28,
          right: 18,
          child: AnimatedStevMascot(size: StevSize.stevHome),
        ),
      ],
    );
  }
}

class _WeeklyBarChart extends StatefulWidget {
  const _WeeklyBarChart({required this.days});

  final List<WeeklySugarDay> days;

  @override
  State<_WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<_WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  static const _trackHeight = 210.0;
  static const _maximumGrams = 60.0;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: StevMotion.outExpo,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduceMotion
        ? StevMotion.reduced
        : StevMotion.chartGrow;
    if (!_controller.isCompleted && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const semanticsLabel =
        'Gula harian: Senin 38 gram, Selasa 55 gram, Rabu 41 gram, '
        'Kamis 42 gram, Jumat sampai Minggu belum ada data. Batas 50 gram.';

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 244,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < widget.days.length; index++) ...[
                    if (index > 0) const SizedBox(width: StevSpace.s2),
                    Expanded(
                      child: _DayBar(
                        key: ValueKey('weeklyBar-$index'),
                        day: widget.days[index],
                        trackHeight: _trackHeight,
                        maximumGrams: _maximumGrams,
                        animation: _animation,
                      ),
                    ),
                  ],
                ],
              ),
              const Positioned(top: 34, left: 0, right: 0, child: _LimitLine()),
              Positioned(
                top: 16,
                right: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: StevColors.card),
                  child: Padding(
                    padding: const EdgeInsets.only(left: StevSpace.s1),
                    child: Text(
                      '50 g',
                      style: StevType.micro.copyWith(color: StevColors.ink2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    super.key,
    required this.day,
    required this.trackHeight,
    required this.maximumGrams,
    required this.animation,
  });

  final WeeklySugarDay day;
  final double trackHeight;
  final double maximumGrams;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final grams = day.grams;
    final barHeight = grams == null
        ? 0.0
        : (grams / maximumGrams).clamp(0, 1) * trackHeight;
    final color = (grams ?? 0) > StevSugar.dailyLimit
        ? StevColors.over
        : StevColors.ink;

    return Column(
      children: [
        SizedBox(
          height: trackHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                alignment: Alignment.bottomCenter,
                scale: animation,
                child: Container(
                  width: 22,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(StevSpace.s2),
                      bottom: Radius.circular(StevSpace.s1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(day.label, style: StevType.micro.copyWith(color: StevColors.ink2)),
      ],
    );
  }
}

class _LimitLine extends StatelessWidget {
  const _LimitLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dashWidth = 5.0;
          const gap = 4.0;
          final count = (constraints.maxWidth / (dashWidth + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => const SizedBox(
                width: dashWidth,
                height: 1,
                child: ColoredBox(color: StevColors.ink2),
              ),
            ),
          );
        },
      ),
    );
  }
}
