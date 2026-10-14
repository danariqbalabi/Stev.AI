import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../drinks/data/drink_catalog.dart';
import '../../drinks/domain/drink.dart';
import '../domain/drink_recognition.dart';

class RemoteDrinkRecognitionService implements DrinkRecognitionService {
  RemoteDrinkRecognitionService({
    required this.endpoint,
    this.bearerToken,
    this.timeout = const Duration(seconds: 15),
    this.client,
  });

  final Uri endpoint;
  final String? bearerToken;
  final Duration timeout;
  final http.Client? client;

  @override
  Future<List<Drink>> identify(Uint8List photoBytes) async {
    if (photoBytes.isEmpty) {
      throw const DrinkRecognitionException(
        'Foto kosong. Ambil ulang atau pilih gambar lain.',
      );
    }

    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              if (bearerToken case final token? when token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'imageBase64': base64Encode(photoBytes),
              'mimeType': 'image/jpeg',
              'catalogIds': DrinkCatalog.all.map((drink) => drink.id).toList(),
            }),
          )
          .timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const DrinkRecognitionException(
          'Layanan pengenalan sedang bermasalah. Coba lagi sebentar.',
        );
      }

      return _parseCandidates(response.body);
    } on DrinkRecognitionException {
      rethrow;
    } on TimeoutException {
      throw const DrinkRecognitionException(
        'Pengenalan minuman terlalu lama. Periksa koneksi lalu coba lagi.',
      );
    } on FormatException {
      throw const DrinkRecognitionException(
        'Jawaban layanan pengenalan tidak valid. Coba lagi.',
      );
    } on http.ClientException {
      throw const DrinkRecognitionException(
        'Layanan pengenalan tidak dapat dihubungi. Periksa koneksi internet.',
      );
    } catch (_) {
      throw const DrinkRecognitionException(
        'Minuman belum berhasil dikenali. Coba lagi atau cari manual.',
      );
    } finally {
      if (client == null) requestClient.close();
    }
  }

  List<Drink> _parseCandidates(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response root must be an object.');
    }

    final rawCandidates = decoded['candidates'];
    if (rawCandidates is! List) {
      throw const FormatException('Candidates must be a list.');
    }

    final seenIds = <String>{};
    final candidates = <Drink>[];
    for (final candidate in rawCandidates) {
      final id = switch (candidate) {
        String value => value,
        Map value when value['id'] is String => value['id'] as String,
        _ => null,
      };
      if (id == null || !seenIds.add(id)) continue;

      final drink = DrinkCatalog.findById(id);
      if (drink != null) candidates.add(drink);
      if (candidates.length == 3) break;
    }

    if (candidates.isEmpty) {
      throw const DrinkRecognitionException(
        'Minuman belum dikenali. Coba foto lain atau cari manual.',
      );
    }
    return candidates;
  }
}
