import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../risk_assessment/data/risk_history_preferences.dart';
import '../../risk_assessment/domain/risk_assessment.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  OnboardingProfile _profile = const OnboardingProfile();
  List<RiskHistoryEntry> _riskHistory = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final profile = await OnboardingPreferences.readProfile();
    final history = await RiskHistoryPreferences().read();
    if (mounted) {
      setState(() {
        _profile = profile;
        _riskHistory = history;
      });
    }
  }

  Future<void> _editProfile() async {
    await context.push('/profile/edit');
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile.name ?? 'Pengguna Stev';
    final drinkTime = _profile.drinkTime ?? 'Belum dipilih';

    return Scaffold(
      key: const ValueKey('profileScreen'),
      extendBody: true,
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              StevSpace.s5,
              StevSpace.s4,
              StevSpace.s5,
              128,
            ),
            children: [
              const StevLogo(markSize: 30),
              const SizedBox(height: StevSpace.s7),
              Text('Profil', style: StevType.title),
              const SizedBox(height: StevSpace.s5),
              GlassCard(
                padding: const EdgeInsets.all(StevSpace.s5),
                child: Column(
                  children: [
                    const StevMascot(mood: StevMood.happy, size: 92),
                    const SizedBox(height: StevSpace.s3),
                    Text(name, style: StevType.heading),
                    const SizedBox(height: StevSpace.s1),
                    Text(
                      'Waktu beli minuman: $drinkTime',
                      style: StevType.body.copyWith(color: StevColors.ink2),
                    ),
                    const SizedBox(height: StevSpace.s5),
                    StevButton(
                      key: const ValueKey('editProfileButton'),
                      label: 'Ubah profil',
                      onPressed: _editProfile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              Text('Riwayat cek risiko', style: StevType.heading),
              const SizedBox(height: StevSpace.s3),
              if (_riskHistory.isEmpty)
                GlassCard(
                  key: const ValueKey('emptyRiskHistory'),
                  padding: const EdgeInsets.all(StevSpace.s4),
                  child: Text(
                    'Belum ada hasil cek risiko yang tersimpan.',
                    style: StevType.body.copyWith(color: StevColors.ink2),
                  ),
                )
              else
                for (final entry in _riskHistory) ...[
                  _RiskHistoryCard(entry: entry),
                  const SizedBox(height: StevSpace.s3),
                ],
              const SizedBox(height: StevSpace.s2),
              GlassCard(
                padding: const EdgeInsets.all(StevSpace.s4),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded),
                    const SizedBox(width: StevSpace.s3),
                    Expanded(
                      child: Text(
                        'Profil dan catatan minuman tersimpan di perangkat ini.',
                        style: StevType.caption.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StevTabBar(
        activeTab: StevTab.profile,
        onHome: () => context.go('/'),
        onFamily: () => context.go('/family'),
        onScan: () => context.push('/scan'),
        onWeekly: () => context.go('/weekly'),
        onProfile: () {},
      ),
    );
  }
}

class _RiskHistoryCard extends StatelessWidget {
  const _RiskHistoryCard({required this.entry});

  final RiskHistoryEntry entry;

  String get _levelLabel => switch (entry.level) {
    RiskLevel.low => 'Rendah',
    RiskLevel.slightlyElevated => 'Sedikit meningkat',
    RiskLevel.medium => 'Sedang',
    RiskLevel.high => 'Tinggi',
    RiskLevel.veryHigh => 'Sangat tinggi',
  };

  String get _dateLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${entry.checkedAt.day} ${months[entry.checkedAt.month - 1]} ${entry.checkedAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: StevRadius.row,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('riskHistory-${entry.id}'),
          onTap: () => context.push('/risk/result', extra: entry.toResult()),
          borderRadius: BorderRadius.circular(StevRadius.row),
          child: Padding(
            padding: const EdgeInsets.all(StevSpace.s4),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety_outlined),
                const SizedBox(width: StevSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risiko $_levelLabel • skor ${entry.score}',
                        style: StevType.label,
                      ),
                      const SizedBox(height: StevSpace.s1),
                      Text(
                        '${entry.subject == RiskSubject.self ? 'Diri sendiri' : entry.subjectName ?? 'Anggota keluarga'} • $_dateLabel',
                        style: StevType.caption.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
