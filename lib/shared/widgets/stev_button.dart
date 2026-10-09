import 'package:flutter/material.dart';

import '../../core/theme/stev_tokens.dart';

enum StevButtonVariant { leaf, ink, card }

class StevButton extends StatefulWidget {
  const StevButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = StevButtonVariant.ink,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final StevButtonVariant variant;
  final Widget? icon;
  final bool expand;

  @override
  State<StevButton> createState() => _StevButtonState();
}

class _StevButtonState extends State<StevButton> {
  bool _pressed = false;

  double get _depth => widget.variant == StevButtonVariant.card ? 4 : 5;

  Color get _background => switch (widget.variant) {
    StevButtonVariant.leaf => StevColors.leaf,
    StevButtonVariant.ink => StevColors.ink,
    StevButtonVariant.card => StevColors.card,
  };

  Color get _foreground => widget.variant == StevButtonVariant.ink
      ? StevColors.onInk
      : StevColors.ink;

  List<BoxShadow> get _shadow => switch (widget.variant) {
    StevButtonVariant.leaf => StevShadows.pressLeaf,
    StevButtonVariant.ink => StevShadows.pressInk,
    StevButtonVariant.card => StevShadows.pressCard,
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
        color: disabled ? StevColors.ink3 : _background,
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
            constraints: const BoxConstraints(
              minHeight: StevSize.buttonHeight,
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
