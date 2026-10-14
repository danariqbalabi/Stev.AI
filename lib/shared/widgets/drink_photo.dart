import 'package:flutter/material.dart';

import '../../features/drinks/domain/drink.dart';
import '../../core/theme/stev_tokens.dart';

class DrinkPhoto extends StatelessWidget {
  const DrinkPhoto({super.key, required this.drink, this.fit, this.alignment});

  final Drink drink;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final imageUrl = drink.photoUrl?.trim();
    final effectiveFit = fit ?? drink.photoFit;
    final effectiveAlignment = alignment ?? drink.photoAlignment;
    final placeholder = Container(
      color: StevColors.canvas,
      alignment: Alignment.center,
      child: const Icon(Icons.local_drink_outlined, color: StevColors.ink2),
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: effectiveFit,
        alignment: effectiveAlignment,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }
    if (drink.photoAsset.isEmpty) return placeholder;

    return Image.asset(
      drink.photoAsset,
      fit: effectiveFit,
      alignment: effectiveAlignment,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
