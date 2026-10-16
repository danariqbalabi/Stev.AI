import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/stev_backend_config.dart';
import '../../drinks/data/drink_catalog_repository.dart';
import '../domain/barcode_product.dart';
import 'barcode_local_store.dart';

class BarcodeLookupService implements BarcodeLookup {
  BarcodeLookupService({
    this.client,
    this.supabaseUrl = StevBackendConfig.supabaseUrl,
    this.publishableKey = StevBackendConfig.supabasePublishableKey,
    this.timeout = const Duration(seconds: 12),
    BarcodeLocalStore? store,
    DateTime Function()? now,
  }) : store = store ?? BarcodeLocalStore(),
       now = now ?? DateTime.now;

  final http.Client? client;
  final String supabaseUrl;
  final String publishableKey;
  final Duration timeout;
  final BarcodeLocalStore store;
  final DateTime Function() now;
  final _inFlight = <String, Future<BarcodeProduct>>{};

  @override
  Future<BarcodeProduct> lookup(String barcode) {
    final code = validRetailBarcode(barcode);
    if (code == null) {
      return Future.error(
        const BarcodeLookupException(
          'Barcode tidak valid. Periksa angka di bawah garis barcode.',
        ),
      );
    }
    return _inFlight.putIfAbsent(code, () async {
      try {
        return await _lookup(code);
      } finally {
        _inFlight.remove(code);
      }
    });
  }

  Future<BarcodeProduct> _lookup(String code) async {
    final cacheKey = '$supabaseUrl|$code';
    final cached = await store.read(cacheKey, now());
    if (cached != null) {
      try {
        final product = cached['provider'] == 'catalog'
            ? _catalogProduct(
                code,
                Map<String, Object?>.from(cached['data'] as Map),
              )
            : parseOpenFoodFacts(code, cached['data']);
        if (product != null) {
          return product.fromCache(DateTime.parse(cached['at'] as String));
        }
      } catch (_) {
        // Corrupt or no-longer-valid cache entries are never nutrition results.
      }
    }
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
              product = _catalogProduct(code, row);
              if (product != null) {
                await store.write(cacheKey, {
                  'provider': 'catalog',
                  'data': row,
                }, now());
              }
            }
          }
        } catch (_) {
          // A catalog outage still allows a lookup in the external database.
        }
      }
      if (product == null) {
        final retryAt = await store.reserve(now());
        if (retryAt != null) throw _limited(retryAt);
        final response = await requestClient
            .get(
              Uri.https(
                'world.openfoodfacts.org',
                '/api/v2/product/$code.json',
                {
                  'fields': 'code,product_name,product_quantity,product_quantity_unit,quantity,nutriments,categories_tags,image_front_small_url,nutrition_data_per,serving_size,serving_quantity,serving_quantity_unit',
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
        if (response.statusCode == 429) {
          throw _limited(
            await store.block(response.headers['retry-after'], now()),
          );
        }
        if (response.statusCode == 404) {
          throw const BarcodeLookupException(
            'Produk belum ditemukan. Coba Foto Minuman, cari manual, atau tambah minuman sendiri.',
            failure: BarcodeFailure.notFound,
          );
        }
        if (response.statusCode != 200) {
          throw const BarcodeLookupException(
            'Pencarian barcode sedang bermasalah. Coba lagi sebentar.',
          );
        }
        final decoded = jsonDecode(response.body);
        product = parseOpenFoodFacts(code, decoded);
        await store.write(cacheKey, {
          'provider': 'off',
          'data': decoded,
        }, now());
      }
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

  static BarcodeLookupException _limited(DateTime retryAt) =>
      BarcodeLookupException(
        'Pencarian barcode perlu jeda. Kamu tetap bisa scan Label Gizi atau isi label manual.',
        retryAt: retryAt,
        failure: BarcodeFailure.rateLimited,
      );

  static BarcodeProduct? _catalogProduct(
    String code,
    Map<String, Object?> row,
  ) {
    final drink = SupabaseDrinkCatalogMapper.fromRow(row);
    final ml = _positive(row['serving_ml']);
    if (drink == null ||
        !drink.grams.isFinite ||
        drink.grams < 0 ||
        ml == null) {
      return null;
    }
    return BarcodeProduct(
      barcode: code,
      name: drink.name,
      sugarGramsPerPortion: drink.grams,
      portionLabel: '${_number(ml)} ml (porsi katalog)',
      portionMl: ml,
      packageVolumeMl: ml,
      source: 'Katalog Stev.AI',
      sourceUrl: drink.sourceUrl ?? '',
      imageUrl: drink.photoUrl,
      catalogDrink: drink,
    );
  }

  static BarcodeProduct parseOpenFoodFacts(String code, Object? decoded) {
    if (decoded is! Map ||
        decoded['status'] != 1 ||
        decoded['product'] is! Map) {
      throw const BarcodeLookupException(
        'Produk belum ditemukan. Coba cari manual atau tambah minuman sendiri.',
        failure: BarcodeFailure.notFound,
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
    Never fail(String message, BarcodeFailure reason) =>
        throw BarcodeLookupException(
          message,
          failure: reason,
          productName: name is String && name.trim().isNotEmpty
              ? name.trim().substring(0, name.trim().length.clamp(0, 160))
              : null,
        );
    final nutrients = row['nutriments'];
    final tags = row['categories_tags'] is List
        ? (row['categories_tags'] as List).whereType<String>().toList()
        : <String>[];
    if (tags.any(
      (tag) => const [
        'en:beverage-preparations',
        'en:syrups',
        'en:concentrated-drinks',
        'en:powdered-drinks',
        'en:milk-powders',
        'en:powdered-milks',
        'en:condensed-milks',
        'en:sweetened-condensed-milks',
      ].contains(tag),
    )) {
      fail(
        'Produk ini perlu diracik atau diencerkan. Gunakan input manual sesuai label.',
        BarcodeFailure.unsupported,
      );
    }
    final liquidCategory = tags.any(
      (tag) => const [
        'en:beverages',
        'en:milks',
        'en:uht-milks',
        'en:whole-milks',
        'en:skimmed-milks',
        'en:semi-skimmed-milks',
        'en:plant-milks',
      ].contains(tag),
    );
    if (tags.isNotEmpty && !liquidCategory) {
      fail(
        'Produk ini belum teridentifikasi sebagai minuman siap minum. Foto label atau isi manual.',
        BarcodeFailure.unsupported,
      );
    }
    final servingMl = _servingVolume(row);
    final per100Ml = row['nutrition_data_per'] == '100ml';
    final servingSugar = nutrients is Map
        ? _nonNegative(nutrients['sugars_serving'])
        : null;
    final sugar100 = per100Ml && nutrients is Map
        ? _nonNegative(nutrients['sugars_100g'])
        : null;
    final sugarFromServing = servingMl != null && servingSugar != null
        ? servingSugar / servingMl * 100
        : null;
    final sugar = sugar100 ?? sugarFromServing;
    if (name is! String ||
        name.trim().isEmpty ||
        sugar == null ||
        sugar > 100) {
      fail(
        'Produk ditemukan, tetapi angka gula dan satuannya belum lengkap atau tidak valid. Foto label gizi untuk melanjutkan.',
        BarcodeFailure.incompleteNutrition,
      );
    }
    if (sugar100 != null &&
        sugarFromServing != null &&
        (sugar100 - sugarFromServing).abs() > 0.5) {
      fail(
        'Angka gula per sajian dan per 100 ml pada sumber tidak konsisten. Foto label gizi untuk memeriksa angkanya.',
        BarcodeFailure.invalidData,
      );
    }
    final carbs = nutrients is Map
        ? (per100Ml
              ? _nonNegative(nutrients['carbohydrates_100g'])
              : servingMl != null &&
                    _nonNegative(nutrients['carbohydrates_serving']) != null
              ? _nonNegative(nutrients['carbohydrates_serving'])! /
                    servingMl *
                    100
              : null)
        : null;
    // Small differences can be rounding; gross contradictions require a label.
    if (carbs != null && sugar > carbs + 0.5) {
      fail(
        'Angka gula melebihi karbohidrat pada data sumber. Foto label gizi untuk memeriksa angkanya.',
        BarcodeFailure.invalidData,
      );
    }
    final size = _packageVolume(row);
    if (size == null || !size.ml.isFinite || size.ml <= 0 || size.ml > 10000) {
      fail(
        'Produk ditemukan, tetapi ukuran kemasannya belum jelas. Foto label gizi; jangan menyamakan satu sajian dengan satu botol.',
        BarcodeFailure.unknownVolume,
      );
    }
    final image = row['image_front_small_url'];
    return BarcodeProduct(
      barcode: code,
      name: name.trim(),
      sugarGramsPerPortion: sugar,
      portionLabel: '100 ml',
      portionMl: 100,
      defaultPortions: size.ml / 100,
      packageVolumeMl: size.ml,
      requiresDrinkConfirmation: tags.isEmpty,
      sizeNote: size.fromServing
          ? 'Ukuran memakai keterangan satu botol/kemasan pada takaran saji. Cocokkan dengan isi bersih produkmu.'
          : null,
      source: 'Open Food Facts — belum diverifikasi Stev.AI',
      sourceUrl: 'https://world.openfoodfacts.org/product/$code',
      imageUrl: image is String && Uri.tryParse(image)?.scheme == 'https'
          ? image
          : null,
    );
  }
}

double? _explicitMl(Object? amount, Object? unit) {
  final value = _positive(amount);
  if (value == null || unit is! String) return null;
  final multiplier = switch (unit.trim().toLowerCase()) {
    'ml' || 'milliliter' || 'milliliters' || 'millilitre' || 'millilitres' => 1,
    'cl' => 10,
    'l' || 'liter' || 'liters' || 'litre' || 'litres' => 1000,
    _ => null,
  };
  return multiplier == null ? null : value * multiplier;
}

double? _volumeText(Object? raw) {
  if (raw is! String) return null;
  final match = RegExp(
    r'^\s*(\d+(?:[.,]\d+)?)\s*(ml|cl|l|liters?|litres?|milliliters?|millilitres?)\s*$',
    caseSensitive: false,
  ).firstMatch(raw);
  return match == null
      ? null
      : _explicitMl(match[1]!.replaceAll(',', '.'), match[2]);
}

double? _servingVolume(Map row) {
  final unit = row['serving_quantity_unit'];
  if (unit is String &&
      unit.trim().isNotEmpty &&
      _explicitMl(1, unit) == null) {
    return null;
  }
  final numeric = _explicitMl(row['serving_quantity'], unit);
  final text = row['serving_size'];
  final parenthesized = text is String
      ? RegExp(
          r'^\s*1\s+(?:bottle|botol|can|kaleng|carton|kotak|kemasan|portion|serving|sajian)\s*\(([^()]+)\)\s*$',
          caseSensitive: false,
        ).firstMatch(text)
      : null;
  final parsed = _volumeText(text) ?? _volumeText(parenthesized?[1]);
  if (numeric != null && parsed != null && (numeric - parsed).abs() > 0.5) {
    return null;
  }
  return numeric ?? parsed;
}

({double ml, bool fromServing})? _packageVolume(Map row) {
  // Never interpret a weight as a volume, or a bare serving as a whole bottle.
  final unit = row['product_quantity_unit'];
  if (unit is String &&
      unit.trim().isNotEmpty &&
      _explicitMl(1, unit) == null) {
    return null;
  }
  final ml =
      _explicitMl(row['product_quantity'], unit) ??
      _volumeText(row['quantity']);
  if (ml != null) return (ml: ml, fromServing: false);
  final serving = row['serving_size'];
  if (serving is! String ||
      !RegExp(
        r'^\s*1\s+(?:bottle|botol|can|kaleng|carton|kotak|kemasan)(?:\s*\([^()]+\))?\s*$',
        caseSensitive: false,
      ).hasMatch(serving)) {
    return null;
  }
  final servingMl = _servingVolume(row);
  return servingMl == null ? null : (ml: servingMl, fromServing: true);
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
