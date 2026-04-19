import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static const _keyThemeMode = 'theme_mode';
  static const _keyUserData = 'user_data';
  static const _keyOnboarding = 'onboarding_done';
  static const _keyFcmToken = 'fcm_token';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // Theme
  static Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  static Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  // User Data (non-sensitive)
  static Future<void> saveUserData(String json) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserData, json);
  }

  static Future<String?> getUserData() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserData);
  }

  // Onboarding
  static Future<void> setOnboardingDone() async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboarding, true);
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboarding) ?? false;
  }

  // FCM Token
  static Future<void> saveFcmToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyFcmToken, token);
  }

  static Future<String?> getFcmToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyFcmToken);
  }

  static Future<void> clearUserData() async {
    final prefs = await _prefs;
    await prefs.remove(_keyUserData);
  }
}
