import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/stev_backend_config.dart';
import '../domain/nutrition_label.dart';

class RemoteNutritionLabelReader implements NutritionLabelReader {
  const RemoteNutritionLabelReader({
    this.supabaseUrl = StevBackendConfig.supabaseUrl,
    this.publishableKey = StevBackendConfig.supabasePublishableKey,
    this.client,
    this.timeout = const Duration(seconds: 40),
  });

  final String supabaseUrl;
  final String publishableKey;
  final http.Client? client;
  final Duration timeout;
  static const maxImageBytes = 8 * 1024 * 1024;

  @override
  Future<NutritionLabel> read(Uint8List photoBytes) async {
    if (photoBytes.isEmpty || photoBytes.length > maxImageBytes) {
      throw const NutritionLabelException(
        'Pilih foto berukuran maksimal 8 MB.',
      );
    }
    final mime = _mime(photoBytes);
    if (mime == null) {
      throw const NutritionLabelException('Gunakan foto JPEG, PNG, atau WebP.');
    }
    if (!StevBackendConfig.isValid(
      url: supabaseUrl,
      publishableKey: publishableKey,
    )) {
      throw const NutritionLabelException(
        'Pembaca label belum terhubung. Coba lagi setelah konfigurasi aplikasi tersedia.',
      );
    }
    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient
          .post(
            Uri.parse(
              '${supabaseUrl.replaceAll(RegExp(r'/+$'), '')}/functions/v1/read-nutrition-label',
            ),
            headers: {
              'apikey': publishableKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'imageBase64': base64Encode(photoBytes),
              'mimeType': mime,
            }),
          )
          .timeout(timeout);
      if (response.statusCode == 422) {
        throw const NutritionLabelException(
          'Gula atau takaran saji belum terbaca jelas. Foto ulang tabel gizi atau isi manual.',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const NutritionLabelException(
          'Akses pembaca label ditolak. Periksa konfigurasi aplikasi.',
        );
      }
      if (response.statusCode == 404) {
        throw const NutritionLabelException(
          'Pembaca label belum tersedia. Coba lagi nanti atau isi manual.',
        );
      }
      if (response.statusCode == 429) {
        throw const NutritionLabelException(
          'Pembaca label sedang sibuk. Tunggu sebentar sebelum mencoba lagi.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const NutritionLabelException(
          'Layanan pembaca label sedang bermasalah. Coba lagi atau isi manual.',
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> ||
          body['label'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid label response.');
      }
      return NutritionLabel.fromJson(body['label'] as Map<String, dynamic>);
    } on NutritionLabelException {
      rethrow;
    } on TimeoutException {
      throw const NutritionLabelException(
        'Pembacaan label terlalu lama. Periksa koneksi dan coba lagi.',
      );
    } catch (_) {
      throw const NutritionLabelException(
        'Label belum dapat dibaca. Periksa koneksi, foto ulang, atau isi manual.',
      );
    } finally {
      if (client == null) requestClient.close();
    }
  }
}

String? _mime(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}
