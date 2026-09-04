import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class ICookieRepo {
  void updateCookies(String domain, Map<String, String> cookies);

  Map<String, String>? getCookiesForUrl(String url);
}

class CookieRepo extends ICookieRepo {
  final Ref _ref;
  final Map<String, Map<String, String>> domainCookies = {};

  CookieRepo({required this._ref});

  @override
  Map<String, String>? getCookiesForUrl(String url) {
    final uri = Uri.parse(url);
    final host = uri.host;

    // Check for exact host or parent domains (e.g., il.indeed.com -> indeed.com)
    for (final domain in domainCookies.keys) {
      if (host.contains(domain)) {
        return domainCookies[domain];
      }
    }

    return null;
  }

  @override
  void updateCookies(String domain, Map<String, String> cookies) {
    domainCookies[domain] = cookies;
  }
}
