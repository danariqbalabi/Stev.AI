import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/domain/drink.dart';
import '../../drinks/domain/drink_swap.dart';

Future<void> showSwapReward(
  BuildContext context, {
  required DrinkSelection current,
  required SwapOption option,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) {
      return SwapRewardOverlay(current: current, option: option);
    },
  );
}

class SwapRewardOverlay extends StatefulWidget {
  const SwapRewardOverlay({
    super.key,
    required this.current,
    required this.option,
  });

  final DrinkSelection current;
  final SwapOption option;

  @override
  State<SwapRewardOverlay> createState() => _SwapRewardOverlayState();
}

class _SwapRewardOverlayState extends State<SwapRewardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.duration = StevMotion.reduced;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _chooseSwap() {
    if (_saving) return;
    _saving = true;
    final router = GoRouter.of(context);
    DrinkLogScope.read(context).log(widget.option.selection);
    Navigator.of(context, rootNavigator: true).pop();
    router.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showConfetti =
        !reduceMotion && widget.option.savedGrams >= StevSugar.gramsPerSpoon;
    final savedLabel = _numberLabel(widget.option.savedGrams);

    return PopScope(
      canPop: false,
      child: Material(
        key: const ValueKey('swapRewardOverlay'),
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: StevGlass.rewardBlur,
                sigmaY: StevGlass.rewardBlur,
              ),
              child: const ColoredBox(color: StevColors.night),
            ),
            if (showConfetti)
              _Confetti(animation: _controller)
            else
              const SizedBox.shrink(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 700;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      StevSpace.s5,
                      compact ? StevSpace.s6 : 88,
                      StevSpace.s5,
                      compact ? StevSpace.s5 : StevSpace.s10,
                    ),
                    child: Column(
                      children: [
                        _RewardEntrance(
                          animation: _controller,
                          beginMs: 0,
                          endMs: reduceMotion ? 150 : 550,
                          offsetY: reduceMotion ? 0 : 70,
                          beginScale: reduceMotion ? 1 : 0.65,
                          curve: reduceMotion
                              ? Curves.easeOut
                              : StevMotion.jump,
                          child: const StevMascot(
                            mood: StevMood.cheerOnDark,
                            size: StevSize.stevReward,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Semantics(
                          label:
                              '${_numberLabel(widget.option.selection.grams)} gram',
                          child: ExcludeSemantics(
                            child: _Odometer(
                              animation: _controller,
                              from: widget.current.grams.round(),
                              to: widget.option.selection.grams.round(),
                              reduceMotion: reduceMotion,
                            ),
                          ),
                        ),
                        const SizedBox(height: 19),
                        _RewardEntrance(
                          animation: _controller,
                          beginMs: reduceMotion ? 0 : 650,
                          endMs: reduceMotion ? 150 : 1100,
                          offsetY: reduceMotion ? 0 : 18,
                          child: Text(
                            'Mantap, hemat $savedLabel g!',
                            key: const ValueKey('swapSavingMessage'),
                            textAlign: TextAlign.center,
                            style: StevType.title.copyWith(
                              color: StevColors.onInk,
                            ),
                          ),
                        ),
                        const SizedBox(height: StevSpace.s7),
                        _RewardEntrance(
                          animation: _controller,
                          beginMs: reduceMotion ? 0 : 800,
                          endMs: reduceMotion ? 150 : 1250,
                          offsetY: reduceMotion ? 0 : 18,
                          child: _RewardDrinkCard(
                            selection: widget.option.selection,
                          ),
                        ),
                        const Spacer(),
                        _RewardEntrance(
                          animation: _controller,
                          beginMs: reduceMotion ? 0 : 900,
                          endMs: 1350,
                          offsetY: reduceMotion ? 0 : 18,
                          child: StevButton(
                            key: const ValueKey('chooseSwapButton'),
                            label: 'Aku pilih ini',
                            variant: StevButtonVariant.leaf,
                            onPressed: _saving ? null : _chooseSwap,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardEntrance extends StatelessWidget {
  const _RewardEntrance({
    required this.animation,
    required this.beginMs,
    required this.endMs,
    required this.offsetY,
    required this.child,
    this.beginScale = 1,
    this.curve = Curves.easeOut,
  });

  final Animation<double> animation;
  final int beginMs;
  final int endMs;
  final double offsetY;
  final double beginScale;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (beginMs / 1350).clamp(0.0, 1.0);
    final end = (endMs / 1350).clamp(begin, 1.0);
    final progress = CurvedAnimation(
      parent: animation,
      curve: Interval(begin, end, curve: curve),
    );

    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) {
        final rawValue = progress.value;
        final value = rawValue.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: Transform.scale(
              scale: beginScale + (1 - beginScale) * rawValue,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _Odometer extends StatelessWidget {
  const _Odometer({
    required this.animation,
    required this.from,
    required this.to,
    required this.reduceMotion,
  });

  final Animation<double> animation;
  final int from;
  final int to;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final fromDigits = from.clamp(0, 99).toString().padLeft(2, '0');
    final toDigits = to.clamp(0, 99).toString().padLeft(2, '0');
    final progress = CurvedAnimation(
      parent: animation,
      curve: reduceMotion
          ? Curves.easeOut
          : const Interval(150 / 1350, 1, curve: StevMotion.outExpo),
    );

    return SizedBox(
      height: 88,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < 2; index++)
            _RollingDigit(
              from: int.parse(fromDigits[index]),
              to: int.parse(toDigits[index]),
              progress: progress,
              reduceMotion: reduceMotion,
            ),
          const SizedBox(width: 5),
          Text(
            'g',
            style: StevType.unitResult.copyWith(color: StevColors.onNight2),
          ),
        ],
      ),
    );
  }
}

class _RollingDigit extends StatelessWidget {
  const _RollingDigit({
    required this.from,
    required this.to,
    required this.progress,
    required this.reduceMotion,
  });

  final int from;
  final int to;
  final Animation<double> progress;
  final bool reduceMotion;

  List<int> get _digits {
    final result = <int>[from];
    var current = from;
    while (current != to) {
      current = (current + 9) % 10;
      result.add(current);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final digits = _digits;
    if (reduceMotion) {
      return SizedBox(
        width: 58,
        height: 88,
        child: Center(
          child: Text(
            '$to',
            style: StevType.rewardNumber.copyWith(color: StevColors.onInk),
          ),
        ),
      );
    }

    return ClipRect(
      child: SizedBox(
        width: 58,
        height: 88,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -(digits.length - 1) * 88 * progress.value),
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final digit in digits)
                  SizedBox(
                    width: 58,
                    height: 88,
                    child: Center(
                      child: Text(
                        '$digit',
                        style: StevType.rewardNumber.copyWith(
                          color: StevColors.onInk,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardDrinkCard extends StatelessWidget {
  const _RewardDrinkCard({required this.selection});

  final DrinkSelection selection;

  String get _displayName {
    if (selection.sugarLevel == SugarLevel.less) {
      return '${selection.drink.name}, less sugar';
    }
    if (selection.sugarLevel == SugarLevel.noSugar) {
      return '${selection.drink.name}, no sugar';
    }
    return selection.drink.name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('swapDrinkCard'),
      height: StevSize.rewardCard,
      decoration: BoxDecoration(
        color: StevColors.rewardCard,
        borderRadius: BorderRadius.circular(StevRadius.row),
        border: Border.all(color: StevColors.rewardCardEdge),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox.square(
            dimension: StevSize.rewardCard,
            child: Image.asset(
              selection.drink.photoAsset,
              fit: selection.drink.photoFit,
              alignment: selection.drink.photoAlignment,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: StevSpace.s4),
              child: Text(
                _displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: StevType.label.copyWith(
                  color: StevColors.onInk,
                  fontWeight: StevType.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: StevSpace.s2,
              right: StevSpace.s5,
            ),
            child: Text(
              selection.displayGrams,
              style: StevType.label.copyWith(
                color: StevColors.onInk,
                fontWeight: StevType.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({required this.animation});

  final Animation<double> animation;

  static const _pieces = [
    (0.08, 13, -12.0, StevColors.sun),
    (0.26, 7, 14.0, StevColors.leaf),
    (0.42, 4, -8.0, StevColors.sugar),
    (0.56, 10, 8.0, StevColors.sun),
    (0.72, 5, -16.0, StevColors.leaf),
    (0.87, 13, 13.0, StevColors.sugar),
    (0.16, 22, 10.0, StevColors.leaf),
    (0.34, 17, -13.0, StevColors.sun),
    (0.64, 20, 14.0, StevColors.sugar),
    (0.92, 24, -8.0, StevColors.sun),
    (0.05, 30, 15.0, StevColors.sugar),
    (0.82, 32, -12.0, StevColors.leaf),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (var index = 0; index < _pieces.length; index++)
                _ConfettiPiece(
                  key: ValueKey('confetti-$index'),
                  animation: animation,
                  left: constraints.maxWidth * _pieces[index].$1,
                  delayMs: _pieces[index].$2 * 18,
                  startDegrees: _pieces[index].$3,
                  color: _pieces[index].$4,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfettiPiece extends StatelessWidget {
  const _ConfettiPiece({
    super.key,
    required this.animation,
    required this.left,
    required this.delayMs,
    required this.startDegrees,
    required this.color,
  });

  final Animation<double> animation;
  final double left;
  final int delayMs;
  final double startDegrees;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final start = (delayMs / 1350).clamp(0.0, 1.0);
    final end = ((delayMs + 900) / 1350).clamp(start, 1.0);
    final progress = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeIn),
    );

    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final value = progress.value;
        final degrees = startDegrees + (440 - startDegrees) * value;
        return Positioned(
          left: left,
          top: -24 + 380 * value,
          child: Transform.rotate(angle: degrees * math.pi / 180, child: child),
        );
      },
      child: Container(
        width: 10,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

String _numberLabel(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
