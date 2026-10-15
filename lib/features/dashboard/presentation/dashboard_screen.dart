import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../../shared/widgets/drink_photo.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/data/drink_log_preferences.dart';
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
  DateTime? _selectedDate;
  StoredDrinkLog? _selectedDayLog;
  bool _loadingDay = false;
  UnderLimitStreak _streak = const UnderLimitStreak(
    days: 0,
    todayActive: false,
  );
  var _streakRequest = 0;

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
      _selectedDate = controller.currentDate;
    }
    unawaited(_refreshStreak());
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

  Future<void> _refreshStreak() async {
    final controller = _drinkLogController;
    if (controller == null) return;
    final request = ++_streakRequest;
    final streak = await controller.loadUnderLimitStreak();
    if (!mounted || request != _streakRequest) return;
    setState(() => _streak = streak);
  }

  Future<void> _checkIn() async {
    final controller = _drinkLogController;
    if (controller == null) return;
    controller.checkIn();
    await controller.flush();
    await _refreshStreak();
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  Future<void> _selectDate(DateTime date) async {
    final controller = _drinkLogController;
    if (controller == null || _loadingDay) return;
    if (_isSameDay(date, controller.currentDate)) {
      setState(() {
        _selectedDate = controller.currentDate;
        _selectedDayLog = null;
      });
      return;
    }

    setState(() {
      _loadingDay = true;
      _selectedDate = date;
    });
    final log = await controller.loadDay(date);
    if (!mounted || !_isSameDay(_selectedDate!, date)) return;
    setState(() {
      _selectedDayLog = log;
      _loadingDay = false;
    });
  }

  Future<void> _confirmDelete(DrinkSelection selection) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus minuman?'),
        content: Text(
          '${selection.drink.name} akan dihapus dari catatan hari ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const ValueKey('confirmDeleteDrinkButton'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      _drinkLogController?.remove(selection.identityId);
    }
  }

  String _dayHeading(DateTime selected, DateTime today) {
    if (_isSameDay(selected, today)) return 'Hari ini';
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(selected, yesterday)) return 'Kemarin';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[selected.weekday - 1]}, ${selected.day}/${selected.month}';
  }

  @override
  Widget build(BuildContext context) {
    final drinkLog = DrinkLogScope.watch(context);
    final selectedDate = _selectedDate ?? drinkLog.currentDate;
    final showingToday = _isSameDay(selectedDate, drinkLog.currentDate);
    final visibleEntries = showingToday
        ? drinkLog.entries
        : _selectedDayLog?.entries ?? const <DrinkSelection>[];
    final visibleTotal = showingToday
        ? drinkLog.totalGrams
        : _selectedDayLog?.totalGrams ?? 0;

    return Scaffold(
      key: const ValueKey('dashboardScreen'),
      extendBody: true,
      body: AnimatedBuilder(
        animation: _loggedController,
        builder: (context, _) {
          final reduceMotion = MediaQuery.disableAnimationsOf(context);
          final progress = _loggedController.value;
          final displayedTotal =
              !showingToday || _flightSelection == null || reduceMotion
              ? visibleTotal
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
                        WeekStrip(
                          today: drinkLog.currentDate,
                          selectedDate: selectedDate,
                          onSelected: _selectDate,
                        ),
                        const SizedBox(height: StevSpace.s5),
                        DailySugarCard(totalGrams: displayedTotal),
                        if (showingToday) ...[
                          const SizedBox(height: StevSpace.s4),
                          _UnderLimitStreakCard(
                            streak: _streak,
                            checkedIn: drinkLog.checkedInToday,
                            totalGrams: drinkLog.totalGrams,
                            onCheckIn: _checkIn,
                          ),
                        ],
                        const SizedBox(height: StevSpace.s10),
                        Text(
                          _dayHeading(selectedDate, drinkLog.currentDate),
                          style: StevType.heading,
                        ),
                        const SizedBox(height: 14),
                        if (_loadingDay)
                          const Center(child: CircularProgressIndicator())
                        else if (visibleEntries.isEmpty)
                          Text(
                            'Belum ada minuman tercatat.',
                            key: const ValueKey('emptyDrinkLog'),
                            style: StevType.body.copyWith(
                              color: StevColors.ink2,
                            ),
                          ),
                        for (
                          var index = 0;
                          index < visibleEntries.length;
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
                                      drink: visibleEntries[index],
                                      onDelete: showingToday
                                          ? () => _confirmDelete(
                                              visibleEntries[index],
                                            )
                                          : null,
                                    ),
                                  )
                                : DrinkRow(
                                    drink: visibleEntries[index],
                                    onDelete: showingToday
                                        ? () => _confirmDelete(
                                            visibleEntries[index],
                                          )
                                        : null,
                                  ),
                          ),
                        ],
                        if (showingToday) ...[
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
        onProfile: () => context.go('/profile'),
      ),
    );
  }
}

class _UnderLimitStreakCard extends StatelessWidget {
  const _UnderLimitStreakCard({
    required this.streak,
    required this.checkedIn,
    required this.totalGrams,
    required this.onCheckIn,
  });

  final UnderLimitStreak streak;
  final bool checkedIn;
  final double totalGrams;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final isUnderLimit = totalGrams <= 50;
    return GlassCard(
      key: const ValueKey('underLimitStreakCard'),
      padding: const EdgeInsets.all(StevSpace.s4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: streak.todayActive
                  ? StevColors.leaf.withValues(alpha: 0.16)
                  : StevColors.canvas,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '🔥',
                style: TextStyle(
                  fontSize: 24,
                  color: streak.todayActive ? null : StevColors.ink3,
                ),
              ),
            ),
          ),
          const SizedBox(width: StevSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak.todayActive
                      ? '${streak.days} hari di bawah 50 g'
                      : checkedIn && !isUnderLimit
                      ? 'Streak belum aktif'
                      : streak.days > 0
                      ? 'Lanjutkan streak ${streak.days} hari'
                      : 'Mulai streak di bawah 50 g',
                  key: const ValueKey('underLimitStreakTitle'),
                  style: StevType.label,
                ),
                const SizedBox(height: StevSpace.s1),
                Text(
                  checkedIn
                      ? isUnderLimit
                            ? 'Check-in hari ini berhasil.'
                            : 'Total hari ini melewati batas 50 g.'
                      : 'Check-in saat total harianmu masih di bawah batas.',
                  style: StevType.caption.copyWith(color: StevColors.ink2),
                ),
              ],
            ),
          ),
          if (!checkedIn)
            TextButton(
              key: const ValueKey('dailySugarCheckInButton'),
              onPressed: onCheckIn,
              child: const Text('Check-in'),
            ),
        ],
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
