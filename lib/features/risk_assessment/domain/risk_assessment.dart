enum RiskSubject { self, parent }

enum RiskLevel { low, medium, high }

class RiskOption {
  const RiskOption({
    required this.label,
    required this.points,
    this.factor,
    this.isUnknown = false,
  });

  final String label;
  final int points;
  final String? factor;
  final bool isUnknown;
}

class RiskQuestion {
  const RiskQuestion({
    required this.selfText,
    required this.parentText,
    required this.options,
  });

  final String selfText;
  final String parentText;
  final List<RiskOption> options;

  String textFor(RiskSubject subject) =>
      subject == RiskSubject.self ? selfText : parentText;
}

class RiskAssessmentResult {
  const RiskAssessmentResult({
    required this.subject,
    required this.level,
    required this.isMinimumEstimate,
    required this.topFactors,
    required this.score,
  });

  final RiskSubject subject;
  final RiskLevel level;
  final bool isMinimumEstimate;
  final List<String> topFactors;

  /// Kept in memory for evaluation only. It is never shown or persisted.
  final int score;
}

abstract final class RiskAssessment {
  static const _unknown = RiskOption(
    label: 'Tidak tahu',
    points: 0,
    isUnknown: true,
  );

  static const questions = <RiskQuestion>[
    RiskQuestion(
      selfText: 'Usia kamu berapa?',
      parentText: 'Usia Ibu/Bapak berapa?',
      options: [
        RiskOption(label: '<45', points: 0),
        RiskOption(label: '45–54', points: 2, factor: 'Usia 45–54'),
        RiskOption(label: '55–64', points: 3, factor: 'Usia 55–64'),
        RiskOption(label: '>64', points: 4, factor: 'Usia di atas 64'),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Berapa kisaran BMI-mu?',
      parentText: 'Berapa kisaran BMI Ibu/Bapak?',
      options: [
        RiskOption(label: '<25', points: 0),
        RiskOption(label: '25–30', points: 1, factor: 'BMI 25–30'),
        RiskOption(label: '>30', points: 3, factor: 'BMI di atas 30'),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Lingkar pinggangmu masuk mana?',
      parentText: 'Lingkar pinggang Ibu/Bapak masuk mana?',
      options: [
        RiskOption(label: 'Rendah', points: 0),
        RiskOption(
          label: 'Sedang',
          points: 3,
          factor: 'Lingkar pinggang sedang',
        ),
        RiskOption(
          label: 'Tinggi',
          points: 4,
          factor: 'Lingkar pinggang tinggi',
        ),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Kamu aktif ≥30 menit sehari?',
      parentText: 'Ibu/Bapak aktif ≥30 menit sehari?',
      options: [
        RiskOption(label: 'Ya', points: 0),
        RiskOption(label: 'Tidak', points: 2, factor: 'Kurang aktif'),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Kamu makan sayur atau buah tiap hari?',
      parentText: 'Ibu/Bapak makan sayur atau buah tiap hari?',
      options: [
        RiskOption(label: 'Ya', points: 0),
        RiskOption(
          label: 'Tidak',
          points: 1,
          factor: 'Jarang makan sayur atau buah',
        ),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Kamu pernah minum obat hipertensi?',
      parentText: 'Ibu/Bapak pernah minum obat hipertensi?',
      options: [
        RiskOption(label: 'Ya', points: 2, factor: 'Obat hipertensi'),
        RiskOption(label: 'Tidak', points: 0),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Kamu pernah punya gula darah tinggi?',
      parentText: 'Ibu/Bapak pernah punya gula darah tinggi?',
      options: [
        RiskOption(label: 'Ya', points: 5, factor: 'Gula darah pernah tinggi'),
        RiskOption(label: 'Tidak', points: 0),
        _unknown,
      ],
    ),
    RiskQuestion(
      selfText: 'Ada riwayat diabetes di keluargamu?',
      parentText: 'Ada riwayat diabetes di keluarga Ibu/Bapak?',
      options: [
        RiskOption(label: 'Tidak ada', points: 0),
        RiskOption(
          label: 'Kakek-nenek, paman, bibi, sepupu',
          points: 3,
          factor: 'Riwayat keluarga besar',
        ),
        RiskOption(
          label: 'Orang tua, saudara kandung, anak',
          points: 5,
          factor: 'Riwayat keluarga inti',
        ),
        _unknown,
      ],
    ),
  ];

  static RiskAssessmentResult evaluate({
    required RiskSubject subject,
    required List<RiskOption> answers,
  }) {
    assert(answers.length == questions.length);
    final score = answers.fold<int>(
      0,
      (total, answer) => total + answer.points,
    );
    final ranked = answers.where((answer) => answer.points > 0).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    return RiskAssessmentResult(
      subject: subject,
      level: score >= 15
          ? RiskLevel.high
          : score >= 12
          ? RiskLevel.medium
          : RiskLevel.low,
      isMinimumEstimate: answers.any((answer) => answer.isUnknown),
      topFactors: ranked
          .map((answer) => answer.factor)
          .whereType<String>()
          .take(3)
          .toList(growable: false),
      score: score,
    );
  }
}
