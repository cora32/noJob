import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/features/home/data/job_repo.dart';
import 'package:nojob/features/home/domain/ijob_repo.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/providers.dart';
import 'package:nojob/shared/scrapper/base_scrapper.dart';
import 'package:nojob/shared/scrapper/scrapper_repo.dart';

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

class UrlFieldViewModel extends AsyncNotifier<UrlFieldState> {
  late final IScrapperRepo repo = ref.read(scrapperRepo);
  late final IJobRepo jRepo = ref.read(jobRepo);

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

    final result = await repo.fetchVacancy(url);

    if (result == null) {
      state = const AsyncData(UrlFieldError("Parse error"));
      return state.value!;
    }

    "[UrlFieldProvider] Fetch result: ${result.status}".e;

    if (result.status == ScrapeStatus.success) {
      final title = result.title;
      final description = result.companyName;
      await jRepo.addJob(
        title,
        description,
        url,
      );

      // Set state for current viewmodel
      state = const AsyncData(UrlFieldSuccess());

      // Notify other viewmodels
      ref.invalidate(logsViewModel);
      ref.invalidate(lineChartViewModel);
      ref.invalidate(homeViewModel);
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