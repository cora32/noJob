import 'package:NoJob/shared/extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

abstract class VacancyScrapper {
  Future<ScrapedVacancy?> fetchVacancy(String url);

  bool canHandle(String url);
}

final vacancyScraperProvider = Provider(
  (ref) => CompositeVacancyScraper([HHVacancyScraper(), InVacancyScraper()]),
);

class ScrapedVacancy {
  final String title;
  final String companyName;

  ScrapedVacancy({required this.title, required this.companyName});
}

class CompositeVacancyScraper extends VacancyScrapper {
  final List<VacancyScrapper> scrapers;

  CompositeVacancyScraper(this.scrapers);

  @override
  bool canHandle(String url) => scrapers.any((s) => s.canHandle(url));

  @override
  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    for (final scraper in scrapers) {
      if (scraper.canHandle(url)) {
        return await scraper.fetchVacancy(url);
      }
    }
    return null;
  }
}

///*
/// For HH
///*///
class HHVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  @override
  bool canHandle(String url) => url.toLowerCase().contains('hh.ru');

  @override
  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8',
        },
      );

      if (response.statusCode != 200) return null;

      final document = parse(response.body);

      final titleElement = document.querySelector(
        'h1[data-qa="vacancy-title"]',
      );
      final companyElement = document.querySelector(
        'a[data-qa="vacancy-company-name"]',
      );

      "titleElement: ${titleElement?.text.trim()}; companyElement: ${companyElement?.text.trim()}"
          .e;

      if (titleElement == null && companyElement == null) return null;

      return ScrapedVacancy(
        title: titleElement?.text.trim() ?? '',
        companyName: companyElement?.text.trim() ?? '',
      );
    } catch (e) {
      return null;
    }
  }
}

///*
/// For LinkedIn
///*///
class InVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  @override
  bool canHandle(String url) => url.toLowerCase().contains('linkedin.com');

  @override
  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response.statusCode != 200) return null;

      final document = parse(response.body);

      // Try multiple selectors as LinkedIn often changes them
      final titleElement =
          document.querySelector('h1.top-card-layout__title') ??
          document.querySelector('h1.topcard__title');

      final companyElement = document.querySelector('a.topcard__org-name-link');

      "titleElement: ${titleElement?.text.trim()}; companyElement: ${companyElement?.text.trim()}"
          .e;

      if (titleElement == null && companyElement == null) return null;

      return ScrapedVacancy(
        title: titleElement?.text.trim() ?? '',
        companyName: companyElement?.text.trim() ?? '',
      );
    } catch (e) {
      return null;
    }
  }
}
