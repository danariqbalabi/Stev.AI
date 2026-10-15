import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../drinks/domain/drink.dart';
import '../domain/custom_drink.dart';

class CustomDrinkScreen extends StatefulWidget {
  const CustomDrinkScreen({super.key});

  @override
  State<CustomDrinkScreen> createState() => _CustomDrinkScreenState();
}

class _CustomDrinkScreenState extends State<CustomDrinkScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _spoons = 1;
  int _syrupPumps = 0;

  double get _grams =>
      CustomDrink.sugarGrams(spoons: _spoons, syrupPumps: _syrupPumps);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final drink = CustomDrink.create(
      name: _nameController.text,
      spoons: _spoons,
      syrupPumps: _syrupPumps,
    );
    await DrinkLogScope.read(context).log(DrinkSelection(drink: drink));
    if (mounted) context.go('/');
  }

  void _updateSpoons(int change) {
    setState(() => _spoons = (_spoons + change).clamp(1, 999));
  }

  void _updateSyrupPumps(int change) {
    setState(() => _syrupPumps = (_syrupPumps + change).clamp(0, 999));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('customDrinkScreen'),
      body: AuraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  StevSpace.s5,
                  88,
                  StevSpace.s5,
                  36,
                ),
                children: [
                  _NameField(controller: _nameController),
                  const SizedBox(height: StevSpace.s6),
                  GlassCard(
                    padding: const EdgeInsets.all(StevSpace.s5),
                    child: Column(
                      children: [
                        _StepperRow(
                          label: 'Sendok gula',
                          value: _spoons,
                          minusKey: const ValueKey('spoonsMinus'),
                          plusKey: const ValueKey('spoonsPlus'),
                          onMinus: _spoons == 1
                              ? null
                              : () => _updateSpoons(-1),
                          onPlus: () => _updateSpoons(1),
                        ),
                        const SizedBox(height: StevSpace.s5),
                        _StepperRow(
                          label: 'Pump sirup',
                          value: _syrupPumps,
                          minusKey: const ValueKey('syrupMinus'),
                          plusKey: const ValueKey('syrupPlus'),
                          onMinus: _syrupPumps == 0
                              ? null
                              : () => _updateSyrupPumps(-1),
                          onPlus: () => _updateSyrupPumps(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: StevSpace.s6),
                  _SugarPreview(grams: _grams),
                  const SizedBox(height: StevSpace.s6),
                  StevButton(
                    key: const ValueKey('saveCustomDrinkButton'),
                    label: 'Simpan',
                    variant: StevButtonVariant.ink,
                    onPressed: _save,
                  ),
                ],
              ),
              const _CustomDrinkHeader(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDrinkHeader extends StatelessWidget {
  const _CustomDrinkHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ColoredBox(
        color: StevColors.canvas.withValues(alpha: 0.82),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: StevSpace.s5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: StevIconButton(
                  icon: const StevIcon(StevIconName.back, size: 20),
                  label: 'Kembali',
                  onPressed: () => context.pop(),
                ),
              ),
              Text('Tambah minuman', style: StevType.heading),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nama minuman', style: StevType.caption),
        const SizedBox(height: StevSpace.s2),
        GlassCard(
          radius: StevRadius.button,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: StevSize.buttonHeight,
            child: TextField(
              key: const ValueKey('customDrinkNameField'),
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: StevType.label,
              decoration: const InputDecoration(
                hintText: 'Contoh: Es kopi susu',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: StevSpace.s4,
                  vertical: StevSpace.s4,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.minusKey,
    required this.plusKey,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int value;
  final Key minusKey;
  final Key plusKey;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: StevType.label)),
        _StepperButton(
          key: minusKey,
          label: 'Kurangi $label',
          symbol: '−',
          onPressed: onMinus,
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            key: ValueKey('${label.toLowerCase()}Value'),
            textAlign: TextAlign.center,
            style: StevType.listGrams.copyWith(fontFeatures: StevType.tabular),
          ),
        ),
        _StepperButton(
          key: plusKey,
          label: 'Tambah $label',
          symbol: '+',
          onPressed: onPlus,
        ),
      ],
    );
  }
}

class _StepperButton extends StatefulWidget {
  const _StepperButton({
    super.key,
    required this.label,
    required this.symbol,
    required this.onPressed,
  });

  final String label;
  final String symbol;
  final VoidCallback? onPressed;

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: StevSpace.s1),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : StevMotion.press,
        transform: Matrix4.translationValues(
          0,
          _pressed && !reduceMotion ? StevSpace.s1 : 0,
          0,
        ),
        width: StevSize.tapMin,
        height: StevSize.tapMin,
        decoration: BoxDecoration(
          color: disabled
              ? StevColors.card.withValues(alpha: 0.5)
              : StevColors.card,
          borderRadius: BorderRadius.circular(StevRadius.small),
          boxShadow: _pressed || disabled ? const [] : StevShadows.pressCard,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(StevRadius.small),
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: disabled
                ? null
                : (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(StevRadius.small),
            child: Semantics(
              button: true,
              enabled: !disabled,
              label: widget.label,
              child: ExcludeSemantics(
                child: Center(
                  child: Text(
                    widget.symbol,
                    style: StevType.heading.copyWith(
                      color: disabled ? StevColors.ink3 : StevColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SugarPreview extends StatelessWidget {
  const _SugarPreview({required this.grams});

  final double grams;

  String get _value {
    final number = grams % 1 == 0
        ? grams.toStringAsFixed(0)
        : grams.toStringAsFixed(1);
    return '≈$number';
  }

  @override
  Widget build(BuildContext context) {
    final spoons = drinkSpoons(grams);

    return Semantics(
      label: 'Estimasi ${formatSugarGrams(grams, true)} gula',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 230,
          child: GlassCard(
            padding: const EdgeInsets.all(StevSpace.s6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _value,
                        key: const ValueKey('customSugarPreview'),
                        style: StevType.number.copyWith(
                          fontFeatures: StevType.tabular,
                        ),
                      ),
                      Text(
                        'g',
                        style: StevType.unitHome.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: StevSpace.s4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 0; index < spoons.length; index++) ...[
                          if (index > 0) const SizedBox(width: StevSpace.s4),
                          Spoon(
                            grams: spoons[index],
                            width: StevSize.spoonResult,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
