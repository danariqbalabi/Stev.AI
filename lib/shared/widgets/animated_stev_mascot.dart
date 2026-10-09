import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/stev_tokens.dart';
import 'stev_brand.dart';

class AnimatedStevMascot extends StatefulWidget {
  const AnimatedStevMascot({
    super.key,
    this.mood = StevMood.happy,
    this.size = StevSize.stevHome,
    this.wave = false,
  });

  final StevMood mood;
  final double size;
  final bool wave;

  @override
  State<AnimatedStevMascot> createState() => _AnimatedStevMascotState();
}

class _AnimatedStevMascotState extends State<AnimatedStevMascot>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: StevMotion.breathe ~/ 2,
    );
    _waveController = AnimationController(
      vsync: this,
      duration: StevMotion.wave ~/ 2,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimations();
  }

  void _syncAnimations() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _breatheController.stop();
      _waveController.stop();
      _breatheController.value = 0;
      _waveController.value = 0;
      return;
    }

    if (!_breatheController.isAnimating) {
      _breatheController.repeat(reverse: true);
    }
    if (widget.wave && !_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
    } else if (!widget.wave) {
      _waveController.stop();
      _waveController.value = 0;
    }
  }

  @override
  void didUpdateWidget(AnimatedStevMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wave != widget.wave) _syncAnimations();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breatheController, _waveController]),
      builder: (context, child) {
        final breatheY =
            -2 * Curves.easeInOut.transform(_breatheController.value);
        final waveValue = Curves.easeInOut.transform(_waveController.value);
        final angle = widget.wave ? (-2 + 5 * waveValue) * math.pi / 180 : 0.0;
        final waveY = widget.wave ? -4 * waveValue : 0.0;

        return Transform.translate(
          offset: Offset(0, breatheY + waveY),
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: StevMascot(mood: widget.mood, size: widget.size),
    );
  }
}
