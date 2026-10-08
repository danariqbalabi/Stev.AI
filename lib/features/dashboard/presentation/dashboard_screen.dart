import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/placeholder_notice.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stev.AI'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Profil (segera hadir)',
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Hai! Cek gula sebelum tegukan berikutnya.',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jatah gula hari ini',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '12 g lagi',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(value: 0.76),
                    const SizedBox(height: 8),
                    const Text('38 g dari referensi harian 50 g'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const PlaceholderNotice(
              message: 'Angka dan daftar minuman pada app shell ini masih berupa data demo.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('scanButton'),
              onPressed: () => context.push('/scan'),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan minuman'),
            ),
            const SizedBox(height: 28),
            Text(
              'Minuman hari ini',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const _DrinkLogTile(
              name: 'Es kopi susu',
              detail: 'Normal sugar · data demo',
              sugar: '24 g',
              icon: Icons.coffee_outlined,
            ),
            const SizedBox(height: 10),
            const _DrinkLogTile(
              name: 'Teh kemasan',
              detail: 'Sesuai label · data demo',
              sugar: '14 g',
              icon: Icons.local_drink_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrinkLogTile extends StatelessWidget {
  const _DrinkLogTile({
    required this.name,
    required this.detail,
    required this.sugar,
    required this.icon,
  });

  final String name;
  final String detail;
  final String sugar;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(name),
        subtitle: Text(detail),
        trailing: Text(
          sugar,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
