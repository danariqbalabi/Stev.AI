import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/placeholder_notice.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  int _selectedDrink = 0;
  int _selectedSugarLevel = 0;

  static const _drinks = ['Es kopi susu', 'Kopi susu gula aren', 'Caffe latte'];
  static const _sugarLevels = ['Normal', 'Less sugar', 'No sugar'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi minuman')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Minuman mana yang paling sesuai?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const PlaceholderNotice(
              message: 'Tiga tebakan berikut masih dummy dan belum berasal dari model AI.',
            ),
            const SizedBox(height: 16),
            RadioGroup<int>(
              groupValue: _selectedDrink,
              onChanged: (value) {
                setState(() => _selectedDrink = value ?? 0);
              },
              child: Column(
                children: [
                  for (var index = 0; index < _drinks.length; index++) ...[
                    Card(
                      color: _selectedDrink == index
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                      child: RadioListTile<int>(
                        value: index,
                        title: Text(_drinks[index]),
                        subtitle: Text('Tebakan ${index + 1} · data demo'),
                        secondary: const Icon(Icons.coffee_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Level gula',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _sugarLevels.length; index++)
                  ChoiceChip(
                    label: Text(_sugarLevels[index]),
                    selected: _selectedSugarLevel == index,
                    onSelected: (_) {
                      setState(() => _selectedSugarLevel = index);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              key: const ValueKey('showResultButton'),
              onPressed: () => context.push('/result'),
              child: const Text('Lihat kandungan gula'),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Bukan ini'),
            ),
          ],
        ),
      ),
    );
  }
}
