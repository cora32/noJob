import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/cookie_provider.dart';

class VerificationDialog extends ConsumerStatefulWidget {
  final String url;

  const VerificationDialog({super.key, required this.url});

  @override
  ConsumerState<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends ConsumerState<VerificationDialog> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  CookieManager cookieManager = CookieManager.instance();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Verification Required",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  onPressed: () => _completeVerification(webViewController),
                  child: const Text("Done"),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Please complete the security check. If you see the job details, click 'Done'.",
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStop: (controller, url) async {
                if (url == null) return;

                // Check for common job site indicators
                final result = await controller.evaluateJavascript(
                  source: """
                  (function() {
                    return !!(
                      document.querySelector('h1[data-qa="vacancy-title"]') ||
                      document.querySelector('h1.top-card-layout__title') ||
                      document.querySelector('h1.topcard__title') ||
                      document.querySelector('h1[data-testid="jobsearch-JobInfoHeader-title"]') ||
                      document.querySelector('h1[id^="jd-job-title-"]')
                    );
                  })()
                """,
                );

                if (result == true) {
                  await _completeVerification(controller);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeVerification(InAppWebViewController? controller) async {
    if (controller == null) return;

    final url = await controller.getUrl();
    if (url == null) return;

    final cookies = await cookieManager.getCookies(url: url);
    final Map<String, String> cookieMap = {};
    for (var cookie in cookies) {
      cookieMap[cookie.name] = cookie.value.toString();
    }

    if (cookieMap.isNotEmpty) {
      final domain = Uri.parse(widget.url).host;
      ref.read(cookieProvider.notifier).updateCookies(domain, cookieMap);
      if (mounted) Navigator.pop(context, true);
    }
  }
}
