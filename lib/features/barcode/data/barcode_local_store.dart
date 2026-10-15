import 'dart:convert';

import 'package:http_parser/http_parser.dart' show parseHttpDate;
import 'package:shared_preferences/shared_preferences.dart';

/// Public product cache and best-effort device pacing, never account data.
class BarcodeLocalStore {
  static const cacheKey = 'stev-device-barcode-cache-v1';
  static const retryKey = 'stev-device-barcode-retry-at';
  static const ttl = Duration(days: 7);
  static Future<void> _queue = Future.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Map<String, dynamic>> _entries(SharedPreferences prefs) async {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(prefs.getString(cacheKey) ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>?> read(String key, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = (await _entries(prefs))[key];
      if (entry is! Map) return null;
      final at = DateTime.tryParse('${entry['at']}');
      if (at == null || at.isAfter(now) || now.difference(at) >= ttl) {
        return null;
      }
      return Map<String, dynamic>.from(entry);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, Object?> payload, DateTime now) =>
      _locked(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final entries = await _entries(prefs);
          entries.remove(key);
          while (entries.length >= 50) {
            entries.remove(entries.keys.first);
          }
          entries[key] = {...payload, 'at': now.toUtc().toIso8601String()};
          await prefs.setString(cacheKey, jsonEncode(entries));
        } catch (_) {
          // A storage failure must not discard a valid live product result.
        }
      });

  DateTime? _memoryRetry;

  Future<DateTime?> reserve(DateTime now) => _locked(() async {
    DateTime? retry = _memoryRetry;
    try {
      final prefs = await SharedPreferences.getInstance();
      retry = DateTime.tryParse(prefs.getString(retryKey) ?? '') ?? retry;
      if (retry != null && retry.isAfter(now)) return retry;
      _memoryRetry = now.add(const Duration(seconds: 6));
      await prefs.setString(retryKey, _memoryRetry!.toUtc().toIso8601String());
    } catch (_) {
      if (retry != null && retry.isAfter(now)) return retry;
      _memoryRetry = now.add(const Duration(seconds: 6));
    }
    return null;
  });

  Future<DateTime> block(String? retryAfter, DateTime now) => _locked(() async {
    final seconds = int.tryParse(retryAfter ?? '');
    DateTime? parsed;
    if (seconds != null && seconds > 0) {
      parsed = now.add(Duration(seconds: seconds));
    } else {
      try {
        parsed = parseHttpDate(retryAfter ?? '');
      } catch (_) {}
    }
    var until = parsed != null && parsed.isAfter(now)
        ? parsed
        : now.add(const Duration(seconds: 60));
    try {
      final prefs = await SharedPreferences.getInstance();
      final previous = DateTime.tryParse(prefs.getString(retryKey) ?? '');
      if (previous != null && previous.isAfter(until)) until = previous;
      await prefs.setString(retryKey, until.toUtc().toIso8601String());
    } catch (_) {}
    _memoryRetry = until;
    return until;
  });
}
