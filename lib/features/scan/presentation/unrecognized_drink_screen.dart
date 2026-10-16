import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/stev_tokens.dart';
import '../../../shared/widgets/stev_design_system.dart';
import '../../drinks/application/drink_catalog_controller.dart';
import '../../drinks/domain/drink.dart';

class UnrecognizedDrinkScreen extends StatelessWidget {
  const UnrecognizedDrinkScreen({super.key, this.photoBytes});
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    final drinks = DrinkCatalogScope.of(context).drinks;
    final groups = <String, bool Function(Drink)>{
      'Es teh': (d) => d.name.toLowerCase().contains('es teh'),
      'Kopi susu': (d) =>
          d.kind == DrinkKind.coffee && d.name.toLowerCase().contains('susu'),
      'Teh susu': (d) =>
          d.kind == DrinkKind.tea &&
          (d.name.toLowerCase().contains('teh susu') ||
              d.name.toLowerCase().contains('milk tea')),
      'Minuman boba': (d) => d.kind == DrinkKind.boba,
      'Jus buah': (d) => d.kind == DrinkKind.juice,
      'Cokelat': (d) => d.name.toLowerCase().contains('cokelat'),
    };
    final options = <String, Drink>{};
    for (final group in groups.entries) {
      final drink = drinks
          .where((d) => d.category != DrinkCategory.packaged && group.value(d))
          .firstOrNull;
      if (drink != null) options[group.key] = drink;
    }
    return Scaffold(
      key: const ValueKey('unrecognizedDrinkScreen'),
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pushReplacement('/scan')),
      ),
      body: AuraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(StevSpace.s5),
            children: [
              Row(
                children: [
                  if (photoBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(StevRadius.small),
                      child: Image.memory(
                        photoBytes!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: StevSpace.s4),
                  Expanded(
                    child: Text(
                      'Belum kenal minuman ini',
                      style: StevType.title,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StevSpace.s7),
              if (options.isNotEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(StevSpace.s5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minuman gelas? Pilih jenisnya',
                        style: StevType.label,
                      ),
                      const SizedBox(height: StevSpace.s4),
                      Wrap(
                        spacing: StevSpace.s2,
                        runSpacing: StevSpace.s2,
                        children: [
                          for (final option in options.entries)
                            ActionChip(
                              label: Text(option.key),
                              onPressed: () =>
                                  context.push('/result', extra: option.value),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: StevSpace.s7),
              Text(
                'Minuman kemasan? Scan barcode-nya',
                style: StevType.heading,
              ),
              const SizedBox(height: StevSpace.s5),
              StevButton(
                key: const ValueKey('unrecognizedScanBarcode'),
                label: 'Scan barcode',
                onPressed: () => context.pushReplacement('/scan/barcode'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: StevColors.ink2,
                  textStyle: StevType.caption,
                ),
                onPressed: () => context.push('/manual'),
                child: const Text('Cari manual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
