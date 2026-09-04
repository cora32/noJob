import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/logs/data/cookie_repo.dart';
import 'package:nojob/shared/providers.dart';

class CookieState {
  final Map<String, Map<String, String>> domainCookies;

  CookieState({required this.domainCookies});

  CookieState copyWith({Map<String, Map<String, String>>? domainCookies}) {
    return CookieState(domainCookies: domainCookies ?? this.domainCookies);
  }
}

class CookieViewModel extends Notifier<CookieState> {
  late ICookieRepo repo = ref.read(cookieRepo);

  @override
  CookieState build() => CookieState(domainCookies: {});

  void updateCookies(String domain, Map<String, String> cookies) {
    repo.updateCookies(domain, cookies);

    state = state.copyWith(
      domainCookies: {...state.domainCookies, domain: cookies},
    );
  }
}