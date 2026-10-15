import 'package:flutter/painting.dart';

enum DrinkCategory { packaged, coffee, tea, boba, juice, custom }

enum DrinkKind { tea, coffee, boba, juice, milk, soda, isotonic, custom }

enum DrinkDataType { label, official, estimated, community, custom }

enum DrinkValidationStatus { demo, verified, unverified }

enum SugarLevel {
  normal('Normal', 3),
  less('Less sugar', 2),
  noSugar('No sugar', 0);

  const SugarLevel(this.label, this.iconLevel);

  final String label;
  final int iconLevel;
}

class SugarLevels {
  const SugarLevels({
    required this.normal,
    required this.less,
    required this.noSugar,
  });

  final double normal;
  final double less;
  final double noSugar;

  double gramsFor(SugarLevel level) => switch (level) {
    SugarLevel.normal => normal,
    SugarLevel.less => less,
    SugarLevel.noSugar => noSugar,
  };
}

class Drink {
  const Drink({
    required this.id,
    required this.name,
    required this.grams,
    required this.estimated,
    required this.category,
    required this.kind,
    this.photoAsset = '',
    this.photoUrl,
    this.levels,
    this.logIdentityId,
    this.photoFit = BoxFit.cover,
    this.photoAlignment = Alignment.center,
    this.dataType = DrinkDataType.estimated,
    this.validationStatus = DrinkValidationStatus.demo,
    this.sourceUrl,
  });

  final String id;
  final String name;
  final double grams;
  final bool estimated;
  final DrinkCategory category;
  final DrinkKind kind;
  final String photoAsset;
  final String? photoUrl;
  final SugarLevels? levels;
  final String? logIdentityId;
  final BoxFit photoFit;
  final Alignment photoAlignment;
  final DrinkDataType dataType;
  final DrinkValidationStatus validationStatus;
  final String? sourceUrl;

  String get identityId => logIdentityId ?? id;

  double gramsFor(SugarLevel? level) {
    if (level == null || levels == null) return grams;
    return levels!.gramsFor(level);
  }
}

class DrinkSelection {
  const DrinkSelection({required this.drink, this.sugarLevel});

  final Drink drink;
  final SugarLevel? sugarLevel;

  double get grams => drink.gramsFor(sugarLevel);
  String get identityId => drink.identityId;

  String get displayGrams => formatSugarGrams(grams, drink.estimated);
}

String formatSugarGrams(double grams, bool estimated) {
  final value = grams % 1 == 0
      ? grams.toStringAsFixed(0)
      : grams.toStringAsFixed(1);
  return '${estimated ? '≈' : ''}$value g';
}
