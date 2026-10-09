import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingPreferences {
  static const completeKey = 'stev-onboarding-complete';
  static const nameKey = 'stev-user-name';
  static const drinkTimeKey = 'stev-drink-time';

  static Future<bool> isComplete() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completeKey) ?? false;
  }

  static Future<void> complete({String? name, String? drinkTime}) async {
    final preferences = await SharedPreferences.getInstance();
    final trimmedName = name?.trim() ?? '';

    if (trimmedName.isNotEmpty) {
      await preferences.setString(nameKey, trimmedName);
    }
    if (drinkTime != null) {
      await preferences.setString(drinkTimeKey, drinkTime);
    }
    await preferences.setBool(completeKey, true);
  }
}
