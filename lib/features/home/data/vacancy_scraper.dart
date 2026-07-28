import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scrapers/base_scrapper.dart';
import 'scrapers/glassdoor_scrapper.dart';
import 'scrapers/hh_scrapper.dart';
import 'scrapers/indeed_scrapper.dart';
import 'scrapers/linkedin_scrapper.dart';

export 'scrapers/base_scrapper.dart';

final vacancyScraperProvider = Provider(
      (ref) => CompositeVacancyScraper(),
);

class CompositeVacancyScraper extends VacancyScrapper {
  @override
  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    if (HHVacancyScraper.canHandle(url)) {
      return await HHVacancyScraper().fetchVacancy(url);
    }
    if (InVacancyScraper.canHandle(url)) {
      return await InVacancyScraper().fetchVacancy(url);
    }
    if (GlassdoorVacancyScraper.canHandle(url)) {
      return await GlassdoorVacancyScraper().fetchVacancy(url);
    }
    if (IndeedVacancyScraper.canHandle(url)) {
      return await IndeedVacancyScraper().fetchVacancy(url);
    }
    return null;
  }
}
