import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/drink.dart';

class DrinkLogPreferences {
  static const _keyPrefix = 'stev-drink-log-v1';
  static const lastActiveDateKey = 'stev-drink-log-last-active-date';

  Future<List<DrinkSelection>?> read(DateTime date) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_keyFor(date));
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return null;

      final entries = <DrinkSelection>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        final selection = _selectionFromJson(Map<String, Object?>.from(value));
        if (selection != null) entries.add(selection);
      }
      return entries;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(DateTime date, Iterable<DrinkSelection> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final normalizedDate = _formatDate(date);
    final encoded = jsonEncode(entries.map(_selectionToJson).toList());
    await preferences.setString(_keyFor(date), encoded);
    await preferences.setString(lastActiveDateKey, normalizedDate);
  }

  Future<String?> readLastActiveDate() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(lastActiveDateKey);
  }

  static String dateKey(DateTime date) => _keyFor(date);

  static String dateLabel(DateTime date) => _formatDate(date);

  static String _keyFor(DateTime date) => '$_keyPrefix-${_formatDate(date)}';

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Map<String, Object?> _selectionToJson(DrinkSelection selection) {
    final drink = selection.drink;
    return {
      'drink': {
        'id': drink.id,
        'name': drink.name,
        'grams': drink.grams,
        'estimated': drink.estimated,
        'category': drink.category.name,
        'kind': drink.kind.name,
        'photoAsset': drink.photoAsset,
        'photoFit': drink.photoFit == BoxFit.contain ? 'contain' : 'cover',
        'photoAlignmentX': drink.photoAlignment.x,
        'photoAlignmentY': drink.photoAlignment.y,
        if (drink.logIdentityId != null) 'logIdentityId': drink.logIdentityId,
        if (drink.levels case final levels?)
          'levels': {
            'normal': levels.normal,
            'less': levels.less,
            'noSugar': levels.noSugar,
          },
      },
      if (selection.sugarLevel case final sugarLevel?)
        'sugarLevel': sugarLevel.name,
    };
  }

  static DrinkSelection? _selectionFromJson(Map<String, Object?> json) {
    final drinkValue = json['drink'];
    if (drinkValue is! Map) return null;
    final drinkJson = Map<String, Object?>.from(drinkValue);

    final id = drinkJson['id'];
    final name = drinkJson['name'];
    final grams = drinkJson['grams'];
    final estimated = drinkJson['estimated'];
    final photoAsset = drinkJson['photoAsset'];
    final category = _enumByName(DrinkCategory.values, drinkJson['category']);
    final kind = _enumByName(DrinkKind.values, drinkJson['kind']);
    if (id is! String ||
        name is! String ||
        grams is! num ||
        estimated is! bool ||
        photoAsset is! String ||
        category == null ||
        kind == null) {
      return null;
    }

    SugarLevels? levels;
    if (drinkJson['levels'] case final Map levelsValue) {
      final levelsJson = Map<String, Object?>.from(levelsValue);
      final normal = levelsJson['normal'];
      final less = levelsJson['less'];
      final noSugar = levelsJson['noSugar'];
      if (normal is num && less is num && noSugar is num) {
        levels = SugarLevels(
          normal: normal.toDouble(),
          less: less.toDouble(),
          noSugar: noSugar.toDouble(),
        );
      }
    }

    final alignmentX = drinkJson['photoAlignmentX'];
    final alignmentY = drinkJson['photoAlignmentY'];
    final sugarLevel = _enumByName(SugarLevel.values, json['sugarLevel']);
    final logIdentityId = drinkJson['logIdentityId'];
    final drink = Drink(
      id: id,
      name: name,
      grams: grams.toDouble(),
      estimated: estimated,
      category: category,
      kind: kind,
      photoAsset: photoAsset,
      levels: levels,
      logIdentityId: logIdentityId is String ? logIdentityId : null,
      photoFit: drinkJson['photoFit'] == 'contain'
          ? BoxFit.contain
          : BoxFit.cover,
      photoAlignment: Alignment(
        alignmentX is num ? alignmentX.toDouble() : 0,
        alignmentY is num ? alignmentY.toDouble() : 0,
      ),
    );
    return DrinkSelection(drink: drink, sugarLevel: sugarLevel);
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
