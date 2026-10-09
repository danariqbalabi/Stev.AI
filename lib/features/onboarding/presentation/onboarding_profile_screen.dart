import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../data/onboarding_preferences.dart';

class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  static const _times = ['Pagi', 'Siang', 'Sore', 'Malam'];

  final _nameController = TextEditingController();
  String? _selectedTime;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool skipDetails}) async {
    if (_saving) return;
    setState(() => _saving = true);

    await OnboardingPreferences.complete(
      name: skipDetails ? null : _nameController.text,
      drinkTime: skipDetails ? null : _selectedTime,
    );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuraBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  StevSpace.s5,
                  StevSpace.s4,
                  StevSpace.s5,
                  33,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - StevSpace.s4 - 33,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StevIconButton(
                          key: const ValueKey('onboardingBackButton'),
                          icon: const StevIcon(StevIconName.back),
                          label: 'Kembali',
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(height: 38),
                        Text('Kenalan dulu, yuk.', style: StevType.title),
                        const SizedBox(height: StevSpace.s10),
                        Text(
                          'Nama kamu',
                          style: StevType.caption.copyWith(
                            color: StevColors.ink,
                          ),
                        ),
                        const SizedBox(height: StevSpace.s2),
                        SizedBox(
                          height: 58,
                          child: TextField(
                            key: const ValueKey('nameField'),
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            style: StevType.label,
                            decoration: const InputDecoration(
                              hintText: 'Tulis nama',
                            ),
                          ),
                        ),
                        const SizedBox(height: StevSpace.s10),
                        Text(
                          'Biasanya beli minum jam berapa?',
                          style: StevType.label.copyWith(
                            fontWeight: StevType.w700,
                          ),
                        ),
                        const SizedBox(height: StevSpace.s4),
                        Row(
                          children: [
                            for (
                              var index = 0;
                              index < _times.length;
                              index++
                            ) ...[
                              if (index > 0)
                                const SizedBox(width: StevSpace.s2),
                              Expanded(
                                child: _TimeChip(
                                  label: _times[index],
                                  selected: _selectedTime == _times[index],
                                  onPressed: () => setState(
                                    () => _selectedTime = _times[index],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(height: StevSpace.s6),
                        StevButton(
                          key: const ValueKey('profileStartButton'),
                          label: _saving ? 'Menyimpan...' : 'Mulai',
                          onPressed: _saving
                              ? null
                              : () => _finish(skipDetails: false),
                        ),
                        const SizedBox(height: StevSpace.s3),
                        StevButton(
                          key: const ValueKey('skipOnboardingButton'),
                          label: 'Lewati',
                          variant: StevButtonVariant.ghost,
                          height: StevSize.tapMin,
                          onPressed: _saving
                              ? null
                              : () => _finish(skipDetails: true),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatefulWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_TimeChip> createState() => _TimeChipState();
}

class _TimeChipState extends State<_TimeChip> {
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
        height: 48,
        decoration: BoxDecoration(
          color: widget.selected ? StevColors.ink : StevColors.glassCard,
          borderRadius: BorderRadius.circular(StevRadius.pill),
          border: Border.all(color: StevColors.glassEdge),
          boxShadow: _pressed
              ? const []
              : widget.selected
              ? StevShadows.pressInkChip
              : StevShadows.pressCard,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(StevRadius.pill),
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            borderRadius: BorderRadius.circular(StevRadius.pill),
            child: Center(
              child: Text(
                widget.label,
                maxLines: 1,
                style: StevType.caption.copyWith(
                  color: widget.selected ? StevColors.onInk : StevColors.ink2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
