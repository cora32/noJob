import 'package:NoJob/shared/extensions.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import 'base_scrapper.dart';

class HHVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool canHandle(String url) => url.toLowerCase().contains('hh.ru');

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

      if (response.statusCode != 200) {
        "HH Status: ${response.statusCode}".e;
        return null;
      }

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
