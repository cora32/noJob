import 'dart:async';

import 'package:NoJob/features/home/data/scrapers/base_scrapper.dart';
import 'package:NoJob/features/home/presentation/providers/home_provider.dart';
import 'package:NoJob/features/logs/presentation/providers/log_provider.dart';
import 'package:NoJob/shared/extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class UrlFieldState {
  const UrlFieldState();
}

class UrlFieldIdle extends UrlFieldState {
  const UrlFieldIdle();
}

class UrlFieldLoading extends UrlFieldState {
  const UrlFieldLoading();
}

class UrlFieldSuccess extends UrlFieldState {
  const UrlFieldSuccess();
}

class UrlFieldError extends UrlFieldState {
  final String errorMessage;

  const UrlFieldError(this.errorMessage);
}

class VerificationRequired extends UrlFieldState {
  const VerificationRequired();
}

class UrlFieldNotifier extends AsyncNotifier<UrlFieldState> {
  @override
  FutureOr<UrlFieldState> build() {
    return const UrlFieldIdle();
  }

  bool validateUrl(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    final isWeb =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isWeb) return false;

    return SupportedSite.fromLink(url) != SupportedSite.unknown;
  }

  Future<UrlFieldState> parse(String url) async {
    state = const AsyncData(UrlFieldLoading());

    if (!validateUrl(url)) {
      state = const AsyncData(UrlFieldError("Invalid URL"));
      return state.value!;
    }

    final logNotifier = ref.read(logsProvider.notifier);
    final result = await logNotifier.fetchVacancy(url);

    if (result == null) {
      state = const AsyncData(UrlFieldError("Parse error"));
      return state.value!;
    }

    "[UrlFieldProvider] Fetch result: ${result.status}".e;

    if (result.status == ScrapeStatus.success) {
      final title = result.title;
      final description = result.companyName;
      logNotifier.addJob(title, description, url);

      state = const AsyncData(UrlFieldSuccess());
    } else if (result.status == ScrapeStatus.verificationRequired) {
      state = const AsyncData(VerificationRequired());
    } else {
      state = const AsyncData(UrlFieldError("Failed to fetch vacancy"));
    }

    return state.value!;
  }

  void reset() {
    state = const AsyncData(UrlFieldIdle());
  }
}

final urlFieldProvider = AsyncNotifierProvider<UrlFieldNotifier, UrlFieldState>(
  UrlFieldNotifier.new,
);
