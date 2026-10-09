import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/stev_tokens.dart';
import 'stev_brand.dart';

enum StevTab { home, weekly }

class StevTabBar extends StatelessWidget {
  const StevTabBar({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onScan,
    required this.onWeekly,
  });

  final StevTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onScan;
  final VoidCallback onWeekly;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: StevSize.tabBarHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: StevGlass.blurSigma,
                    sigmaY: StevGlass.blurSigma,
                  ),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: StevColors.glass,
                      border: Border(
                        top: BorderSide(color: StevColors.glassEdge),
                      ),
                      boxShadow: StevShadows.elevGlass,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabItem(
                            icon: StevIconName.home,
                            label: 'Beranda',
                            selected: activeTab == StevTab.home,
                            onPressed: onHome,
                          ),
                        ),
                        const SizedBox(width: 92),
                        Expanded(
                          child: _TabItem(
                            icon: StevIconName.weekly,
                            label: 'Mingguan',
                            selected: activeTab == StevTab.weekly,
                            onPressed: onWeekly,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(top: -24, child: _ScanButton(onPressed: onScan)),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final StevIconName icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? StevColors.ink : StevColors.ink2;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: StevSpace.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StevIcon(icon, color: color),
                const SizedBox(height: StevSpace.s1),
                Text(label, style: StevType.micro.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanButton extends StatefulWidget {
  const _ScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  bool _pressed = false;
  bool _scheduled = false;
  Timer? _pulseDelay;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: StevMotion.scanPulse,
    );
    _pulse =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1, end: 1.06), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulseDelay?.cancel();
      _pulseController.value = 0;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    _pulseDelay = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _pulseController.forward();
    });
  }

  @override
  void dispose() {
    _pulseDelay?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return ScaleTransition(
      scale: _pulse,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : StevMotion.press,
        transform: Matrix4.translationValues(
          0,
          _pressed && !reduceMotion ? 5 : 0,
          0,
        ),
        width: StevSize.scanButton,
        height: StevSize.scanButton,
        decoration: BoxDecoration(
          color: StevColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: StevColors.onInk, width: 3),
          boxShadow: _pressed ? const [] : StevShadows.elevFloat,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('scanButton'),
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            customBorder: const CircleBorder(),
            child: const Center(
              child: StevIcon(
                StevIconName.scan,
                size: 28,
                label: 'Scan minuman',
                color: StevColors.onInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
