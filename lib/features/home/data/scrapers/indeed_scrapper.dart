import 'package:NoJob/shared/extensions.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import 'base_scrapper.dart';

class IndeedVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool canHandle(String url) => url.toLowerCase().contains('indeed.com');

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
          'Referer': 'https://www.indeed.com/',
        },
      );

      if (response.statusCode != 200) {
        "Indeed Status: ${response.statusCode}".e;
        if (response.body.length > 200) {
          "Indeed Body Snippet: ${response.body.substring(0, 200)}".e;
        }
        return null;
      }

      final document = parse(response.body);

      final titleElement = document.querySelector(
        'h1[data-testid="jobsearch-JobInfoHeader-title"]',
      );
      final companyElement =
          document.querySelector(
            'div[data-testid="inlineHeader-companyName"] a',
          ) ??
          document.querySelector('[data-company-name="true"]');

      "Indeed titleElement: ${titleElement?.text.trim()}; companyElement: ${companyElement?.text.trim()}"
          .e;

      if (titleElement == null && companyElement == null) return null;

      return ScrapedVacancy(
        title: titleElement?.text.trim() ?? '',
        companyName: companyElement?.text.trim() ?? '',
      );
    } catch (e) {
      "Indeed Scrape Error: $e".e;
      return null;
    }
  }
}
