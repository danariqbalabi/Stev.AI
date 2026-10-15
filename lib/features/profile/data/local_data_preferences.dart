import 'package:shared_preferences/shared_preferences.dart';

abstract final class LocalDataPreferences {
  static const _appKeyPrefix = 'stev-';

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
