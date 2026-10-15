import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../domain/weekly_sugar_summary.dart';

class WeeklyScreen extends StatefulWidget {
  const WeeklyScreen({super.key});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  DrinkLogController? _controller;
  DateTime? _summaryDate;
  Future<WeeklySugarSummary>? _summary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DrinkLogScope.read(context);
    if (!identical(controller, _controller) ||
        !_isSameDay(_summaryDate, controller.currentDate)) {
      _controller = controller;
      _summaryDate = controller.currentDate;
      _summary = controller.loadWeeklySummary();
    }
  }

  bool _isSameDay(DateTime? first, DateTime second) =>
      first != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('weeklyScreen'),
      extendBody: true,
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<WeeklySugarSummary>(
            future: _summary,
            builder: (context, snapshot) {
              final summary = snapshot.data;
              if (summary == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    key: ValueKey('weeklyLoading'),
                    color: StevColors.ink,
                  ),
                );
              }
              return ListView(
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
                  const SizedBox(height: StevSpace.s10),
                  _WeeklySummary(savedGrams: summary.savedGrams),
                  const SizedBox(height: 38),
                  _WeeklyChartCard(days: summary.days),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.weekly,
        onHome: () => context.go('/'),
        onFamily: () => context.go('/family'),
        onScan: () => context.push('/scan'),
        onWeekly: () {},
        onProfile: () => context.go('/profile'),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.savedGrams});

  final double savedGrams;

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
              _numberLabel(savedGrams),
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

  final List<DailySugarSummary> days;

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

  final List<DailySugarSummary> days;

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
    final dayDescriptions = widget.days
        .map((day) {
          final grams = day.grams;
          return grams == null
              ? '${_longDayLabel(day.date)} belum ada data'
              : '${_longDayLabel(day.date)} ${_numberLabel(grams)} gram';
        })
        .join(', ');
    final semanticsLabel = 'Gula harian: $dayDescriptions. Batas 50 gram.';

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

  final DailySugarSummary day;
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
        Text(
          _shortDayLabel(day.date),
          style: StevType.micro.copyWith(color: StevColors.ink2),
        ),
      ],
    );
  }
}

const _shortDayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _longDayLabels = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

String _shortDayLabel(DateTime date) => _shortDayLabels[date.weekday - 1];

String _longDayLabel(DateTime date) => _longDayLabels[date.weekday - 1];

String _numberLabel(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
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
