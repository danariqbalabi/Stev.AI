import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/stev_backend_config.dart';
import '../../drinks/data/drink_catalog_repository.dart';
import '../domain/barcode_product.dart';

class BarcodeLookupService implements BarcodeLookup {
  BarcodeLookupService({
    this.client,
    this.supabaseUrl = StevBackendConfig.supabaseUrl,
    this.publishableKey = StevBackendConfig.supabasePublishableKey,
    this.timeout = const Duration(seconds: 12),
  });

  final http.Client? client;
  final String supabaseUrl;
  final String publishableKey;
  final Duration timeout;
  final _cache = <String, BarcodeProduct>{};

  @override
  Future<BarcodeProduct> lookup(String barcode) async {
    final code = validRetailBarcode(barcode);
    if (code == null) {
      throw const BarcodeLookupException(
        'Barcode tidak valid. Periksa angka di bawah garis barcode.',
      );
    }
    if (_cache[code] case final product?) return product;
    final requestClient = client ?? http.Client();
    try {
      BarcodeProduct? product;
      if (StevBackendConfig.isValid(
        url: supabaseUrl,
        publishableKey: publishableKey,
      )) {
        try {
          final response = await requestClient
              .get(
                Uri.parse('$supabaseUrl/rest/v1/drinks').replace(
                  queryParameters: {
                    'barcode': 'eq.$code',
                    'verified': 'eq.true',
                    'select': '*',
                    'limit': '1',
                  },
                ),
                headers: {'apikey': publishableKey},
              )
              .timeout(timeout);
          if (response.statusCode == 200) {
            final rows = jsonDecode(response.body);
            if (rows is List && rows.isNotEmpty && rows.first is Map) {
              final row = Map<String, Object?>.from(rows.first as Map);
              final drink = SupabaseDrinkCatalogMapper.fromRow(row);
              final ml = _positive(row['serving_ml']);
              if (drink != null &&
                  drink.grams.isFinite &&
                  drink.grams >= 0 &&
                  ml != null) {
                product = BarcodeProduct(
                  barcode: code,
                  name: drink.name,
                  sugarGramsPerPortion: drink.grams,
                  portionLabel: '${_number(ml)} ml (porsi katalog)',
                  source: 'Katalog Stev.AI',
                  sourceUrl: drink.sourceUrl ?? '',
                  imageUrl: drink.photoUrl,
                  catalogDrink: drink,
                );
              }
            }
          }
        } catch (_) {
          // A catalog outage still allows a lookup in the external database.
        }
      }
      if (product == null) {
        final response = await requestClient
            .get(
              Uri.https(
                'world.openfoodfacts.org',
                '/api/v2/product/$code.json',
                {
                  'fields': 'code,product_name,product_quantity,product_quantity_unit,quantity,nutriments,categories_tags,image_front_small_url',
                  // Browsers control their own User-Agent header.
                  'app_name': 'StevAI',
                },
              ),
              headers: {
                if (!kIsWeb)
                  'User-Agent':
                      'StevAI/1.0 (https://github.com/danariqbalabi/Stev.AI)',
              },
            )
            .timeout(timeout);
        if (response.statusCode == 404) {
          throw const BarcodeLookupException(
            'Produk belum ditemukan. Coba Foto Minuman, cari manual, atau tambah minuman sendiri.',
          );
        }
        if (response.statusCode != 200) {
          throw const BarcodeLookupException(
            'Pencarian barcode sedang bermasalah. Coba lagi sebentar.',
          );
        }
        product = parseOpenFoodFacts(code, jsonDecode(response.body));
      }
      if (_cache.length >= 50) _cache.remove(_cache.keys.first);
      _cache[code] = product;
      return product;
    } on BarcodeLookupException {
      rethrow;
    } catch (_) {
      throw const BarcodeLookupException(
        'Data produk belum dapat dihubungi. Periksa koneksi dan coba lagi.',
      );
    } finally {
      if (client == null) requestClient.close();
    }
  }

  static BarcodeProduct parseOpenFoodFacts(String code, Object? decoded) {
    if (decoded is! Map ||
        decoded['status'] != 1 ||
        decoded['product'] is! Map) {
      throw const BarcodeLookupException(
        'Produk belum ditemukan. Coba cari manual atau tambah minuman sendiri.',
      );
    }
    final row = decoded['product'] as Map;
    if (row['code'] is! String ||
        (row['code'] as String).padLeft(14, '0') != code.padLeft(14, '0')) {
      throw const BarcodeLookupException(
        'Identitas produk tidak cocok. Periksa barcode atau cari manual.',
      );
    }
    final name = row['product_name'];
    final nutrients = row['nutriments'];
    final tags = row['categories_tags'];
    if (tags is! List || !tags.contains('en:beverages')) {
      throw const BarcodeLookupException(
        'Produk ini belum teridentifikasi sebagai minuman. Coba cari manual.',
      );
    }
    if (tags.any(
      (tag) => const [
        'en:beverage-preparations',
        'en:syrups',
        'en:concentrated-drinks',
        'en:powdered-drinks',
      ].contains(tag),
    )) {
      throw const BarcodeLookupException(
        'Produk ini perlu diracik atau diencerkan. Gunakan input manual sesuai label.',
      );
    }
    final sugar = nutrients is Map
        ? _nonNegative(nutrients['sugars_100g'])
        : null;
    if (name is! String ||
        name.trim().isEmpty ||
        sugar == null ||
        sugar > 100) {
      throw const BarcodeLookupException(
        'Produk ditemukan, tetapi data gulanya belum lengkap. Periksa label atau input manual.',
      );
    }
    // Do not convert grams to millilitres. Only explicit liquid quantities
    // allow the per-100-ml calculation used by this drink scanner.
    var ml = switch (row['product_quantity_unit']) {
      'ml' => _positive(row['product_quantity']),
      'l' => (_positive(row['product_quantity']) ?? 0) * 1000,
      _ => null,
    };
    final quantity = row['quantity'];
    if (ml == null && quantity is String) {
      final match = RegExp(
        r'^\s*(\d+(?:[.,]\d+)?)\s*(ml|cl|l)\s*$',
        caseSensitive: false,
      ).firstMatch(quantity);
      if (match != null) {
        final value = double.parse(match[1]!.replaceAll(',', '.'));
        ml =
            value *
            switch (match[2]!.toLowerCase()) {
              'l' => 1000,
              'cl' => 10,
              _ => 1,
            };
      }
    }
    if (ml == null || !ml.isFinite || ml <= 0 || ml > 10000) {
      throw const BarcodeLookupException(
        'Ukuran minuman dalam ml belum jelas. Periksa label atau input manual.',
      );
    }
    final image = row['image_front_small_url'];
    return BarcodeProduct(
      barcode: code,
      name: name.trim(),
      sugarGramsPerPortion: sugar,
      portionLabel: '100 ml',
      defaultPortions: ml / 100,
      source: 'Open Food Facts — belum diverifikasi Stev.AI',
      sourceUrl: 'https://world.openfoodfacts.org/product/$code',
      imageUrl: image is String && Uri.tryParse(image)?.scheme == 'https'
          ? image
          : null,
    );
  }
}

double? _nonNegative(Object? raw) {
  final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
  return value != null && value.isFinite && value >= 0 ? value : null;
}

double? _positive(Object? raw) {
  final value = _nonNegative(raw);
  return value != null && value > 0 ? value : null;
}

String _number(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
