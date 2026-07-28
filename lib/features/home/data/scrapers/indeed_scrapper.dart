import 'package:NoJob/shared/extensions.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import 'base_scrapper.dart';

class IndeedVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool canHandle(String url) => url.toLowerCase().contains('indeed.com');

  @override
  Future<ScrapedVacancy?> fetchVacancy(
    String url, {
    Map<String, String>? cookies,
  }) async try {
      final headers = {
        'User-Agent': _userAgent,
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Referer': 'https://www.indeed.com/',
      };

      if (cookies != null && cookies.isNotEmpty) {
        headers['Cookie'] =
            cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 403) {
        return ScrapedVacancy.verificationRequired();
      }

      if (response.statusCode != 200) {
        "Indeed Status: ${response.statusCode}".e;
        return ScrapedVacancy.error();
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

      if (titleElement == null && companyElement == null)
        return ScrapedVacancy.error();

      return ScrapedVacancy(
        title: titleElement?.text.trim() ?? '',
        companyName: companyElement?.text.trim() ?? '',
      );
    } catch (e) {
      return ScrapedVacancy.error();
    }
  }
}
