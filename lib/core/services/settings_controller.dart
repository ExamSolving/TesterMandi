import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class SettingsController extends GetxService {
  SettingsController(this._storage);
  final StorageService _storage;

  final themeMode = 'system'.obs;
  final locale = 'en'.obs;
  final notificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _storage.themeMode;
    locale.value = _storage.locale;
    notificationsEnabled.value = _storage.notificationsEnabled;
    _applyTheme(themeMode.value);
  }

  // ── Theme ──────────────────────────────────────────────

  void setTheme(String mode) {
    themeMode.value = mode;
    _storage.saveThemeMode(mode);
    _applyTheme(mode);
  }

  void _applyTheme(String mode) {
    switch (mode) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
      default:
        Get.changeThemeMode(ThemeMode.system);
    }
  }

  // ── Language ───────────────────────────────────────────

  void setLocale(String code) {
    locale.value = code;
    _storage.saveLocale(code);
    switch (code) {
      case 'hi':
        Get.updateLocale(const Locale('hi', 'IN'));
      case 'es':
        Get.updateLocale(const Locale('es', 'ES'));
      default:
        Get.updateLocale(const Locale('en', 'US'));
    }
  }

  // ── Notifications ──────────────────────────────────────

  void toggleNotifications() {
    notificationsEnabled.value = !notificationsEnabled.value;
    _storage.saveNotificationsEnabled(notificationsEnabled.value);
  }

  // ── Helpers ────────────────────────────────────────────

  ThemeMode get currentThemeMode {
    switch (themeMode.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get currentLocale {
    switch (locale.value) {
      case 'hi':
        return const Locale('hi', 'IN');
      case 'es':
        return const Locale('es', 'ES');
      default:
        return const Locale('en', 'US');
    }
  }
}
