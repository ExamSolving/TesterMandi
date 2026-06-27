import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color onPrimary = Colors.white;

  static const Color secondary = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryContainer = Color(0xFFCFFAFE);

  static const Color accent = Color(0xFF7C3AED);
  static const Color accentLight = Color(0xFFA78BFA);

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFF34D399);
  static const Color successContainer = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // ── Light Theme ────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textHintLight = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color dividerLight = Color(0xFFF3F4F6);
  static const Color iconLight = Color(0xFF374151);
  static const Color shimmerBaseLight = Color(0xFFE5E7EB);
  static const Color shimmerHighLight = Color(0xFFF9FAFB);

  // ── Dark Theme ─────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF08080F);
  static const Color surfaceDark = Color(0xFF111122);
  static const Color cardDark = Color(0xFF1A1A2E);
  static const Color cardDarkElevated = Color(0xFF1F1F35);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textHintDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF1E1E3A);
  static const Color dividerDark = Color(0xFF1A1A2E);
  static const Color iconDark = Color(0xFFCBD5E1);
  static const Color shimmerBaseDark = Color(0xFF1E1E3A);
  static const Color shimmerHighDark = Color(0xFF252540);

  // ── Gradients ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradientDark = LinearGradient(
    colors: [Color(0xFF08080F), Color(0xFF0F0F2E), Color(0xFF08080F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGradientLight = LinearGradient(
    colors: [Color(0xFFF5F7FF), Color(0xFFFFFFFF), Color(0xFFEEF2FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient developerCardGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient testerCardGradient = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadow Colors ──────────────────────────────────────
  static Color primaryShadow = primary.withValues(alpha: 0.3);
  static Color primaryShadowStrong = primary.withValues(alpha: 0.5);
  static Color darkShadow = Colors.black.withValues(alpha: 0.4);
  static Color lightShadow = const Color(0xFF4F46E5).withValues(alpha: 0.08);

  // ── Overlay Colors ─────────────────────────────────────
  static Color glassLight = Colors.white.withValues(alpha: 0.85);
  static Color glassDark = Colors.white.withValues(alpha: 0.04);
  static Color glassLightBorder = Colors.white.withValues(alpha: 0.6);
  static Color glassDarkBorder = Colors.white.withValues(alpha: 0.08);
  static Color scrimColor = Colors.black.withValues(alpha: 0.5);

  // ── Rating Stars ───────────────────────────────────────
  static const Color starFilled = Color(0xFFFBBF24);
  static const Color starEmpty = Color(0xFFD1D5DB);
}
