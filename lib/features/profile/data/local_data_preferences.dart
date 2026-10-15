import 'package:shared_preferences/shared_preferences.dart';

abstract final class LocalDataPreferences {
  static const _appKeyPrefix = 'stev-';
  static const _syncKeyPrefix = 'stev-sync-';
  static const revisionKey = 'stev-sync-local-updated-at';
  static const lastSyncedKey = 'stev-sync-last-completed-at';
  static const ownerUserKey = 'stev-sync-owner-user-id';
  static const dirtyKey = 'stev-sync-local-dirty';

  static Future<void> touch({DateTime? at}) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      revisionKey,
      (at ?? DateTime.now()).toUtc().toIso8601String(),
    );
    await preferences.setBool(dirtyKey, true);
  }

  static Future<DateTime?> localRevision() async {
    final preferences = await SharedPreferences.getInstance();
    return DateTime.tryParse(preferences.getString(revisionKey) ?? '');
  }

  static Future<DateTime?> lastSyncedAt() async {
    final preferences = await SharedPreferences.getInstance();
    return DateTime.tryParse(preferences.getString(lastSyncedKey) ?? '');
  }

  static Future<String?> ownerUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(ownerUserKey);
  }

  static Future<bool> isDirty() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(dirtyKey) ?? false;
  }

  static Future<Map<String, Object?>> exportData() async {
    final preferences = await SharedPreferences.getInstance();
    final result = <String, Object?>{};
    for (final key in preferences.getKeys()) {
      if (!key.startsWith(_appKeyPrefix) || key.startsWith(_syncKeyPrefix)) {
        continue;
      }
      final value = preferences.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        result[key] = value;
      }
    }
    return result;
  }

  static Future<void> importData(
    Map<String, Object?> data, {
    required DateTime syncedAt,
    required String userId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final dataKeys = preferences
        .getKeys()
        .where(
          (key) =>
              key.startsWith(_appKeyPrefix) && !key.startsWith(_syncKeyPrefix),
        )
        .toList(growable: false);
    for (final key in dataKeys) {
      await preferences.remove(key);
    }
    for (final entry in data.entries) {
      if (!entry.key.startsWith(_appKeyPrefix) ||
          entry.key.startsWith(_syncKeyPrefix)) {
        continue;
      }
      final value = entry.value;
      if (value is String) await preferences.setString(entry.key, value);
      if (value is bool) await preferences.setBool(entry.key, value);
      if (value is int) await preferences.setInt(entry.key, value);
      if (value is double) await preferences.setDouble(entry.key, value);
      if (value is List) {
        await preferences.setStringList(
          entry.key,
          value.whereType<String>().toList(growable: false),
        );
      }
    }
    final timestamp = syncedAt.toUtc().toIso8601String();
    await preferences.setString(revisionKey, timestamp);
    await preferences.setString(lastSyncedKey, timestamp);
    await preferences.setString(ownerUserKey, userId);
    await preferences.setBool(dirtyKey, false);
  }

  static Future<void> markSynced(
    DateTime timestamp, {
    required String userId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      lastSyncedKey,
      timestamp.toUtc().toIso8601String(),
    );
    await preferences.setString(ownerUserKey, userId);
    await preferences.setBool(dirtyKey, false);
  }

  /// Removes only data owned by Stev.AI and leaves unrelated preferences
  /// untouched.
  static Future<int> resetAll() async {
    final preferences = await SharedPreferences.getInstance();
    final appKeys = preferences
        .getKeys()
        .where((key) => key.startsWith(_appKeyPrefix))
        .toList(growable: false);
    for (final key in appKeys) {
      await preferences.remove(key);
    }
    return appKeys.length;
  }
}
