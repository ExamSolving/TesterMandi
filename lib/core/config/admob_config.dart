import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
// AdMob configuration — ONE place to control every ad in the app.
//
// ┌─────────────────────────────────────────────────────────────────────┐
// │  QUICK CONTROL                                                      │
// │  • Disable an entire format → flip enableBannerAds / etc. to false │
// │  • Disable one spot         → flip the matching showXxx flag        │
// └─────────────────────────────────────────────────────────────────────┘
//
// TESTING (current):  Google's official test IDs — safe on any device.
// PRODUCTION (later): Replace every value marked [REPLACE_PROD] below.
//   Steps:
//     1. Create an AdMob account → add your Android + iOS apps.
//     2. Create ad units: Banner · Interstitial · App Open.
//     3. Replace the IDs in the "Ad Unit IDs" section.
//     4. Also update the App ID strings in:
//          android/app/src/main/AndroidManifest.xml
//          ios/Runner/Info.plist
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies which screen/position a banner ad occupies.
/// Used by [AdmobConfig.isBannerEnabled] and [BannerAdWidget].
enum BannerPlacement {
  browseTab,
  dashboardTab,
  profileTab,
  notifications,
  submitProof,
}

abstract final class AdmobConfig {
  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1 — MASTER SWITCHES
  // Set to false to instantly kill an entire ad format across the whole app.
  // ═══════════════════════════════════════════════════════════════════════════

  static const bool enableBannerAds = true; // all banner placements
  static const bool enableInterstitialAds = false; // all interstitial triggers
  static const bool enableAppOpenAds = false; // app-open on resume

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2 — PER-PLACEMENT BANNER FLAGS
  // Only evaluated when enableBannerAds = true.
  // Set a flag to false to hide the banner at that one spot.
  // ═══════════════════════════════════════════════════════════════════════════

  static const bool showBannerInBrowseTab =
      true; // Browse tab list (after 3rd item)
  static const bool showBannerInDashboardTab =
      true; // Dashboard (between proof sections)
  static const bool showBannerInProfileTab = true; // Profile (below stats row)
  static const bool showBannerInNotifications =
      true; // Notifications screen (top of list)
  static const bool showBannerInSubmitProof =
      true; // Submit Proof screen (above button)

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3 — PER-TRIGGER INTERSTITIAL FLAGS
  // Only evaluated when enableInterstitialAds = true.
  // ═══════════════════════════════════════════════════════════════════════════

  static const bool showInterstitialOnProofSubmit =
      false; // after proof submitted
  static const bool showInterstitialOnAppPosted =
      false; // after app posted (CTA tap)

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4 — AD UNIT IDs
  // ═══════════════════════════════════════════════════════════════════════════

  // ── App IDs ──────────────────────────────────────────────────────────────
  // [REPLACE_PROD] Your AdMob App IDs (one per platform)
  static const String _androidAppId =
      'ca-app-pub-3940256099942544~3347511713'; // TEST
  static const String _iosAppId =
      'ca-app-pub-3940256099942544~1458002511'; // TEST

  static String get appId => Platform.isIOS ? _iosAppId : _androidAppId;

  // ── Banner ────────────────────────────────────────────────────────────────
  // [REPLACE_PROD] ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111'; // TEST
  static const String _iosBannerId =
      'ca-app-pub-3940256099942544/2934735716'; // TEST

  static String get bannerId =>
      Platform.isIOS ? _iosBannerId : _androidBannerId;

  // ── Interstitial ──────────────────────────────────────────────────────────
  // [REPLACE_PROD] ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712'; // TEST
  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910'; // TEST

  static String get interstitialId =>
      Platform.isIOS ? _iosInterstitialId : _androidInterstitialId;

  // ── App Open ──────────────────────────────────────────────────────────────
  // [REPLACE_PROD] ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
  static const String _androidAppOpenId =
      'ca-app-pub-3940256099942544/9257395921'; // TEST
  static const String _iosAppOpenId =
      'ca-app-pub-3940256099942544/5575463023'; // TEST

  static String get appOpenId =>
      Platform.isIOS ? _iosAppOpenId : _androidAppOpenId;

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5 — HELPERS (used internally, not meant to be changed)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns true when the banner at [placement] should load and display.
  /// Checks the master switch first, then the placement-level flag.
  static bool isBannerEnabled(BannerPlacement placement) {
    if (!enableBannerAds) return false;
    switch (placement) {
      case BannerPlacement.browseTab:
        return showBannerInBrowseTab;
      case BannerPlacement.dashboardTab:
        return showBannerInDashboardTab;
      case BannerPlacement.profileTab:
        return showBannerInProfileTab;
      case BannerPlacement.notifications:
        return showBannerInNotifications;
      case BannerPlacement.submitProof:
        return showBannerInSubmitProof;
    }
  }
}
