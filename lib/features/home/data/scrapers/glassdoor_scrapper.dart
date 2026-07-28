import 'package:NoJob/shared/extensions.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

import 'base_scrapper.dart';

class GlassdoorVacancyScraper extends VacancyScrapper {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static bool canHandle(String url) =>
      url.toLowerCase().contains('glassdoor.com');

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
        'Referer': 'https://www.glassdoor.com/',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
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
        "Glassdoor Status: ${response.statusCode}".e;
        return ScrapedVacancy.error();
      }

      final document = parse(response.body);

      // Using fuzzy selectors for classes to handle dynamic suffixes
      final titleElement =
          document.querySelector('h1[id^="jd-job-title-"]') ??
          document.querySelector('h1[class*="heading_Level1"]') ??
          document.querySelector('h1[class*="job-title"]');

      final companyElement =
          document.querySelector('h4[class*="heading_Subhead"]') ??
          document.querySelector('div[class*="employerNameHeading"] h4') ??
          document.querySelector(
            'div[class*="EmployerProfile_employerInfo"] h4',
          ) ??
          document.querySelector('[data-test="employer-name"]');

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
