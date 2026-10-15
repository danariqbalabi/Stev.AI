import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';

class ScanModesScreen extends StatelessWidget {
  const ScanModesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('scanModesScreen'),
      appBar: AppBar(title: const Text('Scan minuman')),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(StevSpace.s5),
            children: [
              Text('Mau scan lewat apa?', style: StevType.onboardingTitle),
              const SizedBox(height: StevSpace.s2),
              Text(
                'Pilih cara untuk mencari kandungan gula minumanmu.',
                style: StevType.body.copyWith(color: StevColors.ink2),
              ),
              const SizedBox(height: StevSpace.s6),
              _ScanModeCard(
                key: const ValueKey('scanMode-photo'),
                icon: Icons.camera_alt_outlined,
                title: 'Foto Minuman',
                description: 'Foto kemasan atau minuman racikan seperti es teh, kopi, dan boba.',
                onTap: () => context.push('/scan/photo'),
              ),
              const SizedBox(height: StevSpace.s4),
              _ScanModeCard(
                key: const ValueKey('scanMode-barcode'),
                icon: Icons.barcode_reader,
                title: 'Barcode',
                description: 'Cari produk kemasan lewat barcode yang tercetak di kemasan.',
                onTap: () => context.push('/scan/barcode'),
              ),
              const SizedBox(height: StevSpace.s4),
              _ScanModeCard(
                key: const ValueKey('scanMode-label'),
                icon: Icons.document_scanner_outlined,
                title: 'Label Gizi',
                description: 'Baca gula dan takaran saji dari tabel Informasi Nilai Gizi.',
                onTap: () => context.push('/scan/label'),
              ),
              const SizedBox(height: StevSpace.s6),
              Text(
                'Sudah tahu nama minumannya?',
                textAlign: TextAlign.center,
                style: StevType.caption.copyWith(color: StevColors.ink2),
              ),
              TextButton.icon(
                key: const ValueKey('scanModesManualSearch'),
                onPressed: () => context.push('/manual'),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Cari manual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanModeCard extends StatelessWidget {
  const _ScanModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    final radius = BorderRadius.circular(StevRadius.card);

    return Semantics(
      button: true,
      enabled: available,
      child: Material(
        color: available ? StevColors.card : StevColors.glassCard,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(StevSpace.s5),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: available ? StevColors.leaf : StevColors.glassEdge,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(StevSpace.s3),
                  decoration: BoxDecoration(
                    color: available
                        ? StevColors.leaf.withValues(alpha: 0.15)
                        : StevColors.canvas,
                    borderRadius: BorderRadius.circular(StevRadius.small),
                  ),
                  child: Icon(
                    icon,
                    color: available ? StevColors.ink : StevColors.ink2,
                  ),
                ),
                const SizedBox(width: StevSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: StevType.label),
                      if (!available) ...[
                        const SizedBox(height: StevSpace.s1),
                        Text(
                          'Segera hadir',
                          style: StevType.micro.copyWith(
                            color: StevColors.ink2,
                          ),
                        ),
                      ],
                      const SizedBox(height: StevSpace.s2),
                      Text(
                        description,
                        style: StevType.caption.copyWith(
                          color: StevColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (available) ...[
                  const SizedBox(width: StevSpace.s2),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
