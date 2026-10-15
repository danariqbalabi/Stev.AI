import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../domain/risk_assessment.dart';

class RiskResultScreen extends StatelessWidget {
  const RiskResultScreen({super.key, required this.result});

  final RiskAssessmentResult result;

  String get _levelLabel => switch (result.level) {
    RiskLevel.low => 'Risiko rendah',
    RiskLevel.medium => 'Risiko sedang',
    RiskLevel.high => 'Risiko tinggi',
  };

  String get _actionTitle => switch (result.level) {
    RiskLevel.low => 'Tetap rutin cek kesehatan',
    RiskLevel.medium => 'Sebaiknya cek gula darah dalam waktu dekat',
    RiskLevel.high => 'Yuk, periksakan ke Puskesmas terdekat',
  };

  String get _actionBody {
    if (result.level == RiskLevel.low) {
      return 'Ulangi Cek Risiko dan ikut Cek Kesehatan Gratis secara berkala.';
    }
    final subject = result.subject == RiskSubject.parent ? 'Ibu/Bapak' : 'Kamu';
    return '$subject bisa ikut Cek Kesehatan Gratis dari Kemenkes. Gula darah termasuk yang diperiksa.';
  }

  Color get _levelColor => switch (result.level) {
    RiskLevel.low => StevColors.leaf,
    RiskLevel.medium => StevColors.sun,
    RiskLevel.high => StevColors.over,
  };

  void _showLocations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          StevSpace.s5,
          StevSpace.s6,
          StevSpace.s5,
          StevSpace.s6 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: StevColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(StevRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puskesmas terdekat', style: StevType.heading),
            const SizedBox(height: StevSpace.s2),
            Text(
              'Contoh lokasi untuk prototipe',
              style: StevType.caption.copyWith(color: StevColors.ink2),
            ),
            const SizedBox(height: StevSpace.s5),
            const _LocationRow('Puskesmas Kecamatan Menteng', '1,2 km'),
            const _LocationRow('Puskesmas Kelurahan Cikini', '2,0 km'),
            const _LocationRow('Puskesmas Kecamatan Senen', '2,8 km'),
            const SizedBox(height: StevSpace.s4),
            StevButton(label: 'Tutup', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }

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
                'Hasil Risiko',
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
                    _levelLabel,
                    style: StevType.label.copyWith(
                      color: result.level == RiskLevel.high
                          ? StevColors.onInk
                          : StevColors.ink,
                    ),
                  ),
                ),
              ),
              if (result.isMinimumEstimate) ...[
                const SizedBox(height: StevSpace.s3),
                Text(
                  'Estimasi minimal karena ada jawaban “Tidak tahu”.',
                  textAlign: TextAlign.center,
                  style: StevType.caption.copyWith(color: StevColors.ink2),
                ),
              ],
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
                    Text(_actionTitle, style: StevType.heading),
                    const SizedBox(height: StevSpace.s2),
                    Text(
                      _actionBody,
                      style: StevType.body.copyWith(color: StevColors.ink2),
                    ),
                    const SizedBox(height: StevSpace.s5),
                    StevButton(
                      label: 'Cari Puskesmas terdekat',
                      variant: StevButtonVariant.leaf,
                      onPressed: () => _showLocations(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StevSpace.s5),
              Text(
                'Ini skrining, bukan diagnosis. Hanya tenaga kesehatan yang bisa memastikan lewat pemeriksaan.',
                textAlign: TextAlign.center,
                style: StevType.caption.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s5),
              StevButton(
                key: const ValueKey('openRiskInvite'),
                label: result.subject == RiskSubject.parent
                    ? 'Ajak Ibu/Bapak periksa'
                    : 'Periksa sekarang',
                variant: StevButtonVariant.leaf,
                onPressed: () =>
                    context.push('/risk/invite', extra: result.subject),
              ),
              const SizedBox(height: StevSpace.s3),
              StevButton(label: 'Selesai', onPressed: () => context.go('/')),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow(this.name, this.distance);

  final String name;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StevSpace.s3),
      child: Row(
        children: [
          const Icon(Icons.local_hospital_outlined),
          const SizedBox(width: StevSpace.s3),
          Expanded(child: Text(name, style: StevType.body)),
          Text(
            distance,
            style: StevType.caption.copyWith(color: StevColors.ink2),
          ),
        ],
      ),
    );
  }
}
