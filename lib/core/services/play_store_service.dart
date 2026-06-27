import 'dart:convert' show utf8;
import 'dart:io' show HttpClient, HttpHeaders;

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
  /// False when they came from the closed-testing opt-in page.
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

  /// Tries the public listing first, then the closed-testing opt-in page.
  /// Description is only populated from the public listing.
  static Future<AppDetails> fetchAppDetails(String packageName) async {
    final pkg = packageName.trim();
    if (pkg.isEmpty) return const AppDetails();

    // 1. Public listing.
    final body = await _getBody(
      Uri.parse('https://play.google.com/store/apps/details?id=$pkg&hl=en'),
    );
    if (body != null) {
      final name = _extractName(body);
      final iconUrl = _extractIconUrl(body);
      if (name != null || iconUrl != null) {
        return AppDetails(
          name: name,
          description: _extractDescription(body),
          iconUrl: iconUrl,
          isPublic: true,
        );
      }
    }

    // 2. Closed-testing opt-in page — uses no-redirect HttpClient so we detect
    //    the auth 302 via Location header (body-content checks are unreliable
    //    because every Google page embeds accounts.google.com in its JS).
    final testBody = await _getTestingBody(pkg);
    if (testBody != null) {
      final name = _extractNameFromTesting(testBody);
      final iconUrl = _extractIconFromTesting(testBody);
      if (name != null || iconUrl != null) {
        return AppDetails(name: name, iconUrl: iconUrl, isPublic: false);
      }
    }

    // 3. APKCombo — public mirror that indexes Play Store apps including
    //    beta/testing tracks without requiring authentication.
    final comboBody = await _getBody(
      Uri.parse('https://apkcombo.com/apk/$pkg/'),
    );
    if (comboBody != null) {
      final name = _extractName(comboBody);
      final iconUrl =
          _extractIconUrl(comboBody) ?? _extractIconFromTesting(comboBody);
      if (name != null || iconUrl != null) {
        return AppDetails(name: name, iconUrl: iconUrl, isPublic: false);
      }
    }

    return const AppDetails();
  }

  /// Convenience: icon URL only.
  static Future<String?> fetchIconUrl(String packageName) async {
    return (await fetchAppDetails(packageName)).iconUrl;
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────

  /// Standard GET that follows redirects (fine for the public listing).
  static Future<String?> _getBody(Uri uri) async {
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      return res.statusCode == 200 ? res.body : null;
    } catch (_) {
      return null;
    }
  }

  /// GET that manually follows redirects and aborts if any redirect leads to
  /// accounts.google.com (auth wall). Returns the body only on a real 200.
  static Future<String?> _getTestingBody(String pkg) async {
    var uri = Uri.parse('https://play.google.com/apps/testing/$pkg');
    final client = HttpClient();
    try {
      for (var hop = 0; hop < 5; hop++) {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        _headers.forEach((k, v) => request.headers.set(k, v));
        final response =
            await request.close().timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          return await response.transform(utf8.decoder).join();
        }

        if (response.statusCode >= 301 && response.statusCode <= 308) {
          final location =
              response.headers.value(HttpHeaders.locationHeader) ?? '';
          // Auth wall — give up.
          if (location.contains('accounts.google.com')) return null;
          // Other redirect (e.g. http→https) — follow it.
          uri = uri.resolve(location);
          continue;
        }

        // 404 or any other non-2xx/3xx.
        return null;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  // ── Public-listing extractors ─────────────────────────────────────────────

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

  // ── Closed-testing page extractors ───────────────────────────────────────

  static String? _extractNameFromTesting(String body) {
    final og = RegExp(
            r'<meta[^>]+property="og:title"[^>]+content="([^"]+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (og != null) return _stripSuffix(og);

    final title =
        RegExp(r'<title>([^<]+)</title>').firstMatch(body)?.group(1);
    if (title != null) return _stripSuffix(title);

    return null;
  }

  static String? _extractIconFromTesting(String body) {
    final og = RegExp(
            r'<meta[^>]+property="og:image"[^>]+content="([^"]+)"',
            caseSensitive: false)
        .firstMatch(body)
        ?.group(1);
    if (og != null) return _cleanIconUrl(og);

    final src = RegExp(
      r'src="(https://play-lh\.googleusercontent\.com/[^"]+)"',
    ).firstMatch(body)?.group(1);
    if (src != null) return _cleanIconUrl(src);

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
