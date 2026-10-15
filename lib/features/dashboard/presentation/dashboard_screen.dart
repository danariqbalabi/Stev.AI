import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../../shared/widgets/drink_photo.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/domain/drink.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import 'widgets/daily_sugar_card.dart';
import 'widgets/drink_row.dart';
import 'widgets/week_strip.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  OnboardingProfile _profile = const OnboardingProfile();
  late final AnimationController _loggedController;
  final _bodyKey = GlobalKey();
  final _firstRowKey = GlobalKey();
  DrinkLogController? _drinkLogController;
  DrinkSelection? _flightSelection;
  double _previousTotalGrams = 0;
  Offset _flightStart = Offset.zero;
  Offset _flightTarget = Offset.zero;
  bool _flightReady = false;

  @override
  void initState() {
    super.initState();
    _loggedController =
        AnimationController(vsync: this, duration: StevMotion.logFlight)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() {
                _flightSelection = null;
                _flightReady = false;
              });
            }
          });
    unawaited(_loadProfile());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DrinkLogScope.read(context);
    if (!identical(controller, _drinkLogController)) {
      _drinkLogController = controller;
    }
    final event = controller.takePendingLoggedEvent();
    if (event != null) {
      _flightSelection = event.selection;
      _previousTotalGrams = event.previousTotalGrams;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startLoggedAnimation();
      });
    }
  }

  void _startLoggedAnimation() {
    final bodyBox = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    final rowBox =
        _firstRowKey.currentContext?.findRenderObject() as RenderBox?;
    if (bodyBox == null || rowBox == null) {
      setState(() => _flightSelection = null);
      return;
    }
    final bodyOrigin = bodyBox.localToGlobal(Offset.zero);
    final rowOrigin = rowBox.localToGlobal(Offset.zero) - bodyOrigin;
    _flightStart = Offset(
      (bodyBox.size.width - StevSize.drinkRow) / 2,
      bodyBox.size.height * 0.48,
    );
    _flightTarget = rowOrigin;
    _flightReady = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _loggedController.duration = reduceMotion
        ? StevMotion.reduced
        : StevMotion.logFlight;
    _loggedController.forward(from: 0);
  }

  @override
  void dispose() {
    _loggedController.dispose();
    super.dispose();
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
      body: AnimatedBuilder(
        animation: _loggedController,
        builder: (context, _) {
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          final progress = _loggedController.value;
          final displayedTotal = _flightSelection == null || reduceMotion
              ? drinkLog.totalGrams
              : lerpDouble(
                  _previousTotalGrams,
                  drinkLog.totalGrams,
                  StevMotion.outExpo.transform(progress),
                )!.roundToDouble();
          return Stack(
            key: _bodyKey,
            children: [
              Positioned.fill(
                child: AuraBackground(
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
                        DailySugarCard(totalGrams: displayedTotal),
                        const SizedBox(height: StevSpace.s10),
                        Text('Hari ini', style: StevType.heading),
                        const SizedBox(height: 14),
                        for (
                          var index = 0;
                          index < drinkLog.entries.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: StevSpace.s3),
                          KeyedSubtree(
                            key: index == 0 ? _firstRowKey : null,
                            child: index == 0 && _flightSelection != null
                                ? _LoggedRowEntrance(
                                    animation: _loggedController,
                                    reduceMotion: reduceMotion,
                                    child: DrinkRow(
                                      drink: drinkLog.entries[index],
                                    ),
                                  )
                                : DrinkRow(drink: drinkLog.entries[index]),
                          ),
                        ],
                        if (drinkLog.entries.isNotEmpty) ...[
                          const SizedBox(height: StevSpace.s10),
                          const _RiskAssessmentCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (_flightReady)
                if (_flightSelection case final selection?)
                  _LoggedDrinkFlight(
                    selection: selection,
                    progress: progress,
                    start: _flightStart,
                    target: _flightTarget,
                    reduceMotion: reduceMotion,
                  ),
            ],
          );
        },
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

class _LoggedRowEntrance extends StatelessWidget {
  const _LoggedRowEntrance({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = StevMotion.outExpo.transform(animation.value);
    return Opacity(
      opacity: progress.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, reduceMotion ? 0 : -24 * (1 - progress)),
        child: child,
      ),
    );
  }
}

class _LoggedDrinkFlight extends StatelessWidget {
  const _LoggedDrinkFlight({
    required this.selection,
    required this.progress,
    required this.start,
    required this.target,
    required this.reduceMotion,
  });

  final DrinkSelection selection;
  final double progress;
  final Offset start;
  final Offset target;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final travelProgress = StevMotion.outExpo.transform(
      (progress / 0.7).clamp(0, 1),
    );
    final position = reduceMotion
        ? target
        : Offset.lerp(start, target, travelProgress)!;
    final fadeProgress = progress <= 0.7
        ? 0.0
        : ((progress - 0.7) / 0.3).clamp(0, 1);
    final opacity = reduceMotion ? 1 - progress : 1 - fadeProgress;
    final scale = reduceMotion ? 1.0 : lerpDouble(1.2, 1, travelProgress)!;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: IgnorePointer(
        child: Opacity(
          key: const ValueKey('loggedDrinkFlight'),
          opacity: opacity.clamp(0, 1).toDouble(),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: StevSize.drinkRow,
              height: StevSize.drinkRow,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: StevColors.card,
                borderRadius: BorderRadius.circular(StevRadius.row),
                border: Border.all(color: StevColors.onInk, width: 3),
                boxShadow: StevShadows.elevFloat,
              ),
              child: DrinkPhoto(drink: selection.drink),
            ),
          ),
        ),
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
