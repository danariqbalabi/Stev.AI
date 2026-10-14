import 'package:flutter/material.dart';

import '../../../../core/theme/stev_tokens.dart';
import '../../../../shared/widgets/stev_design_system.dart';
import '../../../../shared/widgets/drink_photo.dart';
import '../../../drinks/domain/drink.dart';

class DrinkRow extends StatelessWidget {
  const DrinkRow({super.key, required this.drink});

  final DrinkSelection drink;

  @override
  Widget build(BuildContext context) {
    final estimateLabel = drink.drink.estimated ? 'estimasi' : 'sesuai label';

    return Semantics(
      label: '${drink.drink.name}, ${drink.displayGrams}, $estimateLabel',
      child: ExcludeSemantics(
        child: SizedBox(
          height: StevSize.drinkRow,
          child: GlassCard(
            radius: StevRadius.row,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                SizedBox.square(
                  dimension: StevSize.drinkRow,
                  child: ColoredBox(
                    color: StevColors.card,
                    child: DrinkPhoto(drink: drink.drink),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: StevSpace.s4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drink.drink.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: StevType.label,
                        ),
                        if (drink.sugarLevel case final level?) ...[
                          const SizedBox(height: 3),
                          LevelIcon(level: level.iconLevel),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: StevSpace.s2, right: 18),
                  child: Text(drink.displayGrams, style: StevType.listGrams),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
