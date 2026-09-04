import 'package:nojob/shared/providers.dart';
import 'package:nojob/shared/scrapper/base_scrapper.dart';
import 'package:riverpod/src/framework.dart';

abstract interface class IScrapperRepo {
  Future<ScrapedVacancy?> fetchVacancy(String url);
}

class ScrapperRepo implements IScrapperRepo {
  final Ref _ref;
  late final cookies = _ref.read(cookieRepo);
  late final VacancyScrapper _scraper = _ref.read(vacancyScraper);

  ScrapperRepo(this._ref);

  @override
  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    return await _scraper.fetchVacancy(url);
  }
}
