import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:steviai/features/drinks/data/drink_catalog.dart';
import 'package:steviai/features/drinks/domain/drink.dart';
import 'package:steviai/features/recognition/data/demo_drink_recognition_service.dart';
import 'package:steviai/features/recognition/data/drink_recognition_service_factory.dart';
import 'package:steviai/features/recognition/data/remote_drink_recognition_service.dart';
import 'package:steviai/features/recognition/domain/drink_recognition.dart';

void main() {
  group('RemoteDrinkRecognitionService', () {
    test('uses and resolves IDs from an injected remote catalog', () async {
      const remoteDrink = Drink(
        id: 'remote-drink',
        name: 'Remote drink',
        grams: 8,
        estimated: false,
        category: DrinkCategory.packaged,
        kind: DrinkKind.tea,
      );
      late Map<String, dynamic> requestBody;
      final service = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        catalog: const [remoteDrink],
        client: MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'candidates': ['remote-drink'],
            }),
            200,
          );
        }),
      );

      final candidates = await service.identify(Uint8List.fromList([1]));

      expect(requestBody['catalogIds'], ['remote-drink']);
      expect(candidates, [remoteDrink]);
    });

    test('sends the image and maps up to three unique catalog IDs', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'candidates': [
              {'id': 'hydro-coco', 'confidence': 0.94},
              'unknown-drink',
              {'id': 'hydro-coco', 'confidence': 0.82},
              'sprite-botol',
              'es-jeruk',
              'matcha',
            ],
          }),
          200,
        );
      });
      final service = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        bearerToken: 'demo-token',
        apiKey: 'publishable-key',
        client: client,
      );

      final candidates = await service.identify(Uint8List.fromList([1, 2, 3]));
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.headers['authorization'], 'Bearer demo-token');
      expect(capturedRequest.headers['apikey'], 'publishable-key');
      expect(body['imageBase64'], base64Encode([1, 2, 3]));
      expect(body['mimeType'], 'image/jpeg');
      expect(body['catalogIds'], contains('hydro-coco'));
      expect(candidates, [
        DrinkCatalog.hydroCoco,
        DrinkCatalog.spriteBotol,
        DrinkCatalog.esJeruk,
      ]);
    });

    test('turns a server error into a recognition exception', () async {
      final service = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        client: MockClient((_) async => http.Response('unavailable', 503)),
      );

      expect(
        () => service.identify(Uint8List.fromList([1])),
        throwsA(isA<DrinkRecognitionException>()),
      );
    });

    test('rejects an oversized photo before calling the server', () async {
      var requestCount = 0;
      final service = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        client: MockClient((_) async {
          requestCount++;
          return http.Response('{}', 200);
        }),
      );

      expect(
        () => service.identify(
          Uint8List(RemoteDrinkRecognitionService.maxImageBytes + 1),
        ),
        throwsA(
          isA<DrinkRecognitionException>().having(
            (error) => error.message,
            'message',
            contains('8 MB'),
          ),
        ),
      );
      expect(requestCount, 0);
    });

    test('rejects malformed and unknown-only candidates', () async {
      final malformed = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        client: MockClient((_) async => http.Response('{oops', 200)),
      );
      final unknownOnly = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'candidates': ['not-in-catalog'],
            }),
            200,
          ),
        ),
      );

      expect(
        () => malformed.identify(Uint8List.fromList([1])),
        throwsA(isA<DrinkRecognitionException>()),
      );
      expect(
        () => unknownOnly.identify(Uint8List.fromList([1])),
        throwsA(isA<DrinkRecognitionException>()),
      );
    });

    test('reports a timeout', () async {
      final service = RemoteDrinkRecognitionService(
        endpoint: Uri.parse('https://api.example.com/recognize'),
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
      );

      expect(
        () => service.identify(Uint8List.fromList([1])),
        throwsA(
          isA<DrinkRecognitionException>().having(
            (error) => error.message,
            'message',
            contains('terlalu lama'),
          ),
        ),
      );
    });
  });

  group('DrinkRecognitionServiceFactory', () {
    test('uses the demo adapter when endpoint is missing or invalid', () {
      expect(
        DrinkRecognitionServiceFactory.create(endpoint: ''),
        isA<DemoDrinkRecognitionService>(),
      );
      expect(
        DrinkRecognitionServiceFactory.create(endpoint: 'not-a-url'),
        isA<DemoDrinkRecognitionService>(),
      );
    });

    test('uses the remote adapter for an HTTP endpoint', () {
      expect(
        DrinkRecognitionServiceFactory.create(
          endpoint: 'https://api.example.com/recognize',
        ),
        isA<RemoteDrinkRecognitionService>(),
      );
    });

    test('adds publishable key only for a Supabase function', () {
      final supabase = DrinkRecognitionServiceFactory.create(
        endpoint: 'https://project.supabase.co/functions/v1/recognize-drink',
        supabasePublishableKey: 'publishable-key',
      ) as RemoteDrinkRecognitionService;
      final generic = DrinkRecognitionServiceFactory.create(
        endpoint: 'https://api.example.com/recognize',
        supabasePublishableKey: 'publishable-key',
      ) as RemoteDrinkRecognitionService;

      expect(supabase.apiKey, 'publishable-key');
      expect(generic.apiKey, isNull);
    });
  });
}
