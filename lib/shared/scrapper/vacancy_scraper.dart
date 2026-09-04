import 'base_scrapper.dart';
import 'glassdoor_scrapper.dart';
import 'hh_scrapper.dart';
import 'indeed_scrapper.dart';
import 'linkedin_scrapper.dart';

export 'base_scrapper.dart';

class CompositeVacancyScraper extends VacancyScrapper {
  @override
  Future<ScrapedVacancy?> fetchVacancy(String url,
      {Map<String, String>? cookies}) async {
    if (HHVacancyScraper.canHandle(url)) {
      return await HHVacancyScraper().fetchVacancy(url, cookies: cookies);
    }
    if (InVacancyScraper.canHandle(url)) {
      return await InVacancyScraper().fetchVacancy(url, cookies: cookies);
    }
    if (GlassdoorVacancyScraper.canHandle(url)) {
      return await GlassdoorVacancyScraper().fetchVacancy(
          url, cookies: cookies);
    }
    if (IndeedVacancyScraper.canHandle(url)) {
      return await IndeedVacancyScraper().fetchVacancy(url, cookies: cookies);
    }
    return null;
  }
}
