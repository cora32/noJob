import 'package:NoJob/shared/extensions.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import 'base_scrapper.dart';

class InVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool canHandle(String url) =>
      url.toLowerCase().contains('linkedin.com');

  @override
  Future<ScrapedVacancy?> fetchVacancy(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept-Language': 'en-US,en;q=0.9',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        "LinkedIn Status: ${response.statusCode}".e;
        return null;
      }

      final document = parse(response.body);

      // Try multiple selectors as LinkedIn often changes them
      final titleElement =
          document.querySelector('h1.top-card-layout__title') ??
          document.querySelector('h1.topcard__title') ??
          document.querySelector('h1[class*="topcard__title"]');

      final companyElement =
          document.querySelector('a.topcard__org-name-link') ??
          document.querySelector('a[class*="topcard__org-name-link"]');

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
