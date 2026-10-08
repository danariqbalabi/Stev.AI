import 'package:flutter/material.dart';

Future<void> showSwapSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SafeArea(child: SwapSheet()),
  );
}

class SwapSheet extends StatelessWidget {
  const SwapSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Swap ke yang lebih ringan',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text('Pilihan berikut masih menggunakan data demo.'),
          const SizedBox(height: 16),
          const _SwapOption(
            name: 'Es kopi susu · less sugar',
            saving: 'Hemat 8 g',
          ),
          const _SwapOption(
            name: 'Es kopi susu · ukuran kecil',
            saving: 'Hemat 10 g',
          ),
          const _SwapOption(name: 'Americano tanpa gula', saving: 'Hemat 24 g'),
        ],
      ),
    );
  }
}

class _SwapOption extends StatelessWidget {
  const _SwapOption({required this.name, required this.saving});

  final String name;
  final String saving;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        onTap: () => Navigator.of(context).pop(),
        leading: const CircleAvatar(child: Icon(Icons.local_drink_outlined)),
        title: Text(name),
        subtitle: Text(saving),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
