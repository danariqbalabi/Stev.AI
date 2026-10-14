import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProfile {
  const OnboardingProfile({this.name, this.drinkTime});

  final String? name;
  final String? drinkTime;

  bool get hasDetails => name != null || drinkTime != null;
}

abstract final class OnboardingPreferences {
  static const completeKey = 'stev-onboarding-complete';
  static const nameKey = 'stev-user-name';
  static const drinkTimeKey = 'stev-drink-time';

  static Future<bool> isComplete() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completeKey) ?? false;
  }

  static Future<OnboardingProfile> readProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final storedName = preferences.getString(nameKey)?.trim();
    final storedDrinkTime = preferences.getString(drinkTimeKey);
    return OnboardingProfile(
      name: storedName == null || storedName.isEmpty ? null : storedName,
      drinkTime: _validDrinkTimes.contains(storedDrinkTime)
          ? storedDrinkTime
          : null,
    );
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

  static const _validDrinkTimes = {'Pagi', 'Siang', 'Sore', 'Malam'};
}
