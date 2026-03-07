import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorageService {
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _homeAddressKey = 'user_home_address';
  static const String _workSchoolAddressKey = 'user_work_school_address';

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  static Future<void> completeOnboarding({
    required String homeAddress,
    String? workSchoolAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    await prefs.setString(_homeAddressKey, homeAddress.trim());

    final cleanedWorkSchool = workSchoolAddress?.trim();
    if (cleanedWorkSchool != null && cleanedWorkSchool.isNotEmpty) {
      await prefs.setString(_workSchoolAddressKey, cleanedWorkSchool);
    } else {
      await prefs.remove(_workSchoolAddressKey);
    }
  }

  static Future<String?> getHomeAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_homeAddressKey);
  }

  static Future<String?> getWorkSchoolAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_workSchoolAddressKey);
  }

  static Future<void> updateAddresses({
    required String homeAddress,
    String? workSchoolAddress,
  }) async {
    await completeOnboarding(
      homeAddress: homeAddress,
      workSchoolAddress: workSchoolAddress,
    );
  }
}
