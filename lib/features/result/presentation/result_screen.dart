import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/placeholder_notice.dart';
import '../../swap/presentation/swap_sheet.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PlaceholderNotice(
              message: 'Hasil ini hanya contoh alur dan belum boleh dipakai sebagai informasi kesehatan.',
            ),
            const SizedBox(height: 20),
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Es kopi susu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '24 g',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                    const Text('estimasi gula · data demo'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Setara sekitar 6 sendok teh',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              children: [
                Icon(Icons.soup_kitchen_outlined),
                Icon(Icons.soup_kitchen_outlined),
                Icon(Icons.soup_kitchen_outlined),
                Icon(Icons.soup_kitchen_outlined),
                Icon(Icons.soup_kitchen_outlined),
                Icon(Icons.soup_kitchen_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              color: colorScheme.surfaceContainerLow,
              child: const ListTile(
                leading: Icon(Icons.donut_large_outlined),
                title: Text('Sisa jatah setelah minuman ini'),
                trailing: Text('12 g'),
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              key: const ValueKey('swapButton'),
              onPressed: () => showSwapSheet(context),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Swap drink'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Aku pilih ini'),
            ),
          ],
        ),
      ),
    );
  }
}
