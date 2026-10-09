import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/stev_tokens.dart';

enum StevMood { happy, cheer, worried, cheerOnDark }

class StevMascot extends StatelessWidget {
  const StevMascot({
    super.key,
    this.mood = StevMood.happy,
    this.size = StevSize.stevHome,
  });

  final StevMood mood;
  final double size;

  String get _asset => switch (mood) {
    StevMood.happy => 'assets/brand/stev_happy.svg',
    StevMood.cheer => 'assets/brand/stev_cheer.svg',
    StevMood.worried => 'assets/brand/stev_worried.svg',
    StevMood.cheerOnDark => 'assets/brand/stev_cheer_on_dark.svg',
  };

  String get _label => switch (mood) {
    StevMood.happy => 'Stev senang',
    StevMood.cheer || StevMood.cheerOnDark => 'Stev bersorak',
    StevMood.worried => 'Stev khawatir',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: _label,
      child: SvgPicture.asset(
        _asset,
        width: size,
        height: size,
        excludeFromSemantics: true,
      ),
    );
  }
}

class StevLogo extends StatelessWidget {
  const StevLogo({super.key, this.markSize = 28, this.onDark = false});

  final double markSize;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? StevColors.onInk : StevColors.ink;

    return Semantics(
      image: true,
      label: 'Stev.AI',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/brand/logo_mark.svg',
              width: markSize,
              height: markSize,
            ),
            const SizedBox(width: StevSpace.s2),
            Text('Stev.AI', style: StevType.logo.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

enum StevIconName { home, weekly, scan, search, swap, back, chevronRight }

class StevIcon extends StatelessWidget {
  const StevIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.label,
    this.color,
  });

  final StevIconName name;
  final double size;
  final String? label;
  final Color? color;

  String get _assetName => switch (name) {
    StevIconName.home => 'home',
    StevIconName.weekly => 'weekly',
    StevIconName.scan => 'scan',
    StevIconName.search => 'search',
    StevIconName.swap => 'swap',
    StevIconName.back => 'back',
    StevIconName.chevronRight => 'chevron_right',
  };

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      'assets/icons/$_assetName.svg',
      width: size,
      height: size,
      excludeFromSemantics: true,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );

    if (label == null) return icon;
    return Semantics(image: true, label: label, child: icon);
  }
}
