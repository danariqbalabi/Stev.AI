import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../family/application/family_controller.dart';
import '../../family/domain/family_member.dart';
import '../data/risk_history_preferences.dart';
import '../domain/bmi_calculator.dart';
import '../domain/risk_assessment.dart';
import '../domain/waist_calculator.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key, this.familyMemberId});

  final String? familyMemberId;

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  RiskSubject? _subject;
  var _questionIndex = 0;
  final List<RiskOption?> _answers = List.filled(
    RiskAssessment.questions.length,
    null,
  );
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  WaistSex? _waistSex;
  bool _useBmiCalculator = false;
  bool _useWaistCalculator = false;
  bool _savingResult = false;

  @override
  void initState() {
    super.initState();
    if (widget.familyMemberId != null) _subject = RiskSubject.parent;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_subject == null) {
      context.pop();
    } else if (_questionIndex == 0) {
      if (widget.familyMemberId != null) {
        context.pop();
      } else {
        setState(() => _subject = null);
      }
    } else {
      setState(() => _questionIndex--);
    }
  }

  void _selectSubject(RiskSubject subject) {
    setState(() {
      _subject = subject;
      _questionIndex = 0;
    });
  }

  Future<void> _answer(RiskOption option) async {
    if (_savingResult) return;
    _answers[_questionIndex] = option;
    if (_questionIndex < RiskAssessment.questions.length - 1) {
      setState(() => _questionIndex++);
      return;
    }

    final familyController = widget.familyMemberId == null
        ? null
        : FamilyScope.read(context);
    final familyMember = widget.familyMemberId == null
        ? null
        : familyController?.memberById(widget.familyMemberId!);
    final result = RiskAssessment.evaluate(
      subject: _subject!,
      answers: _answers.whereType<RiskOption>().toList(),
      familyMemberId: widget.familyMemberId,
      subjectName: familyMember?.nickname,
    );
    setState(() => _savingResult = true);
    await RiskHistoryPreferences().add(result);
    if (widget.familyMemberId case final memberId?) {
      await familyController?.updateStatus(
        memberId,
        FamilyProgressStatus.assessed,
      );
    }
    if (mounted) context.pushReplacement('/risk/result', extra: result);
  }

  BmiCalculation? get _bmiCalculation => BmiCalculator.calculate(
    heightCentimeters: _heightController.text,
    weightKilograms: _weightController.text,
  );

  void _answerBmi() {
    final calculation = _bmiCalculation;
    if (calculation == null) return;
    final options = RiskAssessment.questions[1].options;
    final option = switch (calculation.category) {
      BmiCategory.below25 => options[0],
      BmiCategory.from25To30 => options[1],
      BmiCategory.above30 => options[2],
    };
    _answer(option);
  }

  WaistCalculation? get _waistCalculation => WaistCalculator.calculate(
    circumferenceCentimeters: _waistController.text,
    sex: _waistSex,
  );

  void _answerWaist() {
    final calculation = _waistCalculation;
    if (calculation == null) return;
    final options = RiskAssessment.questions[2].options;
    final option = switch (calculation.category) {
      WaistCategory.belowThreshold => options[0],
      WaistCategory.middleRange => options[1],
      WaistCategory.aboveThreshold => options[2],
    };
    _answer(option);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final familyMemberName = widget.familyMemberId == null
        ? null
        : FamilyScope.watch(context)
              .memberById(widget.familyMemberId!)
              ?.nickname;

    return Scaffold(
      key: const ValueKey('riskAssessmentScreen'),
      body: AuraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  StevSpace.s5,
                  StevSpace.s3,
                  StevSpace.s5,
                  0,
                ),
                child: Row(
                  children: [
                    StevIconButton(
                      icon: const StevIcon(StevIconName.back),
                      label: 'Kembali',
                      onPressed: _goBack,
                    ),
                    Expanded(
                      child: Text(
                        'Cek Risiko',
                        textAlign: TextAlign.center,
                        style: StevType.heading,
                      ),
                    ),
                    const SizedBox(width: StevSize.roundButton),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? StevMotion.reduced
                      : StevMotion.screenFade,
                  child: _subject == null
                      ? _SubjectStep(onSelected: _selectSubject)
                      : _questionIndex == 1
                      ? _BmiQuestionStep(
                          key: const ValueKey('bmiQuestionStep'),
                          subject: _subject!,
                          familyMemberName: familyMemberName,
                          heightController: _heightController,
                          weightController: _weightController,
                          calculation: _bmiCalculation,
                          useCalculator: _useBmiCalculator,
                          onUseCalculatorChanged: (value) =>
                              setState(() => _useBmiCalculator = value),
                          onOptionSelected: _answer,
                          onChanged: () => setState(() {}),
                          onContinue: _answerBmi,
                        )
                      : _questionIndex == 2
                      ? _WaistQuestionStep(
                          key: const ValueKey('waistQuestionStep'),
                          subject: _subject!,
                          familyMemberName: familyMemberName,
                          controller: _waistController,
                          selectedSex: _waistSex,
                          calculation: _waistCalculation,
                          useCalculator: _useWaistCalculator,
                          onUseCalculatorChanged: (value) =>
                              setState(() => _useWaistCalculator = value),
                          onOptionSelected: _answer,
                          onSexChanged: (sex) =>
                              setState(() => _waistSex = sex),
                          onChanged: () => setState(() {}),
                          onContinue: _answerWaist,
                        )
                      : _QuestionStep(
                          key: ValueKey(_questionIndex),
                          subject: _subject!,
                          familyMemberName: familyMemberName,
                          index: _questionIndex,
                          selected: _answers[_questionIndex],
                          onSelected: _answer,
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

class _BmiQuestionStep extends StatelessWidget {
  const _BmiQuestionStep({
    super.key,
    required this.subject,
    this.familyMemberName,
    required this.heightController,
    required this.weightController,
    required this.calculation,
    required this.useCalculator,
    required this.onUseCalculatorChanged,
    required this.onOptionSelected,
    required this.onChanged,
    required this.onContinue,
  });

  final RiskSubject subject;
  final String? familyMemberName;
  final TextEditingController heightController;
  final TextEditingController weightController;
  final BmiCalculation? calculation;
  final bool useCalculator;
  final ValueChanged<bool> onUseCalculatorChanged;
  final ValueChanged<RiskOption> onOptionSelected;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  String get _categoryLabel => switch (calculation?.category) {
    BmiCategory.below25 => '<25',
    BmiCategory.from25To30 => '25–30',
    BmiCategory.above30 => '>30',
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    final question = RiskAssessment.questions[1];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StevSpace.s5,
        StevSpace.s6,
        StevSpace.s5,
        StevSpace.s6,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(StevRadius.pill),
                child: const LinearProgressIndicator(
                  minHeight: 8,
                  value: 2 / 8,
                  color: StevColors.leaf,
                  backgroundColor: StevColors.card,
                ),
              ),
            ),
            const SizedBox(width: StevSpace.s3),
            Text(
              '2/${RiskAssessment.questions.length}',
              style: StevType.caption.copyWith(color: StevColors.ink2),
            ),
          ],
        ),
        const SizedBox(height: StevSpace.s7),
        Text(
          question.textFor(subject, familyMemberName: familyMemberName),
          style: StevType.title,
        ),
        const SizedBox(height: StevSpace.s2),
        Text(
          'Pilih kategori BMI. Kalau belum tahu, hitung dari tinggi dan berat.',
          style: StevType.body.copyWith(color: StevColors.ink2),
        ),
        const SizedBox(height: StevSpace.s5),
        for (final option in question.options) ...[
          _ChoiceCard(
            label: option.label,
            onTap: () => onOptionSelected(option),
          ),
          const SizedBox(height: StevSpace.s3),
        ],
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            key: const ValueKey('bmiCalculatorToggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Hitung BMI dari tinggi & berat'),
            subtitle: const Text(
              'Opsional dan hanya dihitung di perangkat ini.',
            ),
            value: useCalculator,
            onChanged: onUseCalculatorChanged,
          ),
        ),
        if (useCalculator) ...[
          const SizedBox(height: StevSpace.s3),
          Row(
            children: [
              Expanded(
                child: _MeasurementField(
                  key: const ValueKey('bmiHeightField'),
                  controller: heightController,
                  label: subject == RiskSubject.parent
                      ? 'Tinggi badan ${familyMemberName ?? 'Ayah/Ibu'}'
                      : 'Tinggi badan',
                  suffix: 'cm',
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: StevSpace.s3),
              Expanded(
                child: _MeasurementField(
                  key: const ValueKey('bmiWeightField'),
                  controller: weightController,
                  label: subject == RiskSubject.parent
                      ? 'Berat badan ${familyMemberName ?? 'Ayah/Ibu'}'
                      : 'Berat badan',
                  suffix: 'kg',
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: StevSpace.s5),
          GlassCard(
            child: calculation == null
                ? Text(
                    'Isi tinggi 80–250 cm dan berat 20–400 kg.',
                    style: StevType.body.copyWith(color: StevColors.ink2),
                  )
                : Column(
                    children: [
                      Text(
                        'BMI ${calculation!.value.toStringAsFixed(1)}',
                        style: StevType.heading,
                      ),
                      const SizedBox(height: StevSpace.s1),
                      Text(
                        'Kategori $_categoryLabel',
                        key: const ValueKey('bmiCategory'),
                        style: StevType.body.copyWith(color: StevColors.ink2),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: StevSpace.s5),
          StevButton(
            key: const ValueKey('bmiContinue'),
            label: 'Gunakan hasil BMI',
            variant: StevButtonVariant.leaf,
            onPressed: calculation == null ? null : onContinue,
          ),
        ],
        if (subject == RiskSubject.parent) ...[
          const SizedBox(height: StevSpace.s3),
          Text(
            'Belum tahu? Tanyakan terlebih dahulu kepada ${familyMemberName ?? 'Ayah/Ibu'}.',
            textAlign: TextAlign.center,
            style: StevType.caption.copyWith(color: StevColors.ink2),
          ),
        ],
      ],
    );
  }
}

class _WaistQuestionStep extends StatelessWidget {
  const _WaistQuestionStep({
    super.key,
    required this.subject,
    this.familyMemberName,
    required this.controller,
    required this.selectedSex,
    required this.calculation,
    required this.useCalculator,
    required this.onUseCalculatorChanged,
    required this.onOptionSelected,
    required this.onSexChanged,
    required this.onChanged,
    required this.onContinue,
  });

  final RiskSubject subject;
  final String? familyMemberName;
  final TextEditingController controller;
  final WaistSex? selectedSex;
  final WaistCalculation? calculation;
  final bool useCalculator;
  final ValueChanged<bool> onUseCalculatorChanged;
  final ValueChanged<RiskOption> onOptionSelected;
  final ValueChanged<WaistSex> onSexChanged;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  String get _categoryLabel => switch (calculation?.category) {
    WaistCategory.belowThreshold => 'Di bawah batas',
    WaistCategory.middleRange => 'Rentang tengah',
    WaistCategory.aboveThreshold => 'Di atas batas',
    null => '',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StevSpace.s5,
        StevSpace.s6,
        StevSpace.s5,
        StevSpace.s6,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(StevRadius.pill),
                child: const LinearProgressIndicator(
                  minHeight: 8,
                  value: 3 / 8,
                  color: StevColors.leaf,
                  backgroundColor: StevColors.card,
                ),
              ),
            ),
            const SizedBox(width: StevSpace.s3),
            Text(
              '3/8',
              style: StevType.caption.copyWith(color: StevColors.ink2),
            ),
          ],
        ),
        const SizedBox(height: StevSpace.s7),
        Text(
          RiskAssessment.questions[2].textFor(
            subject,
            familyMemberName: familyMemberName,
          ),
          style: StevType.title,
        ),
        const SizedBox(height: StevSpace.s2),
        Text(
          'Pilih kategorinya. Kalau belum tahu, gunakan pengukuran manual.',
          style: StevType.body.copyWith(color: StevColors.ink2),
        ),
        const SizedBox(height: StevSpace.s5),
        for (final option in RiskAssessment.questions[2].options) ...[
          _ChoiceCard(
            label: option.label,
            onTap: () => onOptionSelected(option),
          ),
          const SizedBox(height: StevSpace.s3),
        ],
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            key: const ValueKey('waistCalculatorToggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Hitung dari lingkar pinggang'),
            subtitle: const Text(
              'Opsional, ukur sejajar pusar dengan meteran.',
            ),
            value: useCalculator,
            onChanged: onUseCalculatorChanged,
          ),
        ),
        if (useCalculator) ...[
          const SizedBox(height: StevSpace.s4),
          SegmentedButton<WaistSex>(
            key: const ValueKey('waistSexSelector'),
            segments: const [
              ButtonSegment(value: WaistSex.male, label: Text('Pria')),
              ButtonSegment(value: WaistSex.female, label: Text('Wanita')),
            ],
            selected: selectedSex == null ? const {} : {selectedSex!},
            emptySelectionAllowed: true,
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onSexChanged(selection.first);
            },
          ),
          const SizedBox(height: StevSpace.s4),
          _MeasurementField(
            key: const ValueKey('waistField'),
            controller: controller,
            label: subject == RiskSubject.parent
                ? 'Lingkar pinggang ${familyMemberName ?? 'Ayah/Ibu'}'
                : 'Lingkar pinggang',
            suffix: 'cm',
            onChanged: onChanged,
          ),
          if (calculation != null) ...[
            const SizedBox(height: StevSpace.s4),
            GlassCard(
              child: Text(
                'Kategori $_categoryLabel',
                key: const ValueKey('waistCategory'),
                textAlign: TextAlign.center,
                style: StevType.heading,
              ),
            ),
          ],
          const SizedBox(height: StevSpace.s5),
          StevButton(
            key: const ValueKey('waistContinue'),
            label: 'Gunakan hasil pengukuran',
            variant: StevButtonVariant.leaf,
            onPressed: calculation == null ? null : onContinue,
          ),
        ],
        if (subject == RiskSubject.parent) ...[
          const SizedBox(height: StevSpace.s3),
          Text(
            'Belum tahu? Tanyakan terlebih dahulu kepada ${familyMemberName ?? 'Ayah/Ibu'}.',
            textAlign: TextAlign.center,
            style: StevType.caption.copyWith(color: StevColors.ink2),
          ),
        ],
      ],
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}

class _SubjectStep extends StatelessWidget {
  const _SubjectStep({required this.onSelected});

  final ValueChanged<RiskSubject> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StevSpace.s5,
        StevSpace.s10,
        StevSpace.s5,
        StevSpace.s6,
      ),
      children: [
        const Center(child: StevMascot(mood: StevMood.happy, size: 110)),
        const SizedBox(height: StevSpace.s6),
        Text(
          'Cek risiko untuk siapa?',
          textAlign: TextAlign.center,
          style: StevType.title,
        ),
        const SizedBox(height: StevSpace.s7),
        _ChoiceCard(
          label: 'Diri sendiri',
          onTap: () => onSelected(RiskSubject.self),
        ),
        const SizedBox(height: StevSpace.s3),
        _ChoiceCard(
          label: 'Orang tua',
          onTap: () => onSelected(RiskSubject.parent),
        ),
        const SizedBox(height: StevSpace.s7),
        Text(
          'Jawaban diproses di perangkatmu. Kami tidak menyimpan nama atau data kesehatan orang tuamu.',
          textAlign: TextAlign.center,
          style: StevType.caption.copyWith(color: StevColors.ink2),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    super.key,
    required this.subject,
    this.familyMemberName,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final RiskSubject subject;
  final String? familyMemberName;
  final int index;
  final RiskOption? selected;
  final ValueChanged<RiskOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final question = RiskAssessment.questions[index];
    final progress = (index + 1) / RiskAssessment.questions.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StevSpace.s5,
        StevSpace.s6,
        StevSpace.s5,
        StevSpace.s6,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(StevRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  color: StevColors.leaf,
                  backgroundColor: StevColors.card,
                ),
              ),
            ),
            const SizedBox(width: StevSpace.s3),
            Text(
              '${index + 1}/${RiskAssessment.questions.length}',
              style: StevType.caption.copyWith(color: StevColors.ink2),
            ),
          ],
        ),
        const SizedBox(height: StevSpace.s10),
        Text(
          question.textFor(subject, familyMemberName: familyMemberName),
          style: StevType.title,
        ),
        const SizedBox(height: StevSpace.s7),
        for (final option in question.options) ...[
          _ChoiceCard(
            label: option.label,
            selected: identical(selected, option),
            onTap: () => onSelected(option),
          ),
          const SizedBox(height: StevSpace.s3),
        ],
        if (subject == RiskSubject.parent) ...[
          const SizedBox(height: StevSpace.s2),
          Text(
            'Belum tahu? Tanyakan terlebih dahulu kepada ${familyMemberName ?? 'Ayah/Ibu'}.',
            textAlign: TextAlign.center,
            style: StevType.caption.copyWith(color: StevColors.ink2),
          ),
        ],
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? StevColors.leaf.withValues(alpha: 0.18)
          : StevColors.card,
      borderRadius: BorderRadius.circular(StevRadius.row),
      child: InkWell(
        key: ValueKey('riskOption-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(StevRadius.row),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: StevSpace.s5,
            vertical: StevSpace.s4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(StevRadius.row),
            border: Border.all(
              color: selected ? StevColors.leaf : StevColors.glassEdge,
            ),
            boxShadow: StevShadows.elevCard,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: StevType.label)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
