import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../domain/risk_assessment.dart';

class RiskResultScreen extends StatelessWidget {
  const RiskResultScreen({super.key, required this.result});

  final RiskAssessmentResult result;

  String get _levelLabel => switch (result.level) {
    RiskLevel.low => 'Rendah',
    RiskLevel.slightlyElevated => 'Sedikit meningkat',
    RiskLevel.medium => 'Sedang',
    RiskLevel.high => 'Tinggi',
    RiskLevel.veryHigh => 'Sangat tinggi',
  };

  String get _probabilityLabel => switch (result.level) {
    RiskLevel.low => '1 dari 100 dalam 10 tahun',
    RiskLevel.slightlyElevated => '1 dari 25 dalam 10 tahun',
    RiskLevel.medium => '1 dari 6 dalam 10 tahun',
    RiskLevel.high => '1 dari 3 dalam 10 tahun',
    RiskLevel.veryHigh => '1 dari 2 dalam 10 tahun',
  };

  Color get _levelColor => switch (result.level) {
    RiskLevel.medium => StevColors.sugar,
    RiskLevel.high || RiskLevel.veryHigh => StevColors.over,
    RiskLevel.low || RiskLevel.slightlyElevated => StevColors.ink,
  };

  String get _recommendation => switch (result.level) {
    RiskLevel.low => 'Belum perlu tes khusus. Pertahankan kebiasaan sehat dan lakukan cek ulang risiko secara berkala.',
    RiskLevel.slightlyElevated => 'Tes gula darah bersifat opsional, terutama bila ada anggota keluarga dengan diabetes.',
    RiskLevel.medium => 'Disarankan melakukan tes gula darah.',
    RiskLevel.high || RiskLevel.veryHigh =>
      'Segera lakukan tes gula darah dan konsultasi ke dokter.',
  };

  bool get _showTests => switch (result.level) {
    RiskLevel.medium || RiskLevel.high || RiskLevel.veryHigh => true,
    RiskLevel.low || RiskLevel.slightlyElevated => false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('riskResultScreen'),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s4,
              StevSpace.s5,
              StevSpace.s6,
            ),
            children: [
              Text(
                'Hasil cek risiko',
                textAlign: TextAlign.center,
                style: StevType.heading,
              ),
              const SizedBox(height: StevSpace.s7),
              Center(
                child: StevMascot(
                  mood: result.level == RiskLevel.low
                      ? StevMood.happy
                      : StevMood.worried,
                  size: 112,
                ),
              ),
              const SizedBox(height: StevSpace.s5),
              Center(
                child: Container(
                  key: const ValueKey('riskLevelPill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StevSpace.s5,
                    vertical: StevSpace.s3,
                  ),
                  decoration: BoxDecoration(
                    color: _levelColor,
                    borderRadius: BorderRadius.circular(StevRadius.pill),
                  ),
                  child: Text(
                    'Risiko $_levelLabel',
                    style: StevType.label.copyWith(color: StevColors.onInk),
                  ),
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              Semantics(
                label: 'Skor FINDRISC ${result.score} dari 26',
                child: Text(
                  '${result.score}',
                  key: const ValueKey('riskScore'),
                  textAlign: TextAlign.center,
                  style: StevType.number,
                ),
              ),
              Text(
                'Skor FINDRISC dari 26',
                textAlign: TextAlign.center,
                style: StevType.caption.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s2),
              Text(
                'Perkiraan risiko: $_probabilityLabel',
                textAlign: TextAlign.center,
                style: StevType.body,
              ),
              const SizedBox(height: StevSpace.s7),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yang paling berpengaruh', style: StevType.heading),
                    const SizedBox(height: StevSpace.s3),
                    if (result.topFactors.isEmpty)
                      Text(
                        'Belum ada faktor utama',
                        style: StevType.body.copyWith(color: StevColors.ink2),
                      )
                    else
                      Wrap(
                        spacing: StevSpace.s2,
                        runSpacing: StevSpace.s2,
                        children: [
                          for (final factor in result.topFactors)
                            Chip(
                              label: Text(factor),
                              backgroundColor: StevColors.card,
                              side: const BorderSide(
                                color: StevColors.glassEdge,
                              ),
                              labelStyle: StevType.caption,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tes yang bisa kamu ambil', style: StevType.heading),
                    const SizedBox(height: StevSpace.s2),
                    Text(
                      _recommendation,
                      style: StevType.body.copyWith(color: StevColors.ink2),
                    ),
                    if (_showTests) ...[
                      const SizedBox(height: StevSpace.s5),
                      const _TestCard(
                        name: 'GDP (Gula Darah Puasa)',
                        measures: 'Kadar gula darah setelah puasa',
                        preparation:
                            'Puasa minimal 8 jam; air putih diperbolehkan',
                        note: 'Paling umum dan terjangkau; tersedia di banyak Puskesmas',
                      ),
                      const _TestCard(
                        name: 'HbA1c',
                        measures: 'Rata-rata kadar gula darah sekitar 3 bulan terakhir',
                        preparation: 'Tidak perlu puasa',
                        note: 'Biaya lebih tinggi; belum tersedia di semua Puskesmas',
                      ),
                      const _TestCard(
                        name: 'TTGO (Tes Toleransi Glukosa Oral)',
                        measures: 'Kadar gula darah 2 jam setelah minum larutan glukosa',
                        preparation:
                            'Puasa, lalu menunggu 2 jam di laboratorium',
                        note: 'Umumnya dilakukan atas permintaan dokter',
                      ),
                      const SizedBox(height: StevSpace.s3),
                      Text(
                        'Tes tersedia di Puskesmas, klinik, atau laboratorium. Tanyakan ketersediaan dan persiapannya kepada fasilitas kesehatan.',
                        style: StevType.caption.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: StevSpace.s5),
              Text(
                'Hasil ini merupakan skrining risiko, bukan diagnosis. Konsultasikan hasil pemeriksaan kepada tenaga kesehatan.',
                textAlign: TextAlign.center,
                style: StevType.caption.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s5),
              if (result.shouldOfferParentInvite) ...[
                StevButton(
                  key: const ValueKey('openRiskInvite'),
                  label: 'Ajak Ayah/Ibu cek',
                  variant: StevButtonVariant.leaf,
                  onPressed: () => context.push('/risk/invite', extra: result),
                ),
                const SizedBox(height: StevSpace.s3),
              ],
              StevButton(
                key: const ValueKey('finishRiskAssessment'),
                label: 'Selesai',
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.name,
    required this.measures,
    required this.preparation,
    required this.note,
  });

  final String name;
  final String measures;
  final String preparation;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: StevSpace.s3),
      padding: const EdgeInsets.all(StevSpace.s4),
      decoration: BoxDecoration(
        color: StevColors.card,
        borderRadius: BorderRadius.circular(StevRadius.small),
        border: Border.all(color: StevColors.pressCardEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: StevType.label),
          const SizedBox(height: StevSpace.s2),
          _TestDetail(label: 'Yang diukur', value: measures),
          _TestDetail(label: 'Persiapan', value: preparation),
          _TestDetail(label: 'Catatan', value: note),
        ],
      ),
    );
  }
}

class _TestDetail extends StatelessWidget {
  const _TestDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: StevSpace.s1),
      child: Text.rich(
        TextSpan(
          style: StevType.caption.copyWith(color: StevColors.ink2),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
