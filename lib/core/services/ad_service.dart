import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/admob_config.dart';

/// Manages interstitial and app-open ads for TesterMandi.
///
/// Registered as a permanent GetX service in [InitialBinding].
/// Automatically preloads both ad types on startup and reloads after each show.
///
/// App-open ads fire on app resume (foreground). A 30-second cooldown prevents
/// back-to-back full-screen ads (e.g. interstitial → app open on dismiss).
class AdService extends GetxService with WidgetsBindingObserver {
  static AdService get to => Get.find();

  // ── State ─────────────────────────────────────────────────────────────────

  InterstitialAd? _interstitial;
  AppOpenAd? _appOpenAd;

  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;

  /// True while ANY full-screen ad (interstitial or app-open) is on screen.
  bool _isShowingFullScreenAd = false;

  DateTime? _appOpenLoadTime;

  /// Tracks when the last full-screen ad was dismissed so we can enforce a
  /// cooldown before showing the next one.
  DateTime? _lastFullScreenAdDismissedAt;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    if (AdmobConfig.enableInterstitialAds) _loadInterstitial();
    if (AdmobConfig.enableAppOpenAds) _loadAppOpenAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Respect cooldown — don't stack ads back-to-back.
    final last = _lastFullScreenAdDismissedAt;
    if (last != null &&
        DateTime.now().difference(last).inSeconds < 30) {
      return;
    }

    showAppOpenAd();
  }

  // ── Interstitial ─────────────────────────────────────────────────────────

  void _loadInterstitial() {
    if (!AdmobConfig.enableInterstitialAds) return;
    if (_isInterstitialLoading || _interstitial != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AdmobConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _isInterstitialLoading = false;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial load failed: ${error.message}');
        },
      ),
    );
  }

  /// Shows the preloaded interstitial ad. If none is ready, one is queued for
  /// the next call. Safe to call at any time — silently no-ops when unavailable
  /// or when [AdmobConfig.enableInterstitialAds] is false.
  Future<void> showInterstitial() async {
    if (!AdmobConfig.enableInterstitialAds) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
        debugPrint('[AdService] Interstitial show failed: ${error.message}');
      },
    );

    await ad.show();
  }

  // ── App Open ──────────────────────────────────────────────────────────────

  bool get _isAdAvailable {
    if (_appOpenAd == null || _appOpenLoadTime == null) return false;
    // App-open ads expire after 4 hours.
    return DateTime.now().difference(_appOpenLoadTime!).inHours < 4;
  }

  void _loadAppOpenAd() {
    if (!AdmobConfig.enableAppOpenAds) return;
    if (_isAppOpenLoading || _appOpenAd != null) return;
    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: AdmobConfig.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isAppOpenLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isAppOpenLoading = false;
          debugPrint('[AdService] AppOpen load failed: ${error.message}');
        },
      ),
    );
  }

  /// Shows the app-open ad. Called automatically on app resume via lifecycle.
  /// Guards against showing during other full-screen ads and enforces cooldown.
  /// No-ops when [AdmobConfig.enableAppOpenAds] is false.
  void showAppOpenAd() {
    if (!AdmobConfig.enableAppOpenAds) return;
    if (_isShowingFullScreenAd || !_isAdAvailable) {
      if (!_isAdAvailable && !_isAppOpenLoading) _loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => _isShowingFullScreenAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreenAd = false;
        _lastFullScreenAdDismissedAt = DateTime.now();
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreenAd = false;
        ad.dispose();
        _appOpenAd = null;
        _loadAppOpenAd();
        debugPrint('[AdService] AppOpen show failed: ${error.message}');
      },
    );

    _appOpenAd!.show();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitial?.dispose();
    _appOpenAd?.dispose();
    super.onClose();
  }
}
