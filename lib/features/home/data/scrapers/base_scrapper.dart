abstract class VacancyScrapper {
  Future<ScrapedVacancy?> fetchVacancy(String url);
}

class ScrapedVacancy {
  final String title;
  final String companyName;

  ScrapedVacancy({required this.title, required this.companyName});
}
