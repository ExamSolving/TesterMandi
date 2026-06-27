import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/admob_config.dart';
import '../constants/app_colors.dart';

/// Reusable AdMob banner (320×50).
///
/// Pass [placement] to identify which screen this banner belongs to — the widget
/// automatically checks [AdmobConfig.isBannerEnabled] and renders nothing if the
/// master switch or the placement-specific flag is off.
///
/// Also renders nothing while the ad is loading or if the request fails, so it
/// never reserves blank space in the layout.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    required this.placement,
    this.margin,
  });

  /// Which screen/position this banner occupies. Controls the per-placement flag.
  final BannerPlacement placement;

  /// Defaults to symmetric 16 horizontal + 8 vertical if not provided.
  final EdgeInsets? margin;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Skip loading entirely when the placement (or master switch) is disabled.
    if (AdmobConfig.isBannerEnabled(widget.placement)) {
      _loadAd();
    }
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AdmobConfig.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[BannerAd] Failed to load: ${error.message}');
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
