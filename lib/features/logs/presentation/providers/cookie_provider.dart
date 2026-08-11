import 'package:flutter_riverpod/flutter_riverpod.dart';

class CookieState {
  final Map<String, Map<String, String>> domainCookies;

  CookieState({required this.domainCookies});

  CookieState copyWith({Map<String, Map<String, String>>? domainCookies}) {
    return CookieState(domainCookies: domainCookies ?? this.domainCookies);
  }
}

class CookieNotifier extends Notifier<CookieState> {
  @override
  CookieState build() => CookieState(domainCookies: {});

  void updateCookies(String domain, Map<String, String> cookies) {
    state = state.copyWith(
      domainCookies: {...state.domainCookies, domain: cookies},
    );
  }

  Map<String, String>? getCookiesForUrl(String url) {
    final uri = Uri.parse(url);
    final host = uri.host;

    // Check for exact host or parent domains (e.g., il.indeed.com -> indeed.com)
    for (final domain in state.domainCookies.keys) {
      if (host.contains(domain)) {
        return state.domainCookies[domain];
      }
    }
    return null;
  }
}

final cookieProvider = NotifierProvider<CookieNotifier, CookieState>(
  CookieNotifier.new,
);
