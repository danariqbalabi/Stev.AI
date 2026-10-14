import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../drinks/data/drink_catalog.dart';
import '../../drinks/domain/drink.dart';
import '../domain/drink_recognition.dart';

class RemoteDrinkRecognitionService implements DrinkRecognitionService {
  static const maxImageBytes = 8 * 1024 * 1024;
  static const minimumConfidence = 0.55;

  RemoteDrinkRecognitionService({
    required this.endpoint,
    this.bearerToken,
    this.apiKey,
    this.timeout = const Duration(seconds: 15),
    this.client,
    Iterable<Drink> catalog = DrinkCatalog.all,
  }) : catalog = List.unmodifiable(catalog);

  final Uri endpoint;
  final String? bearerToken;
  final String? apiKey;
  final Duration timeout;
  final http.Client? client;
  final List<Drink> catalog;

  @override
  Future<List<DrinkRecognitionCandidate>> identify(Uint8List photoBytes) async {
    if (photoBytes.isEmpty) {
      throw const DrinkRecognitionException(
        'Foto kosong. Ambil ulang atau pilih gambar lain.',
      );
    }
    if (photoBytes.length > maxImageBytes) {
      throw const DrinkRecognitionException(
        'Foto terlalu besar. Pilih foto berukuran maksimal 8 MB.',
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
              if (apiKey case final key? when key.isNotEmpty) 'apikey': key,
            },
            body: jsonEncode({
              'imageBase64': base64Encode(photoBytes),
              'mimeType': _detectMimeType(photoBytes),
              'catalogIds': catalog.map((drink) => drink.id).toList(),
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

  List<DrinkRecognitionCandidate> _parseCandidates(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response root must be an object.');
    }

    final rawCandidates = decoded['candidates'];
    if (rawCandidates is! List) {
      throw const FormatException('Candidates must be a list.');
    }

    final seenIds = <String>{};
    final candidates = <DrinkRecognitionCandidate>[];
    for (final candidate in rawCandidates) {
      if (candidate is! Map || candidate['id'] is! String) continue;
      final id = candidate['id'] as String;
      final confidenceValue = candidate['confidence'];
      if (confidenceValue is! num) continue;
      final confidence = confidenceValue.toDouble();
      if (!confidence.isFinite || confidence < minimumConfidence) continue;
      if (!seenIds.add(id)) continue;

      final drink = _findById(id);
      if (drink != null) {
        candidates.add(
          DrinkRecognitionCandidate(
            drink: drink,
            confidence: confidence.clamp(0.0, 1.0).toDouble(),
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      throw const DrinkRecognitionException(
        'Stev belum yakin dengan minuman ini. Coba foto yang lebih jelas atau cari manual.',
      );
    }
    candidates.sort(
      (left, right) => right.confidence.compareTo(left.confidence),
    );
    return candidates.take(3).toList(growable: false);
  }

  Drink? _findById(String id) {
    for (final drink in catalog) {
      if (drink.id == id) return drink;
    }
    return null;
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
