import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nojob/shared/providers.dart';
import 'package:nojob/shared/scrapper/base_scrapper.dart';

abstract class BaseLogViewModel<T> extends AsyncNotifier<T> {
  late final repo = ref.read(jobRepo);
  late final scRepo = ref.read(scrapperRepo);

  Future<void> onRemove(int id) async {
    await repo.deleteJob(id);

    ref.invalidateSelf();
    ref.invalidate(lineChartViewModel);
    ref.invalidate(homeViewModel);
  }

  Future<void> updateStatus(int id, String status) async {
    await repo.updateJobStatus(id, status);

    ref.invalidateSelf();
    ref.invalidate(lineChartViewModel);
    ref.invalidate(homeViewModel);
  }

  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    return await scRepo.fetchVacancy(url);
  }

  Future<void> addJob(String title, String description, String link) async {
    await repo.addJob(title, description, link);

    ref.invalidateSelf();
    ref.invalidate(lineChartViewModel);
    ref.invalidate(homeViewModel);
  }
}
