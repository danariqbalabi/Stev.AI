import 'package:flutter/material.dart';

import '../../../../core/theme/stev_tokens.dart';
import '../../../../shared/widgets/stev_design_system.dart';

class DailySugarCard extends StatelessWidget {
  const DailySugarCard({super.key, required this.totalGrams});

  final double totalGrams;

  @override
  Widget build(BuildContext context) {
    final totalLabel = totalGrams % 1 == 0
        ? totalGrams.toStringAsFixed(0)
        : totalGrams.toStringAsFixed(1);
    final spoons = homeSpoons(totalGrams);
    final isOver = totalGrams > StevSugar.dailyLimit;

    return Semantics(
      label: '$totalLabel gram gula hari ini dari batas harian 50 gram',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 290,
          child: GlassCard(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(totalLabel, style: StevType.number),
                        const SizedBox(width: 3),
                        Text(
                          '/50 g',
                          style: StevType.unitHome.copyWith(
                            color: StevColors.ink2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gula hari ini',
                      style: StevType.caption.copyWith(color: StevColors.ink2),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final spoon in spoons)
                          Spoon(
                            grams: spoon.grams,
                            over: spoon.over,
                            width: StevSize.spoonHome,
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedStevMascot(
                    mood: isOver ? StevMood.worried : StevMood.happy,
                    size: StevSize.stevHome,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
