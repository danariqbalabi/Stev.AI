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
        _Aura(
          alignment: Alignment(-1.35, -1.08),
          size: 360,
          color: StevColors.auraLeaf,
        ),
        _Aura(
          alignment: Alignment(1.42, -0.35),
          size: 300,
          color: StevColors.auraSugar,
        ),
        _Aura(
          alignment: Alignment(-0.85, 1.3),
          size: 330,
          color: StevColors.auraSun,
        ),
      ],
    );
  }
}

class _Aura extends StatelessWidget {
  const _Aura({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
