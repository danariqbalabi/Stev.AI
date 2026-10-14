import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../domain/risk_assessment.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

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

  void _goBack() {
    if (_subject == null) {
      context.pop();
    } else if (_questionIndex == 0) {
      setState(() => _subject = null);
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

  void _answer(RiskOption option) {
    _answers[_questionIndex] = option;
    if (_questionIndex < RiskAssessment.questions.length - 1) {
      setState(() => _questionIndex++);
      return;
    }

    final result = RiskAssessment.evaluate(
      subject: _subject!,
      answers: _answers.whereType<RiskOption>().toList(),
    );
    context.pushReplacement('/risk/result', extra: result);
  }

  @override
  Widget build(BuildContext context) {
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
                  duration: StevMotion.screenFade,
                  child: _subject == null
                      ? _SubjectStep(onSelected: _selectSubject)
                      : _QuestionStep(
                          key: ValueKey(_questionIndex),
                          subject: _subject!,
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
          'Mau cek untuk siapa?',
          textAlign: TextAlign.center,
          style: StevType.title,
        ),
        const SizedBox(height: StevSpace.s3),
        Text(
          'Jawab 8 pertanyaan singkat untuk melihat gambaran risikonya.',
          textAlign: TextAlign.center,
          style: StevType.body.copyWith(color: StevColors.ink2),
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
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final RiskSubject subject;
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
        Text(question.textFor(subject), style: StevType.title),
        const SizedBox(height: StevSpace.s7),
        for (final option in question.options) ...[
          _ChoiceCard(
            label: option.label,
            selected: identical(selected, option),
            onTap: () => onSelected(option),
          ),
          const SizedBox(height: StevSpace.s3),
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
