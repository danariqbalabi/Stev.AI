import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../auth/application/auth_controller.dart';
import '../../drinks/application/drink_log_controller.dart';
import '../../family/application/family_controller.dart';
import '../../onboarding/data/onboarding_preferences.dart';
import '../../risk_assessment/data/risk_history_preferences.dart';
import '../../risk_assessment/domain/risk_assessment.dart';
import '../../sync/application/cloud_sync_controller.dart';
import '../data/local_data_preferences.dart';

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

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
    required Key confirmKey,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                key: confirmKey,
                onPressed: () => Navigator.pop(context, true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteHistory(RiskHistoryEntry entry) async {
    final confirmed = await _confirm(
      title: 'Hapus hasil cek?',
      message: 'Hasil cek risiko ini akan dihapus dari perangkat.',
      actionLabel: 'Hapus',
      confirmKey: const ValueKey('confirmDeleteRiskHistory'),
    );
    if (!confirmed) return;
    await RiskHistoryPreferences().remove(entry.id);
    if (mounted) await _loadProfile();
  }

  Future<void> _clearHistory() async {
    final confirmed = await _confirm(
      title: 'Hapus semua riwayat?',
      message: 'Semua hasil cek risiko akan dihapus permanen dari perangkat.',
      actionLabel: 'Hapus semua',
      confirmKey: const ValueKey('confirmClearRiskHistory'),
    );
    if (!confirmed) return;
    await RiskHistoryPreferences().clear();
    if (mounted) await _loadProfile();
  }

  Future<void> _signOut() async {
    final synced = await CloudSyncScope.read(context).syncNow();
    if (!synced || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Data belum berhasil disinkronkan. Coba keluar lagi nanti.',
            ),
          ),
        );
      }
      return;
    }
    final signedOut = await AuthScope.read(context).signOut();
    if (!signedOut || !mounted) return;
    await DrinkLogScope.read(context).resetLocalState();
    if (!mounted) return;
    FamilyScope.read(context).resetLocalState();
    await LocalDataPreferences.resetAll();
    if (mounted) context.go('/onboarding');
  }

  Future<void> _resetLocalData() async {
    final confirmed = await _confirm(
      title: 'Reset data aplikasi?',
      message: 'Profil, catatan minuman, streak, keluarga, dan riwayat cek risiko akan dihapus permanen dari perangkat ini.',
      actionLabel: 'Reset data',
      confirmKey: const ValueKey('confirmResetLocalData'),
    );
    if (!confirmed || !mounted) return;

    final cloudDeleted = await CloudSyncScope.read(context).deleteCloudData();
    if (!cloudDeleted || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data cloud belum terhapus. Coba reset lagi.'),
          ),
        );
      }
      return;
    }
    await AuthScope.read(context).signOut(localOnly: true);
    if (!mounted) return;
    await DrinkLogScope.read(context).resetLocalState();
    if (!mounted) return;
    FamilyScope.read(context).resetLocalState();
    await LocalDataPreferences.resetAll();
    if (mounted) context.go('/onboarding');
  }

  Future<void> _syncNow() async {
    final success = await CloudSyncScope.read(context).syncNow();
    if (!mounted) return;
    await _loadProfile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Data berhasil disinkronkan.'
              : 'Sinkronisasi belum berhasil. Coba lagi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.watch(context);
    final sync = CloudSyncScope.watch(context);
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
              Text('Akun', style: StevType.heading),
              const SizedBox(height: StevSpace.s3),
              GlassCard(
                key: const ValueKey('profileAccountCard'),
                padding: const EdgeInsets.all(StevSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          auth.isSignedIn
                              ? Icons.cloud_done_outlined
                              : Icons.cloud_off_outlined,
                        ),
                        const SizedBox(width: StevSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.isSignedIn
                                    ? 'Akun terhubung'
                                    : 'Mode tamu',
                                style: StevType.label,
                              ),
                              const SizedBox(height: StevSpace.s1),
                              Text(
                                auth.user?.email ?? 'Data saat ini hanya tersimpan di perangkat ini.',
                                style: StevType.caption.copyWith(
                                  color: StevColors.ink2,
                                ),
                              ),
                              if (auth.isSignedIn) ...[
                                const SizedBox(height: StevSpace.s1),
                                Text(
                                  _syncStatusLabel(sync),
                                  key: const ValueKey('cloudSyncStatus'),
                                  style: StevType.caption.copyWith(
                                    color: sync.status == CloudSyncStatus.error
                                        ? Theme.of(context).colorScheme.error
                                        : StevColors.ink2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: StevSpace.s3),
                    StevButton(
                      key: ValueKey(
                        auth.isSignedIn ? 'signOutButton' : 'openAuthButton',
                      ),
                      label: auth.isSignedIn
                          ? 'Keluar dari akun'
                          : 'Masuk atau daftar',
                      variant: StevButtonVariant.card,
                      onPressed: auth.isLoading
                          ? null
                          : auth.isSignedIn
                          ? _signOut
                          : () => context.push('/auth'),
                    ),
                    if (auth.isSignedIn) ...[
                      const SizedBox(height: StevSpace.s2),
                      StevButton(
                        key: const ValueKey('syncNowButton'),
                        label: sync.status == CloudSyncStatus.syncing
                            ? 'Menyinkronkan...'
                            : 'Sinkronkan sekarang',
                        variant: StevButtonVariant.ghost,
                        icon: const Icon(Icons.sync_rounded),
                        onPressed:
                            sync.canSync &&
                                sync.status != CloudSyncStatus.syncing
                            ? _syncNow
                            : null,
                      ),
                    ],
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
                  _RiskHistoryCard(
                    entry: entry,
                    onDelete: () => _deleteHistory(entry),
                  ),
                  const SizedBox(height: StevSpace.s3),
                ],
              if (_riskHistory.isNotEmpty) ...[
                StevButton(
                  key: const ValueKey('clearRiskHistoryButton'),
                  label: 'Hapus semua riwayat',
                  variant: StevButtonVariant.ghost,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: _clearHistory,
                ),
                const SizedBox(height: StevSpace.s2),
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
                        auth.isSignedIn
                            ? 'Data tersimpan di perangkat dan dapat disinkronkan ke akunmu.'
                            : 'Profil dan catatan minuman tersimpan di perangkat ini.',
                        style: StevType.caption.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StevSpace.s4),
              Text('Kontrol data', style: StevType.heading),
              const SizedBox(height: StevSpace.s3),
              GlassCard(
                padding: const EdgeInsets.all(StevSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mulai dari awal', style: StevType.label),
                    const SizedBox(height: StevSpace.s1),
                    Text(
                      'Hapus seluruh data Stev.AI yang tersimpan di perangkat ini.',
                      style: StevType.caption.copyWith(color: StevColors.ink2),
                    ),
                    const SizedBox(height: StevSpace.s3),
                    StevButton(
                      key: const ValueKey('resetLocalDataButton'),
                      label: 'Reset data aplikasi',
                      variant: StevButtonVariant.card,
                      icon: const Icon(Icons.restart_alt_rounded),
                      onPressed: _resetLocalData,
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

  String _syncStatusLabel(CloudSyncController sync) => switch (sync.status) {
    CloudSyncStatus.unavailable => 'Sinkronisasi tidak tersedia',
    CloudSyncStatus.signedOut => 'Belum masuk akun',
    CloudSyncStatus.idle => 'Siap disinkronkan',
    CloudSyncStatus.syncing => 'Sedang menyinkronkan data...',
    CloudSyncStatus.synced =>
      sync.lastSyncedAt == null
          ? 'Data sudah sinkron'
          : 'Terakhir sinkron ${_timeLabel(sync.lastSyncedAt!)}',
    CloudSyncStatus.error => sync.errorMessage ?? 'Sinkronisasi gagal',
  };

  String _timeLabel(DateTime timestamp) {
    final local = timestamp.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _RiskHistoryCard extends StatelessWidget {
  const _RiskHistoryCard({required this.entry, required this.onDelete});

  final RiskHistoryEntry entry;
  final VoidCallback onDelete;

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
                IconButton(
                  key: ValueKey('deleteRiskHistory-${entry.id}'),
                  tooltip: 'Hapus hasil cek',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
