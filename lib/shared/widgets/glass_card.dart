import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/stev_tokens.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(StevSpace.s7),
    this.radius = StevRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: StevShadows.elevCard,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: StevGlass.blurSigma,
            sigmaY: StevGlass.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: StevColors.glassCard,
              borderRadius: borderRadius,
              border: Border.all(color: StevColors.glassEdge),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
