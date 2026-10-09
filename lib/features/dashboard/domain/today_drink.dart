import 'package:flutter/widgets.dart';

class TodayDrink {
  const TodayDrink({
    required this.id,
    required this.name,
    required this.grams,
    required this.estimated,
    required this.photoAsset,
    this.sugarLevel,
    this.photoFit = BoxFit.cover,
  });

  final String id;
  final String name;
  final double grams;
  final bool estimated;
  final String photoAsset;
  final int? sugarLevel;
  final BoxFit photoFit;

  String get displayGrams {
    final value = grams % 1 == 0
        ? grams.toStringAsFixed(0)
        : grams.toStringAsFixed(1);
    return '${estimated ? '≈' : ''}$value g';
  }
}
