import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/drink.dart';
import 'drink_catalog.dart';

abstract interface class DrinkCatalogRepository {
  Future<List<Drink>> fetchAll();
}

class LocalDrinkCatalogRepository implements DrinkCatalogRepository {
  const LocalDrinkCatalogRepository();

  @override
  Future<List<Drink>> fetchAll() async => DrinkCatalog.all;
}

class SupabaseDrinkCatalogRepository implements DrinkCatalogRepository {
  const SupabaseDrinkCatalogRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<Drink>> fetchAll() async {
    final response = await client
        .from('drinks')
        .select(
          'id,name,category,kind,sugar_grams,estimated,photo_asset,'
          'image_url,data_type,validation_status,source_url,'
          'sugar_options(level,sugar_grams)',
        )
        .eq('verified', true)
        .order('name');

    final drinks = response
        .whereType<Map>()
        .map(
          (row) => SupabaseDrinkCatalogMapper.fromRow(
            Map<String, Object?>.from(row),
          ),
        )
        .whereType<Drink>()
        .toList(growable: false);
    if (drinks.isEmpty) {
      throw const FormatException('Remote drink catalog is empty or invalid.');
    }
    return drinks;
  }
}

class FallbackDrinkCatalogRepository implements DrinkCatalogRepository {
  const FallbackDrinkCatalogRepository({
    required this.remote,
    this.fallback = const LocalDrinkCatalogRepository(),
  });

  final DrinkCatalogRepository remote;
  final DrinkCatalogRepository fallback;

  @override
  Future<List<Drink>> fetchAll() async {
    try {
      return await remote.fetchAll();
    } catch (_) {
      return fallback.fetchAll();
    }
  }
}

abstract final class SupabaseDrinkCatalogMapper {
  static Drink? fromRow(Map<String, Object?> row) {
    final id = row['id'];
    final name = row['name'];
    final grams = row['sugar_grams'];
    final estimated = row['estimated'];
    final category = _enumByName(DrinkCategory.values, row['category']);
    final kind = _enumByName(DrinkKind.values, row['kind']);
    if (id is! String ||
        name is! String ||
        grams is! num ||
        estimated is! bool ||
        category == null ||
        kind == null) {
      return null;
    }

    final levelsByName = <String, double>{};
    if (row['sugar_options'] case final List options) {
      for (final value in options) {
        if (value is! Map) continue;
        final option = Map<String, Object?>.from(value);
        if (option['level'] case final String level) {
          if (option['sugar_grams'] case final num optionGrams) {
            levelsByName[level] = optionGrams.toDouble();
          }
        }
      }
    }

    final normal = levelsByName['normal'];
    final less = levelsByName['less'];
    final noSugar = levelsByName['no_sugar'] ?? levelsByName['noSugar'];
    final imageUrl = row['image_url'];
    final photoAsset = row['photo_asset'];
    final dataType =
        _enumByName(DrinkDataType.values, row['data_type']) ??
        DrinkDataType.estimated;
    final validationStatus =
        _enumByName(DrinkValidationStatus.values, row['validation_status']) ??
        DrinkValidationStatus.demo;
    final sourceUrl = row['source_url'];
    return Drink(
      id: id,
      name: name,
      grams: grams.toDouble(),
      estimated: estimated,
      category: category,
      kind: kind,
      photoAsset: photoAsset is String ? photoAsset : '',
      photoUrl: imageUrl is String && imageUrl.trim().isNotEmpty
          ? imageUrl
          : null,
      dataType: dataType,
      validationStatus: validationStatus,
      sourceUrl: sourceUrl is String && sourceUrl.trim().isNotEmpty
          ? sourceUrl
          : null,
      levels: normal != null && less != null && noSugar != null
          ? SugarLevels(normal: normal, less: less, noSugar: noSugar)
          : null,
    );
  }

  static T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
