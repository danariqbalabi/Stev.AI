import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../onboarding/data/onboarding_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  OnboardingProfile _profile = const OnboardingProfile();

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    final profile = await OnboardingPreferences.readProfile();
    if (mounted) setState(() => _profile = profile);
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
