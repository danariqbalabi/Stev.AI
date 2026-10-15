import 'package:flutter_test/flutter_test.dart';
import 'package:steviai/core/config/stev_backend_config.dart';
import 'package:steviai/features/drinks/application/drink_catalog_controller.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/drinks/data/drink_catalog_repository.dart';
import 'package:steviai/features/drinks/domain/drink.dart';

void main() {
  group('StevBackendConfig', () {
    test('requires an HTTPS URL and publishable key', () {
      expect(
        StevBackendConfig.isValid(
          url: 'https://project.supabase.co',
          publishableKey: 'publishable-key',
        ),
        isTrue,
      );
      expect(
        StevBackendConfig.isValid(
          url: 'http://project.supabase.co',
          publishableKey: 'publishable-key',
        ),
        isFalse,
      );
      expect(
        StevBackendConfig.isValid(
          url: 'https://project.supabase.co',
          publishableKey: '',
        ),
        isFalse,
      );
    });
  });

  group('SupabaseDrinkCatalogMapper', () {
    test('maps a verified database row and its sugar options', () {
      final drink = SupabaseDrinkCatalogMapper.fromRow({
        'id': 'remote-matcha',
        'name': 'Remote Matcha',
        'sugar_grams': 20,
        'estimated': true,
        'category': 'tea',
        'kind': 'tea',
        'photo_asset': null,
        'image_url': 'https://cdn.example.com/matcha.png',
        'data_type': 'label',
        'validation_status': 'verified',
        'source_url': 'https://example.com/matcha-label',
        'sugar_options': [
          {'level': 'normal', 'sugar_grams': 20},
          {'level': 'less', 'sugar_grams': 12},
          {'level': 'no_sugar', 'sugar_grams': 4},
        ],
      });

      expect(drink, isNotNull);
      expect(drink!.id, 'remote-matcha');
      expect(drink.photoAsset, isEmpty);
      expect(drink.photoUrl, 'https://cdn.example.com/matcha.png');
      expect(drink.dataType, DrinkDataType.label);
      expect(drink.validationStatus, DrinkValidationStatus.verified);
      expect(drink.sourceUrl, 'https://example.com/matcha-label');
      expect(drink.levels!.gramsFor(SugarLevel.less), 12);
    });

    test('rejects a row with unsupported enums or missing sugar data', () {
      expect(
        SupabaseDrinkCatalogMapper.fromRow({
          'id': 'invalid',
          'name': 'Invalid',
          'sugar_grams': null,
          'estimated': true,
          'category': 'unknown',
          'kind': 'tea',
        }),
        isNull,
      );
    });
  });

  test('fallback repository uses local catalog when remote fails', () async {
    const repository = FallbackDrinkCatalogRepository(
      remote: _ThrowingCatalogRepository(),
    );

    final drinks = await repository.fetchAll();

    expect(drinks, DrinkCatalog.all);
  });

  test('catalog controller replaces local data after refresh', () async {
    const remoteDrink = Drink(
      id: 'remote-drink',
      name: 'Remote drink',
      grams: 7,
      estimated: false,
      category: DrinkCategory.packaged,
      kind: DrinkKind.tea,
    );
    final controller = DrinkCatalogController(
      repository: const _StaticCatalogRepository([remoteDrink]),
    );
    addTearDown(controller.dispose);

    expect(controller.drinks, DrinkCatalog.all);
    await controller.refresh();

    expect(controller.drinks, [remoteDrink]);
    expect(controller.findById('remote-drink'), remoteDrink);
    expect(controller.isRefreshing, isFalse);
    expect(controller.errorMessage, isNull);
  });
}

class _ThrowingCatalogRepository implements DrinkCatalogRepository {
  const _ThrowingCatalogRepository();

  @override
  Future<List<Drink>> fetchAll() => throw Exception('offline');
}

class _StaticCatalogRepository implements DrinkCatalogRepository {
  const _StaticCatalogRepository(this.drinks);

  final List<Drink> drinks;

  @override
  Future<List<Drink>> fetchAll() async => drinks;
}
