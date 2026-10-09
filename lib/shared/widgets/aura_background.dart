import 'package:flutter/material.dart';

import '../../core/theme/stev_tokens.dart';

class AuraBackground extends StatelessWidget {
  const AuraBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StevColors.canvas,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: _Auras()),
          child,
        ],
      ),
    );
  }
}

class _Auras extends StatelessWidget {
  const _Auras();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: const [
        Positioned(
          top: 170,
          left: -90,
          child: _Aura(size: 280, color: StevColors.auraLeaf),
        ),
        Positioned(
          top: 58,
          right: -130,
          child: _Aura(size: 260, color: StevColors.auraSugar),
        ),
        Positioned(
          top: 510,
          right: -88,
          child: _Aura(size: 240, color: StevColors.auraSun),
        ),
        Positioned(
          bottom: -120,
          left: -80,
          child: _Aura(size: 250, color: StevColors.auraLeaf),
        ),
      ],
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
