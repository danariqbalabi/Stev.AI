import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../../shared/widgets/drink_photo.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/domain/drink.dart';
import '../../drinks/domain/drink_swap.dart';
import '../../swap/presentation/swap_reward_overlay.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.drink});

  final Drink drink;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  SugarLevel? _sugarLevel;

  @override
  void initState() {
    super.initState();
    _sugarLevel = widget.drink.levels == null ? null : SugarLevel.normal;
  }

  DrinkSelection get _selection =>
      DrinkSelection(drink: widget.drink, sugarLevel: _sugarLevel);

  void _chooseDrink() {
    DrinkLogScope.read(context).log(_selection);
    context.go('/');
  }

  void _openSwap() {
    HapticFeedback.lightImpact();
    final options = DrinkSwap.optionsFor(_selection);
    if (options.isEmpty) return;
    showSwapReward(context, current: _selection, option: options.first);
  }

  @override
  Widget build(BuildContext context) {
    final drinkLog = DrinkLogScope.watch(context);
    final selection = _selection;
    final overGrams =
        (drinkLog.totalGrams + selection.grams - StevSugar.dailyLimit)
            .clamp(0, double.infinity)
            .toDouble();
    final hasSwap = DrinkSwap.optionsFor(selection).isNotEmpty;
    final hasLevels = widget.drink.levels != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const ValueKey('resultScreen'),
        backgroundColor: StevColors.ink,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final targetHeight = hasLevels ? 590.0 : 504.0;
            final minTop = hasLevels ? 220.0 : 280.0;
            final maxTop = hasLevels ? 300.0 : 360.0;
            final sheetTop = (constraints.maxHeight - targetHeight).clamp(
              minTop,
              maxTop,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                _DrinkPhoto(drink: widget.drink),
                const _PhotoShade(),
                const Positioned(
                  top: 320,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AuraBackground(child: SizedBox.expand()),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: sheetTop,
                  bottom: 0,
                  child: _ResultSheet(
                    selection: selection,
                    overGrams: overGrams,
                    hasSwap: hasSwap,
                    onLevelChanged: (level) {
                      setState(() => _sugarLevel = level);
                    },
                    onChoose: _chooseDrink,
                    onSwap: _openSwap,
                  ),
                ),
                const _ResultHeader(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DrinkPhoto extends StatelessWidget {
  const _DrinkPhoto({required this.drink});

  final Drink drink;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: 430,
        child: ColoredBox(
          color: StevColors.canvas,
          child: DrinkPhoto(drink: drink),
        ),
      ),
    );
  }
}

class _PhotoShade extends StatelessWidget {
  const _PhotoShade();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8A111113), Color(0x00111113)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          StevSpace.s5,
          StevSpace.s2,
          StevSpace.s5,
          0,
        ),
        child: SizedBox(
          height: StevSize.roundButton,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _PhotoBackButton(onPressed: () => context.pop()),
              ),
              Text(
                'Hasil scan',
                style: StevType.label.copyWith(
                  color: StevColors.onInk,
                  fontWeight: StevType.w700,
                  shadows: const [
                    Shadow(color: Color(0x80111113), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoBackButton extends StatelessWidget {
  const _PhotoBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: StevGlass.photoButtonBlur,
          sigmaY: StevGlass.photoButtonBlur,
        ),
        child: Material(
          color: StevColors.photoButton,
          child: InkWell(
            key: const ValueKey('resultBackButton'),
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox.square(
              dimension: StevSize.roundButton,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 19,
                color: StevColors.onInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({
    required this.selection,
    required this.overGrams,
    required this.hasSwap,
    required this.onLevelChanged,
    required this.onChoose,
    required this.onSwap,
  });

  final DrinkSelection selection;
  final double overGrams;
  final bool hasSwap;
  final ValueChanged<SugarLevel> onLevelChanged;
  final VoidCallback onChoose;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(StevRadius.sheet),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: StevGlass.blurSigma,
          sigmaY: StevGlass.blurSigma,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: StevColors.glass,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(StevRadius.sheet),
            ),
            boxShadow: StevShadows.elevGlass,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              26,
              StevSpace.s5,
              34,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selection.drink.name, style: StevType.headingResult),
                const SizedBox(height: StevSpace.s1),
                Text(
                  selection.drink.validationStatus == DrinkValidationStatus.demo
                      ? 'Data demo — belum divalidasi'
                      : _sourceLabel(selection.drink),
                  key: const ValueKey('drinkDataStatus'),
                  style: StevType.caption.copyWith(color: StevColors.ink2),
                ),
                if (selection.drink.levels != null) ...[
                  const SizedBox(height: StevSpace.s3),
                  _LevelPicker(
                    selected: selection.sugarLevel ?? SugarLevel.normal,
                    onChanged: onLevelChanged,
                  ),
                ],
                const SizedBox(height: 14),
                _SugarCard(selection: selection, overGrams: overGrams),
                const SizedBox(height: 53),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: hasSwap ? 5 : 1,
                      child: StevButton(
                        key: const ValueKey('chooseDrinkButton'),
                        label: 'Aku pilih ini',
                        variant: StevButtonVariant.card,
                        onPressed: onChoose,
                      ),
                    ),
                    if (hasSwap) ...[
                      const SizedBox(width: StevSpace.s3),
                      Expanded(
                        flex: 4,
                        child: StevButton(
                          key: const ValueKey('swapButton'),
                          label: 'Swap',
                          variant: StevButtonVariant.leaf,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          onPressed: onSwap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sourceLabel(Drink drink) => switch (drink.dataType) {
  DrinkDataType.label => 'Diverifikasi dari label produk',
  DrinkDataType.official => 'Diverifikasi dari sumber resmi',
  DrinkDataType.estimated => 'Estimasi terverifikasi',
  DrinkDataType.community => 'Data komunitas terverifikasi',
  DrinkDataType.custom => 'Estimasi racikan pengguna',
};

class _LevelPicker extends StatelessWidget {
  const _LevelPicker({required this.selected, required this.onChanged});

  final SugarLevel selected;
  final ValueChanged<SugarLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      SugarLevel.normal: 'Normal',
      SugarLevel.less: 'Less',
      SugarLevel.noSugar: 'No',
    };

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: StevColors.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(StevRadius.button),
        border: Border.all(color: StevColors.glassEdge),
      ),
      child: Row(
        children: [
          for (final level in SugarLevel.values)
            Expanded(
              child: _LevelChoice(
                level: level,
                label: labels[level]!,
                selected: selected == level,
                onTap: () => onChanged(level),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelChoice extends StatelessWidget {
  const _LevelChoice({
    required this.level,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SugarLevel level;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? StevColors.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: ValueKey('sugarLevel-${level.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label,
            style: StevType.caption.copyWith(
              color: selected ? StevColors.onInk : StevColors.ink2,
              fontWeight: StevType.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SugarCard extends StatelessWidget {
  const _SugarCard({required this.selection, required this.overGrams});

  final DrinkSelection selection;
  final double overGrams;

  @override
  Widget build(BuildContext context) {
    final isOver = overGrams > 0;
    final overLabel = overGrams % 1 == 0
        ? overGrams.toStringAsFixed(0)
        : overGrams.toStringAsFixed(1);
    final gramsLabel = selection.grams % 1 == 0
        ? selection.grams.toStringAsFixed(0)
        : selection.grams.toStringAsFixed(1);
    final displayLabel = '${selection.drink.estimated ? '≈' : ''}$gramsLabel g';
    final spoons = drinkSpoons(selection.grams);

    return Semantics(
      label:
          '$displayLabel gula. ${isOver ? 'Lewat $overLabel gram dari batas harian.' : 'Masih aman.'}',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 290,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: double.infinity,
                height: 251,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  color: StevColors.card,
                  borderRadius: BorderRadius.circular(StevRadius.card),
                  boxShadow: StevShadows.elevCard,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 100,
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? StevMotion.reduced
                            : StevMotion.spoonAppear,
                        switchInCurve: StevMotion.outBack,
                        child: Row(
                          key: ValueKey('spoons-${selection.grams}'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (
                              var index = 0;
                              index < spoons.length;
                              index++
                            ) ...[
                              Spoon(
                                grams: spoons[index],
                                width: StevSize.spoonResult,
                              ),
                              if (index < spoons.length - 1)
                                const SizedBox(width: StevSpace.s4),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? StevMotion.reduced
                          : StevMotion.countUp,
                      child: Text.rich(
                        key: ValueKey('grams-${selection.grams}'),
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${selection.drink.estimated ? '≈' : ''}$gramsLabel',
                              style: StevType.heroCard,
                            ),
                            TextSpan(
                              text: ' g',
                              style: StevType.unitResult.copyWith(
                                color: StevColors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (isOver)
                      Text.rich(
                        TextSpan(
                          style: StevType.body,
                          children: [
                            const TextSpan(text: 'Waduh, lewat '),
                            TextSpan(
                              text: '$overLabel g',
                              style: StevType.body.copyWith(
                                color: StevColors.over,
                              ),
                            ),
                            const TextSpan(text: '!'),
                          ],
                        ),
                      )
                    else
                      Text('Masih aman, nih!', style: StevType.body),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: AnimatedStevMascot(
                  mood: isOver ? StevMood.worried : StevMood.happy,
                  size: StevSize.stevResult,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
