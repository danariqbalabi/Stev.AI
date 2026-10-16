import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:steviai/features/barcode/data/barcode_lookup_service.dart';
import 'package:steviai/features/barcode/domain/barcode_product.dart';

// Selected API fields captured on 2026-10-16. Historical source data, not a
// verified nutrition catalog. Keep live requests out of CI.
final fixtures = (jsonDecode(
  File('test/fixtures/off_barcode_products.json').readAsStringSync(),
) as List).cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const totals = {
    '8991749000012': 14.0,
    '8992858527308': 7.0,
    '8997009781110': 35.0,
    '8998009010552': 8.0,
  };
  for (final fixture in fixtures) {
    final code = fixture['product']['code'] as String;
    test(
      'OFF regression $code: accepted data or precise incomplete-data error',
      () async {
        final service = BarcodeLookupService(
          supabaseUrl: '',
          client: MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.path, '/api/v2/product/$code.json');
            expect(
              request.url.queryParameters['fields'],
              contains('serving_quantity_unit'),
            );
            return http.Response(jsonEncode(fixture), 200);
          }),
        );
        if (!totals.containsKey(code)) {
          await expectLater(
            service.lookup(code),
            throwsA(
              isA<BarcodeLookupException>()
                  .having(
                    (error) => error.failure,
                    'reason',
                    BarcodeFailure.incompleteNutrition,
                  )
                  .having(
                    (error) => error.productName,
                    'known product',
                    isNotEmpty,
                  ),
            ),
          );
          return;
        }
        final result = await service.lookup(code);
        expect(
          result.selectionForVolume(result.packageMl!, 1).grams,
          closeTo(totals[code]!, 0.000001),
        );
        if (code == '8991749000012') {
          expect(result.packageMl, 220);
          expect(result.requiresDrinkConfirmation, isTrue);
          expect(result.sizeNote, isNotNull);
          final cached = await service.lookup(code);
          expect(cached.requiresDrinkConfirmation, isTrue);
          expect(cached.sizeNote, isNotNull);
        }
        if (code == '8997009781110') expect(result.packageMl, 500);
      },
    );
  }

  Map<String, dynamic> copyOf(int index) =>
      jsonDecode(jsonEncode(fixtures[index])) as Map<String, dynamic>;
  test('one portion is not a bottle, and a bare number is not a volume', () {
    final data = copyOf(2);
    final row = data['product'] as Map;
    row.remove('product_quantity');
    row.remove('product_quantity_unit');
    row['quantity'] = '6';
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(row['code'], data),
      throwsA(
        isA<BarcodeLookupException>().having(
          (e) => e.failure,
          'reason',
          BarcodeFailure.unknownVolume,
        ),
      ),
    );
  });

  test(
    'only explicit ml servings allow conversion, never 100 g into 100 ml',
    () {
      final data = copyOf(3);
      final row = data['product'] as Map;
      row['nutrition_data_per'] = '100g';
      row['serving_size'] = '200 g';
      row['serving_quantity'] = 200;
      row['serving_quantity_unit'] = 'g';
      expect(
        () => BarcodeLookupService.parseOpenFoodFacts(row['code'], data),
        throwsA(
          isA<BarcodeLookupException>().having(
            (e) => e.failure,
            'reason',
            BarcodeFailure.incompleteNutrition,
          ),
        ),
      );
      row['serving_size'] = '200 ml';
      row['serving_quantity_unit'] = 'ml';
      expect(
        BarcodeLookupService.parseOpenFoodFacts(
          row['code'],
          data,
        ).sugarGramsPerPortion,
        4,
      );
    },
  );

  test('milk powder and contradictory nutrient values remain rejected', () {
    final data = copyOf(3);
    final row = data['product'] as Map;
    (row['categories_tags'] as List).add('en:milk-powders');
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(row['code'], data),
      throwsA(
        isA<BarcodeLookupException>().having(
          (e) => e.failure,
          'reason',
          BarcodeFailure.unsupported,
        ),
      ),
    );
    (row['categories_tags'] as List).remove('en:milk-powders');
    row['nutriments']['sugars_100g'] = 20;
    expect(
      () => BarcodeLookupService.parseOpenFoodFacts(row['code'], data),
      throwsA(
        isA<BarcodeLookupException>().having(
          (e) => e.failure,
          'reason',
          BarcodeFailure.invalidData,
        ),
      ),
    );
  });
}
