import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Theme ──────────────────────────────────────────────
  static const _themeKey = 'theme_mode';

  String get themeMode => _prefs.getString(_themeKey) ?? 'system';
  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  // ── Locale ─────────────────────────────────────────────
  static const _localeKey = 'locale';

  String get locale => _prefs.getString(_localeKey) ?? 'en';
  Future<void> saveLocale(String code) => _prefs.setString(_localeKey, code);

  // ── Notifications ──────────────────────────────────────
  static const _notificationsKey = 'notifications_enabled';

  bool get notificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;
  Future<void> saveNotificationsEnabled(bool value) =>
      _prefs.setBool(_notificationsKey, value);

  // ── User ───────────────────────────────────────────────
  String? get cachedUserId => _prefs.getString(AppConstants.cachedUserId);
  Future<void> saveCachedUserId(String uid) =>
      _prefs.setString(AppConstants.cachedUserId, uid);

  String? get cachedUserRole => _prefs.getString(AppConstants.cachedUserRole);
  Future<void> saveCachedUserRole(String role) =>
      _prefs.setString(AppConstants.cachedUserRole, role);

  bool get onboardingDone => _prefs.getBool(AppConstants.onboardingDone) ?? false;
  Future<void> setOnboardingDone() =>
      _prefs.setBool(AppConstants.onboardingDone, true);

  Future<void> clearUserSession() async {
    await _prefs.remove(AppConstants.cachedUserId);
    await _prefs.remove(AppConstants.cachedUserRole);
  }
}
