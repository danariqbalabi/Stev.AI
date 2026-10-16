import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/features/barcode/data/barcode_lookup_service.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';
import 'package:steviai/features/drinks/domain/drink.dart';

const code = '5449000000996';

Map<String, Object?> product({Object? sugar = 10, Object? quantity = 330}) => {
  'status': 1,
  'product': {
    'code': code,
    'product_name': 'Minuman uji',
    'nutrition_data_per': '100ml',
    'categories_tags': ['en:beverages'],
    'nutriments': {'sugars_100g': sugar, 'carbohydrates_100g': 20},
    'product_quantity': quantity,
    'product_quantity_unit': 'ml',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'cache survives another service and stays explicitly unverified',
    () async {
      var requests = 0;
      final clock = DateTime.utc(2026, 10, 16);
      final client = MockClient((_) async {
        requests++;
        return http.Response(jsonEncode(product()), 200);
      });
      final first = BarcodeLookupService(
        supabaseUrl: '',
        client: client,
        now: () => clock,
      );
      expect((await first.lookup(code)).cachedAt, isNull);
      final offline = BarcodeLookupService(
        supabaseUrl: '',
        now: () => clock.add(const Duration(days: 1)),
        client: MockClient((_) async => throw StateError('Must use cache')),
      );
      final cached = await offline.lookup(code);
      expect(cached.cachedAt, clock);
      expect(cached.selectionFor(cached.defaultPortions).grams, 33);
      expect(
        cached.selectionFor(1).drink.validationStatus,
        DrinkValidationStatus.unverified,
      );
      expect(requests, 1);
    },
  );

  test(
    'expired cache refreshes and concurrent same-code requests coalesce',
    () async {
      var clock = DateTime.utc(2026, 10, 16);
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(
          jsonEncode(product(sugar: requests == 1 ? 10 : 5)),
          200,
        );
      });
      final service = BarcodeLookupService(
        supabaseUrl: '',
        client: client,
        now: () => clock,
      );
      await Future.wait([service.lookup(code), service.lookup(code)]);
      expect(requests, 1);
      clock = clock.add(const Duration(days: 7));
      expect((await service.lookup(code)).sugarGramsPerPortion, 5);
      expect(requests, 2);
    },
  );

  test('429 cooldown persists and retry succeeds after Retry-After', () async {
    var clock = DateTime.utc(2026, 10, 16);
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return requests == 1
          ? http.Response('{}', 429, headers: {'retry-after': '120'})
          : http.Response(jsonEncode(product()), 200);
    });
    BarcodeLookupService service() =>
        BarcodeLookupService(supabaseUrl: '', client: client, now: () => clock);
    final limited = throwsA(
      isA<BarcodeLookupException>().having(
        (e) => e.retryAt,
        'retryAt',
        clock.add(const Duration(seconds: 120)),
      ),
    );
    await expectLater(service().lookup(code), limited);
    await expectLater(service().lookup(code), limited);
    expect(requests, 1);
    clock = clock.add(const Duration(seconds: 120));
    expect((await service().lookup(code)).name, 'Minuman uji');
    expect(requests, 2);
  });

  test(
    'uncached repeated requests are paced even after a missing product',
    () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('{}', 404);
      });
      final clock = DateTime.utc(2026, 10, 16);
      final service = BarcodeLookupService(
        supabaseUrl: '',
        client: client,
        now: () => clock,
      );
      await expectLater(
        service.lookup(code),
        throwsA(isA<BarcodeLookupException>()),
      );
      await expectLater(
        service.lookup('96385074'),
        throwsA(
          isA<BarcodeLookupException>().having(
            (e) => e.retryAt,
            'pacing',
            isNotNull,
          ),
        ),
      );
      expect(requests, 1);
    },
  );
  test('validates GTIN checksum and preserves leading zeros', () {
    expect(validRetailBarcode(code), code);
    expect(validRetailBarcode('96385074'), '96385074');
    expect(validRetailBarcode(' 012345678905 '), '012345678905');
    expect(validRetailBarcode('5449000000997'), isNull);
    expect(validRetailBarcode('https://example.com'), isNull);
    expect(validRetailBarcode('1234'), isNull);
  });

  test('external drink calculates a whole bottle and fractional portions', () {
    final result = BarcodeLookupService.parseOpenFoodFacts(code, product());
    expect(result.portionLabel, '100 ml');
    expect(result.defaultPortions, 3.3);
    expect(result.selectionFor(result.defaultPortions).grams, 33);
    expect(result.selectionFor(1.5).grams, 15);
    expect(result.selectionFor(1).drink.sourceUrl, contains(code));
    expect(result.source, contains('belum diverifikasi'));
    expect(result.portionMl, 100);
    expect(result.packageMl, 330);
    expect(result.fromCache(DateTime.utc(2026)).portionMl, 100);
    expect(
      result.selectionFor(1).drink.validationStatus,
      DrinkValidationStatus.unverified,
    );
  });

  test(
    'Pocari barcode volume can be corrected without changing cached product',
    () {
      final payload = product(sugar: 5.6, quantity: 350);
      final result = BarcodeLookupService.parseOpenFoodFacts(code, payload);
      expect(result.selectionForVolume(250, 1).grams, closeTo(14, 0.000001));
      expect(result.selectionForVolume(250, 0.5).grams, closeTo(7, 0.000001));
      expect(
        result.selectionForVolume(250, 1).drink.validationStatus,
        DrinkValidationStatus.unverified,
      );
      expect(result.selectionForVolume(250, 1).drink.estimated, isTrue);
      expect(
        result.selectionForVolume(250, 1).drink.name,
        contains('ukuran dikoreksi'),
      );
      expect(result.packageMl, 350);
      for (final ml in [0.0, -1.0, double.nan, double.infinity, 10001.0]) {
        expect(() => result.selectionForVolume(ml, 1), throwsFormatException);
      }
      expect(() => result.selectionForVolume(250, 2), throwsFormatException);
    },
  );

  test('zero sugar is a valid result, missing sugar is not zero', () {
    expect(
      BarcodeLookupService.parseOpenFoodFacts(
        code,
        product(sugar: 0),
      ).sugarGramsPerPortion,
      0,
    );
    for (final value in [null, -1, 'NaN', 'Infinity', 101]) {
      expect(
        () => BarcodeLookupService.parseOpenFoodFacts(
          code,
          product(sugar: value),
        ),
        throwsA(isA<BarcodeLookupException>()),
      );
    }
  });

  test('rejects foods, unknown quantity, and weight-only packages', () {
    final food = product();
    (food['product']! as Map)['categories_tags'] = ['en:candies'];
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(code, food),
      throwsA(isA<BarcodeLookupException>()),
    );
    final weight = product();
    (weight['product']! as Map)['product_quantity_unit'] = 'g';
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(code, weight),
      throwsA(isA<BarcodeLookupException>()),
    );
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(
        code,
        product(quantity: null),
      ),
      throwsA(isA<BarcodeLookupException>()),
    );
  });

  test('rejects a different product and drinks requiring dilution', () {
    final mismatch = product();
    (mismatch['product']! as Map)['code'] = '96385074';
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(code, mismatch),
      throwsA(isA<BarcodeLookupException>()),
    );
    final syrup = product();
    (syrup['product']! as Map)['categories_tags'] = [
      'en:beverages',
      'en:syrups',
    ];
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(code, syrup),
      throwsA(isA<BarcodeLookupException>()),
    );
  });

  test('explicit litre quantity works without guessing multipacks', () {
    final litre = product(quantity: null);
    (litre['product']! as Map)['quantity'] = '1,5 L';
    expect(
      BarcodeLookupService.parseOpenFoodFacts(code, litre).defaultPortions,
      15,
    );
    (litre['product']! as Map)['quantity'] = '6 x 330 ml';
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(code, litre),
      throwsA(isA<BarcodeLookupException>()),
    );
  });

  test('Supabase match wins and only read requests are sent', () async {
    final requests = <http.Request>[];
    final service = BarcodeLookupService(
      supabaseUrl: 'https://example.supabase.co',
      publishableKey: 'public-key',
      client: MockClient((request) async {
        requests.add(request);
        expect(request.method, 'GET');
        expect(request.url.queryParameters['verified'], 'eq.true');
        expect(request.url.queryParameters['barcode'], 'eq.$code');
        return http.Response(
          jsonEncode([
            {
              'id': 'drink',
              'name': 'Test tea',
              'category': 'packaged',
              'kind': 'tea',
              'sugar_grams': 18,
              'estimated': false,
              'serving_ml': 250,
              'validation_status': 'verified',
              'data_type': 'label',
            },
          ]),
          200,
        );
      }),
    );
    final result = await service.lookup(code);
    expect(result.sugarGramsPerPortion, 18);
    expect(result.portionLabel, contains('250 ml'));
    expect(result.source, 'Katalog Stev.AI');
    final corrected = result.selectionForVolume(350, 1).drink;
    expect(corrected.validationStatus, DrinkValidationStatus.unverified);
    expect(corrected.dataType, DrinkDataType.custom);
    expect(corrected.estimated, isTrue);
    expect(
      result.selectionForVolume(250, 1).drink.validationStatus,
      DrinkValidationStatus.verified,
    );
    await service.lookup(code);
    expect(requests, hasLength(1));
  });

  for (final catalogStatus in [200, 503]) {
    test('falls back after catalog status $catalogStatus', () async {
      final hosts = <String>[];
      final service = BarcodeLookupService(
        supabaseUrl: 'https://example.supabase.co',
        publishableKey: 'public-key',
        client: MockClient((request) async {
          hosts.add(request.url.host);
          return request.url.host == 'example.supabase.co'
              ? http.Response('[]', catalogStatus)
              : http.Response(jsonEncode(product()), 200);
        }),
      );
      expect((await service.lookup(code)).name, 'Minuman uji');
      expect(hosts, ['example.supabase.co', 'world.openfoodfacts.org']);
    });
  }

  test('invalid input never calls the API', () async {
    final service = BarcodeLookupService(
      client: MockClient((_) async => throw StateError('Unexpected request')),
    );
    await expectLater(
      service.lookup('123'),
      throwsA(isA<BarcodeLookupException>()),
    );
  });

  test(
    'not found, provider errors and timeouts produce actionable errors',
    () async {
      for (final status in [404, 429, 500]) {
        SharedPreferences.setMockInitialValues({});
        final service = BarcodeLookupService(
          supabaseUrl: '',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(
          service.lookup(code),
          throwsA(isA<BarcodeLookupException>()),
        );
      }
      SharedPreferences.setMockInitialValues({});
      final service = BarcodeLookupService(
        supabaseUrl: '',
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(
        service.lookup(code),
        throwsA(isA<BarcodeLookupException>()),
      );
    },
  );
}
