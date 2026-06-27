import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/bindings/initial_binding.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';
import '../core/translations/app_translations.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

class TesterMandiApp extends StatelessWidget {
  const TesterMandiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TesterMandi',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _resolveThemeMode(),

      // ── Translations ───────────────────────────────────
      translations: AppTranslations(),
      locale: _resolveLocale(),
      fallbackLocale: const Locale('en', 'US'),

      // ── Navigation ─────────────────────────────────────
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),

      // ── Behaviour ──────────────────────────────────────
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
      routingCallback: (routing) {},
    );
  }

  ThemeMode _resolveThemeMode() {
    switch (StorageService().themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale _resolveLocale() {
    switch (StorageService().locale) {
      case 'hi':
        return const Locale('hi', 'IN');
      case 'es':
        return const Locale('es', 'ES');
      default:
        // Fall back to device language if no saved preference
        final saved = StorageService().locale;
        if (saved == 'en') {
          final deviceLang = Get.deviceLocale?.languageCode ?? 'en';
          if (deviceLang == 'hi') return const Locale('hi', 'IN');
          if (deviceLang == 'es') return const Locale('es', 'ES');
        }
        return const Locale('en', 'US');
    }
  }
}
