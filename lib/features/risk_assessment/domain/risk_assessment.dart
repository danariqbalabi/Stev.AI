enum RiskSubject { self, parent }

enum RiskLevel { low, slightlyElevated, medium, high, veryHigh }

class RiskOption {
  const RiskOption({required this.label, required this.points, this.factor});

  final String label;
  final int points;
  final String? factor;
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
    required this.topFactors,
    required this.score,
    this.familyMemberId,
  });

  final RiskSubject subject;
  final RiskLevel level;
  final List<String> topFactors;
  final String? familyMemberId;

  /// Kept in memory for the current flow. It is never persisted.
  final int score;

  bool get shouldOfferParentInvite => score >= 12;
}

abstract final class RiskAssessment {
  static const questions = <RiskQuestion>[
    RiskQuestion(
      selfText: 'Usia kamu berapa?',
      parentText: 'Usia Ayah/Ibu berapa?',
      options: [
        RiskOption(label: '<45', points: 0),
        RiskOption(label: '45-54', points: 2, factor: 'Usia 45-54'),
        RiskOption(label: '55-64', points: 3, factor: 'Usia 55-64'),
        RiskOption(label: '>64', points: 4, factor: 'Usia di atas 64'),
      ],
    ),
    RiskQuestion(
      selfText: 'Berapa BMI-mu?',
      parentText: 'Berapa BMI Ayah/Ibu?',
      options: [
        RiskOption(label: '<25', points: 0),
        RiskOption(label: '25-30', points: 1, factor: 'BMI 25-30'),
        RiskOption(label: '>30', points: 3, factor: 'BMI di atas 30'),
      ],
    ),
    RiskQuestion(
      selfText: 'Berapa lingkar pinggangmu?',
      parentText: 'Berapa lingkar pinggang Ayah/Ibu?',
      options: [
        RiskOption(label: 'Di bawah batas', points: 0),
        RiskOption(
          label: 'Rentang tengah',
          points: 3,
          factor: 'Lingkar pinggang meningkat',
        ),
        RiskOption(
          label: 'Di atas batas',
          points: 4,
          factor: 'Lingkar pinggang tinggi',
        ),
      ],
    ),
    RiskQuestion(
      selfText:
          'Apakah kamu melakukan aktivitas fisik minimal 30 menit setiap hari?',
      parentText: 'Apakah Ayah/Ibu melakukan aktivitas fisik minimal 30 menit setiap hari?',
      options: [
        RiskOption(label: 'Ya', points: 0),
        RiskOption(label: 'Tidak', points: 2, factor: 'Kurang aktif'),
      ],
    ),
    RiskQuestion(
      selfText: 'Apakah kamu mengonsumsi sayur atau buah setiap hari?',
      parentText: 'Apakah Ayah/Ibu mengonsumsi sayur atau buah setiap hari?',
      options: [
        RiskOption(label: 'Ya', points: 0),
        RiskOption(
          label: 'Tidak',
          points: 1,
          factor: 'Jarang makan sayur atau buah',
        ),
      ],
    ),
    RiskQuestion(
      selfText: 'Apakah kamu pernah rutin mengonsumsi obat darah tinggi?',
      parentText: 'Apakah Ayah/Ibu pernah rutin mengonsumsi obat darah tinggi?',
      options: [
        RiskOption(label: 'Tidak', points: 0),
        RiskOption(label: 'Ya', points: 2, factor: 'Obat darah tinggi'),
      ],
    ),
    RiskQuestion(
      selfText: 'Apakah kamu pernah diketahui memiliki gula darah tinggi?',
      parentText:
          'Apakah Ayah/Ibu pernah diketahui memiliki gula darah tinggi?',
      options: [
        RiskOption(label: 'Tidak', points: 0),
        RiskOption(label: 'Ya', points: 5, factor: 'Gula darah pernah tinggi'),
      ],
    ),
    RiskQuestion(
      selfText: 'Apakah ada anggota keluargamu yang didiagnosis diabetes?',
      parentText:
          'Apakah ada anggota keluarga Ayah/Ibu yang didiagnosis diabetes?',
      options: [
        RiskOption(label: 'Tidak', points: 0),
        RiskOption(
          label: 'Kakek/nenek, paman/bibi, sepupu',
          points: 3,
          factor: 'Riwayat keluarga besar',
        ),
        RiskOption(
          label: 'Orang tua, saudara kandung, anak',
          points: 5,
          factor: 'Riwayat keluarga inti',
        ),
      ],
    ),
  ];

  static RiskLevel levelForScore(int score) {
    if (score > 20) return RiskLevel.veryHigh;
    if (score >= 15) return RiskLevel.high;
    if (score >= 12) return RiskLevel.medium;
    if (score >= 7) return RiskLevel.slightlyElevated;
    return RiskLevel.low;
  }

  static RiskAssessmentResult evaluate({
    required RiskSubject subject,
    required List<RiskOption> answers,
    String? familyMemberId,
  }) {
    if (answers.length != questions.length) {
      throw ArgumentError.value(
        answers.length,
        'answers',
        'All eight FINDRISC questions must be answered.',
      );
    }
    final score = answers.fold<int>(
      0,
      (total, answer) => total + answer.points,
    );
    final ranked = answers.where((answer) => answer.points > 0).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    return RiskAssessmentResult(
      subject: subject,
      level: levelForScore(score),
      topFactors: ranked
          .map((answer) => answer.factor)
          .whereType<String>()
          .take(3)
          .toList(growable: false),
      score: score,
      familyMemberId: familyMemberId,
    );
  }
}
