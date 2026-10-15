import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/drink_photo.dart';
import '../../../shared/widgets/stev_button.dart';
import '../../drinks/domain/drink.dart';
import '../../drinks/domain/drink_swap.dart';

Future<SwapOption?> showSwapOptionsSheet(
  BuildContext context, {
  required List<SwapOption> options,
}) {
  return showModalBottomSheet<SwapOption>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    sheetAnimationStyle: AnimationStyle.noAnimation,
    backgroundColor: Colors.transparent,
    barrierColor: StevColors.ink.withValues(alpha: 0.3),
    builder: (context) => _SwapOptionsSheet(options: options),
  );
}

class _SwapOptionsSheet extends StatefulWidget {
  const _SwapOptionsSheet({required this.options});

  final List<SwapOption> options;

  @override
  State<_SwapOptionsSheet> createState() => _SwapOptionsSheetState();
}

class _SwapOptionsSheetState extends State<_SwapOptionsSheet> {
  SwapOption? _selected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(StevRadius.sheet),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: StevGlass.blurSigma,
          sigmaY: StevGlass.blurSigma,
        ),
        child: Container(
          key: const ValueKey('swapOptionsSheet'),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          padding: EdgeInsets.fromLTRB(
            StevSpace.s5,
            StevSpace.s5,
            StevSpace.s5,
            StevSpace.s4 + bottomInset,
          ),
          decoration: const BoxDecoration(
            color: StevColors.glass,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(StevRadius.sheet),
            ),
            boxShadow: StevShadows.elevGlass,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: StevColors.ink3,
                    borderRadius: BorderRadius.circular(StevRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              Text('Tukar jadi apa?', style: StevType.headingResult),
              const SizedBox(height: StevSpace.s1),
              Text(
                'Pilih versi yang lebih rendah gula.',
                style: StevType.caption.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s4),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    return _SwapOptionCard(
                      key: ValueKey('swapOption-$index'),
                      option: option,
                      selected: identical(_selected, option),
                      onTap: () => setState(() => _selected = option),
                    );
                  },
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: StevButton(
                      key: const ValueKey('cancelSwapButton'),
                      label: 'Batal',
                      variant: StevButtonVariant.card,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: StevSpace.s3),
                  Expanded(
                    child: StevButton(
                      key: const ValueKey('confirmSwapButton'),
                      label: 'Swap',
                      variant: StevButtonVariant.leaf,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      onPressed: _selected == null
                          ? null
                          : () => Navigator.of(context).pop(_selected),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapOptionCard extends StatelessWidget {
  const _SwapOptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SwapOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selection = option.selection;

    return Material(
      color: StevColors.card,
      borderRadius: BorderRadius.circular(StevRadius.row),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StevRadius.row),
        child: AnimatedContainer(
          duration: StevMotion.press,
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StevRadius.row),
            border: Border.all(
              color: selected ? StevColors.leaf : StevColors.glassEdge,
              width: selected ? 2 : 1,
            ),
            boxShadow: StevShadows.elevCard,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox.square(
                  dimension: 60,
                  child: DrinkPhoto(drink: selection.drink),
                ),
              ),
              const SizedBox(width: StevSpace.s3),
              Expanded(
                child: Text(
                  _optionName(selection),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StevType.caption.copyWith(
                    color: StevColors.ink,
                    fontWeight: StevType.w700,
                  ),
                ),
              ),
              const SizedBox(width: StevSpace.s2),
              Text(selection.displayGrams, style: StevType.caption),
              const SizedBox(width: StevSpace.s2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: StevColors.leaf,
                  borderRadius: BorderRadius.circular(StevRadius.pill),
                ),
                child: Text(
                  '-${_grams(option.savedGrams)} g',
                  style: StevType.micro.copyWith(
                    color: StevColors.ink,
                    fontWeight: StevType.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _optionName(DrinkSelection selection) {
  final level = selection.sugarLevel;
  if (level == null || level == SugarLevel.normal) return selection.drink.name;
  return '${selection.drink.name}, ${level.label.toLowerCase()}';
}

String _grams(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
