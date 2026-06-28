import 'package:http/http.dart' as http;

class AppDetails {
  const AppDetails({
    this.name,
    this.description,
    this.iconUrl,
    this.isPublic = false,
  });
  final String? name;
  final String? description;
  final String? iconUrl;

  /// True when details came from the public Play Store listing.
  final bool isPublic;

  bool get hasAnyData => name != null || iconUrl != null;
}

class PlayStoreService {
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept': 'text/html,application/xhtml+xml',
  };

  /// Fetches app details from the public Play Store listing only.
  /// Returns empty [AppDetails] if the app is not publicly listed (closed
  /// testing / not yet published). Caller is responsible for falling back to
  /// the device query in that case.
  static Future<AppDetails> fetchAppDetails(String packageName) async {
    final pkg = packageName.trim();
    if (pkg.isEmpty) return const AppDetails();

    try {
      final res = await http
          .get(
            Uri.parse(
                'https://play.google.com/store/apps/details?id=$pkg&hl=en'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) return const AppDetails();

      final body = res.body;
      return AppDetails(
        name: _extractName(body),
        description: _extractDescription(body),
        iconUrl: _extractIconUrl(body),
        isPublic: true,
      );
    } catch (_) {
      return const AppDetails();
    }
  }

  /// Convenience: icon URL only.
  static Future<String?> fetchIconUrl(String packageName) async {
    return (await fetchAppDetails(packageName)).iconUrl;
  }

  // ── Extractors ─────────────────────────────────────────────────────────────

  static String? _extractName(String body) {
    final ogTitle = RegExp(
            r'<meta[^>]+property="og:title"[^>]+content="([^"]+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (ogTitle != null) return _stripSuffix(ogTitle);

    final titleTag =
        RegExp(r'<title>([^<]+)</title>').firstMatch(body)?.group(1);
    if (titleTag != null) return _stripSuffix(titleTag);

    final jsonLd = RegExp(r'"name"\s*:\s*"((?:[^"\\]|\\.)+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (jsonLd != null) return _decodeHtml(jsonLd);

    return null;
  }

  static String? _extractDescription(String body) {
    final ogDesc = RegExp(
            r'<meta[^>]+property="og:description"[^>]+content="([^"]+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (ogDesc != null) return _decodeHtml(ogDesc);

    final metaDesc = RegExp(
            r'<meta[^>]+name="description"[^>]+content="([^"]+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (metaDesc != null) return _decodeHtml(metaDesc);

    final jsonLd = RegExp(r'"description"\s*:\s*"((?:[^"\\]|\\.)+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (jsonLd != null) return _decodeHtml(jsonLd);

    return null;
  }

  static String? _extractIconUrl(String body) {
    final jsonLdIcon = RegExp(
      r'"image"\s*:\s*"(https://play-lh\.googleusercontent\.com/[^"]+)"',
    ).firstMatch(body)?.group(1);
    if (jsonLdIcon != null) return _cleanIconUrl(jsonLdIcon);

    final ogImage = RegExp(
      r'<meta[^>]+property="og:image"[^>]+content="([^"]+)"',
    ).firstMatch(body)?.group(1);
    if (ogImage != null) return _cleanIconUrl(ogImage);

    final itemProp = RegExp(
      r'<img[^>]+itemprop="image"[^>]+src="(https://play-lh\.googleusercontent\.com/[^"]+)"',
    ).firstMatch(body)?.group(1);
    if (itemProp != null) return _cleanIconUrl(itemProp);

    return null;
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static String _stripSuffix(String title) {
    return title
        .replaceAll(' - Apps on Google Play', '')
        .replaceAll(' – Apps on Google Play', '')
        .replaceAll(' - Google Play', '')
        .replaceAll(' – Google Play', '')
        .trim();
  }

  static String _decodeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(r'\n', '\n')
        .trim();
  }

  static String _cleanIconUrl(String url) {
    return url.replaceAll(RegExp(r'=[^=]*$'), '=s256-rw');
  }
}
