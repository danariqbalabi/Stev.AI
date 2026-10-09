import 'package:flutter/material.dart';

import '../../core/theme/stev_tokens.dart';

enum StevButtonVariant { leaf, ink, card, ghost }

class StevButton extends StatefulWidget {
  const StevButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = StevButtonVariant.ink,
    this.icon,
    this.expand = true,
    this.height = StevSize.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final StevButtonVariant variant;
  final Widget? icon;
  final bool expand;
  final double height;

  @override
  State<StevButton> createState() => _StevButtonState();
}

class _StevButtonState extends State<StevButton> {
  bool _pressed = false;

  double get _depth => switch (widget.variant) {
    StevButtonVariant.card => 4,
    StevButtonVariant.ghost => 0,
    _ => 5,
  };

  Color get _background => switch (widget.variant) {
    StevButtonVariant.leaf => StevColors.leaf,
    StevButtonVariant.ink => StevColors.ink,
    StevButtonVariant.card => StevColors.card,
    StevButtonVariant.ghost => Colors.transparent,
  };

  Color get _foreground => switch (widget.variant) {
    StevButtonVariant.ink => StevColors.onInk,
    StevButtonVariant.ghost => StevColors.ink2,
    _ => StevColors.ink,
  };

  List<BoxShadow> get _shadow => switch (widget.variant) {
    StevButtonVariant.leaf => StevShadows.pressLeaf,
    StevButtonVariant.ink => StevShadows.pressInk,
    StevButtonVariant.card => StevShadows.pressCard,
    StevButtonVariant.ghost => const [],
  };

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final button = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : StevMotion.press,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        0,
        _pressed && !reduceMotion ? _depth : 0,
        0,
      ),
      decoration: BoxDecoration(
        color: disabled ? StevColors.ink3.withValues(alpha: 0.5) : _background,
        borderRadius: BorderRadius.circular(StevRadius.button),
        border: widget.variant == StevButtonVariant.card
            ? Border.all(color: StevColors.glassEdge)
            : null,
        boxShadow: _pressed || disabled ? const [] : _shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(StevRadius.button),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: disabled
              ? null
              : (value) => setState(() => _pressed = value),
          borderRadius: BorderRadius.circular(StevRadius.button),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.height,
              minWidth: StevSize.tapMin,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: StevSpace.s5),
              child: Row(
                mainAxisSize: widget.expand
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon case final icon?) ...[
                    IconTheme(
                      data: IconThemeData(color: _foreground, size: 22),
                      child: icon,
                    ),
                    const SizedBox(width: StevSpace.s2),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: StevType.button.copyWith(color: _foreground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: _depth),
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

class StevIconButton extends StatefulWidget {
  const StevIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<StevIconButton> createState() => _StevIconButtonState();
}

class _StevIconButtonState extends State<StevIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : StevMotion.press,
        transform: Matrix4.translationValues(
          0,
          _pressed && !reduceMotion ? 4 : 0,
          0,
        ),
        width: StevSize.roundButton,
        height: StevSize.roundButton,
        decoration: BoxDecoration(
          color: StevColors.glassCard,
          shape: BoxShape.circle,
          border: Border.all(color: StevColors.glassEdge),
          boxShadow: _pressed
              ? const []
              : [...StevShadows.pressCard, ...StevShadows.elevCard],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: Semantics(
              button: true,
              label: widget.label,
              child: Center(child: ExcludeSemantics(child: widget.icon)),
            ),
          ),
        ),
      ),
    );
  }
}
