import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steviai/features/nutrition/data/remote_nutrition_label_reader.dart';
import 'package:steviai/features/nutrition/domain/nutrition_label.dart';

Map<String, dynamic> labelJson() => {
  'sugarGrams': 9,
  'basis': 'per_serving',
  'servingMl': 150,
  'servingsPerPackage': 2,
  'packageMl': 300,
  'productName': 'Teh uji',
  'sugarText': 'Gula total 9 g',
  'basisText': 'Takaran saji 150 ml',
  'confidence': 0.95,
};

void main() {
  test('calculates each basis and consumed fraction without doubling package sugar', () {
    expect(
      nutritionSugarFor(
        sugarGrams: 9,
        basis: NutritionBasis.perServing,
        consumedFraction: 1,
        servingsPerPackage: 2,
      ),
      18,
    );
    expect(
      nutritionSugarFor(
        sugarGrams: 9,
        basis: NutritionBasis.perServing,
        consumedFraction: 0.5,
        servingsPerPackage: 2,
      ),
      9,
    );
    expect(
      nutritionSugarFor(
        sugarGrams: 6,
        basis: NutritionBasis.per100Ml,
        consumedFraction: 1,
        packageMl: 300,
      ),
      18,
    );
    expect(
      nutritionSugarFor(
        sugarGrams: 18,
        basis: NutritionBasis.perPackage,
        consumedFraction: 1,
        servingsPerPackage: 2,
      ),
      18,
    );
    expect(
      nutritionSugarFor(
        sugarGrams: 0,
        basis: NutritionBasis.perPackage,
        consumedFraction: 1,
      ),
      0,
    );
  });

  test(
    'unknown quantities stay null and cannot produce a whole package total',
    () {
      final json = labelJson()..['servingsPerPackage'] = null;
      expect(NutritionLabel.fromJson(json).servingsPerPackage, isNull);
      expect(
        () => nutritionSugarFor(
          sugarGrams: 9,
          basis: NutritionBasis.perServing,
          consumedFraction: 1,
        ),
        throwsFormatException,
      );
      expect(
        () => nutritionSugarFor(
          sugarGrams: 9,
          basis: NutritionBasis.per100Ml,
          consumedFraction: 1,
        ),
        throwsFormatException,
      );
      for (final value in [-1.0, double.nan, double.infinity]) {
        expect(
          () => nutritionSugarFor(
            sugarGrams: value,
            basis: NutritionBasis.perPackage,
            consumedFraction: 1,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('rejects malformed and low confidence service output', () {
    for (final override in [
      {'sugarGrams': null},
      {'sugarGrams': -1},
      {'confidence': 0.1},
      {'basis': 'per_100g'},
      {'sugarText': ''},
      {'packageMl': -1},
    ]) {
      expect(
        () => NutritionLabel.fromJson({...labelJson(), ...override}),
        throwsA(isA<NutritionLabelException>()),
      );
    }
  });

  test(
    'sends photo only to configured edge function and maps result',
    () async {
      final reader = RemoteNutritionLabelReader(
        supabaseUrl: 'https://example.supabase.co',
        publishableKey: 'public-key',
        client: MockClient((request) async {
          expect(request.url.path, '/functions/v1/read-nutrition-label');
          expect(request.headers['apikey'], 'public-key');
          final body = jsonDecode(request.body) as Map;
          expect(body['mimeType'], 'image/jpeg');
          expect(base64Decode(body['imageBase64'] as String), [255, 216, 255]);
          expect(body.containsKey('catalogIds'), isFalse);
          return http.Response(jsonEncode({'label': labelJson()}), 200);
        }),
      );
      expect(
        (await reader.read(Uint8List.fromList([255, 216, 255]))).sugarGrams,
        9,
      );
    },
  );

  test('rejects unsupported photos before making a request', () async {
    final reader = RemoteNutritionLabelReader(
      client: MockClient((_) async => throw StateError('Unexpected request')),
    );
    for (final bytes in [
      Uint8List(0),
      Uint8List.fromList([1, 2, 3]),
      Uint8List(RemoteNutritionLabelReader.maxImageBytes + 1),
    ]) {
      await expectLater(
        reader.read(bytes),
        throwsA(isA<NutritionLabelException>()),
      );
    }
  });

  test(
    'handles unavailable configuration, invalid output and HTTP failures',
    () async {
      await expectLater(
        const RemoteNutritionLabelReader(supabaseUrl: '')
            .read(Uint8List.fromList([255, 216, 255])),
        throwsA(isA<NutritionLabelException>()),
      );
      for (final status in [200, 401, 404, 422, 429, 500]) {
        final reader = RemoteNutritionLabelReader(
          supabaseUrl: 'https://example.supabase.co',
          publishableKey: 'public-key',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(
          reader.read(Uint8List.fromList([255, 216, 255])),
          throwsA(isA<NutritionLabelException>()),
        );
      }
      final reader = RemoteNutritionLabelReader(
        supabaseUrl: 'https://example.supabase.co',
        publishableKey: 'public-key',
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(
        reader.read(Uint8List.fromList([255, 216, 255])),
        throwsA(isA<NutritionLabelException>()),
      );
    },
  );
}
