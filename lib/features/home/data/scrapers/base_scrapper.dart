enum ScrapeStatus { success, error, verificationRequired }

class ScrapedVacancy {
  final String title;
  final String companyName;
  final ScrapeStatus status;

  ScrapedVacancy({
    required this.title,
    required this.companyName,
    this.status = ScrapeStatus.success,
  });

  factory ScrapedVacancy.error() =>
      ScrapedVacancy(title: '', companyName: '', status: ScrapeStatus.error);

  factory ScrapedVacancy.verificationRequired() => ScrapedVacancy(
    title: '',
    companyName: '',
    status: ScrapeStatus.verificationRequired,
  );
}

abstract class VacancyScrapper {
  Future<ScrapedVacancy?> fetchVacancy(
    String url, {
    Map<String, String>? cookies,
  });
}
