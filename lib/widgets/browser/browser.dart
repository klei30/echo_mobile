import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:chatmcp/utils/inappview.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:html2md/html2md.dart' as html2md;
import 'package:chatmcp/generated/app_localizations.dart';

class SearchResult {
  final String title;
  final String url;
  final String snippet;
  String content = '';

  SearchResult({required this.title, required this.url, required this.snippet, this.content = ''});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(title: json['title'] ?? '', url: json['url'] ?? '', snippet: json['snippet'] ?? '', content: json['content'] ?? '');
  }
}

class BrowserView extends StatefulWidget {
  final String url;

  const BrowserView({super.key, required this.url});

  @override
  State<BrowserView> createState() => BrowserViewState();
}

class BrowserViewState extends State<BrowserView> {
  final browser = MyInAppBrowser(webViewEnvironment: webViewEnvironment);
  List<SearchResult> searchResults = [];

  final settings = InAppBrowserClassSettings(
    browserSettings: InAppBrowserSettings(hideUrlBar: true),
    webViewSettings: InAppWebViewSettings(
      userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      javaScriptEnabled: true,
      isInspectable: kDebugMode,
    ),
  );

  @override
  Widget build(BuildContext context) {
    var t = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.open_in_browser),
      tooltip: t.openBrowser,
      onPressed: () {
        browser.openUrlRequest(
          urlRequest: URLRequest(url: WebUri('http://google.com/search?q=${widget.url}')),
          settings: settings,
        );
        debugPrint(t.openingBrowser);
      },
    );
  }
}

class MyInAppBrowser extends InAppBrowser {
  MyInAppBrowser({super.webViewEnvironment});
  List<SearchResult> searchResults = [];
  HeadlessInAppWebView? contentWebView;
  String? turndownJs;

  @override
  Future onBrowserCreated() async {
    debugPrint("Browser Created!");
    // initialize headless browser for extracting content
    contentWebView = HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        javaScriptEnabled: true,
      ),
    );
    await contentWebView?.run();

    // load turndown.js file
    turndownJs = await rootBundle.loadString('assets/js/turndown.js');
  }

  @override
  Future onLoadStart(url) async {
    debugPrint("Started $url");
  }

  @override
  Future onLoadStop(url) async {
    debugPrint("Stopped $url");
    final pageDataList = await extractSearchResults();
    debugPrint('pageDataList: $pageDataList');
  }

  Future<String> extractContent(String url) async {
    try {
      final controller = contentWebView?.webViewController;
      if (controller == null) {
        return '';
      }

      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));

      await Future.delayed(const Duration(seconds: 3));

      // check page content
      final pageContent = await controller.evaluateJavascript(source: 'document.documentElement.outerHTML');

      final md = html2md.convert(pageContent);
      return md;
    } catch (e) {
      debugPrint('extract content error: $e');
      debugPrint('error stack: ${StackTrace.current}');
      return '';
    }
  }

  Future<List<Map<String, String>>> extractSearchResults() async {
    final js = '''
      function extractResults() {
        const results = [];
        document.querySelectorAll('.g').forEach(item => {
          const titleEl = item.querySelector('.LC20lb');
          const linkEl = item.querySelector('a');
          const snippetEl = item.querySelector('.VwiC3b');
          
          if(titleEl && linkEl && snippetEl) {
            results.push({
              title: titleEl.innerText,
              url: linkEl.href,
              snippet: snippetEl.innerText
            });
          }
        });
        return JSON.stringify(results);
      }
      extractResults();
    ''';

    final result = await webViewController?.evaluateJavascript(source: js);
    if (result != null) {
      try {
        final List parsed = jsonDecode(result);
        searchResults = parsed.map((item) => SearchResult.fromJson(item)).toList();

        List<Map<String, String>> pageDataList = [];
        // iterate to get content of each result
        for (var result in searchResults) {
          Map<String, String> paegData = {
            'title': result.title,
            'url': result.url,
            'snippet': result.snippet,
            'content': await extractContent(result.url),
          };
          pageDataList.add(paegData);
        }

        return pageDataList;
      } catch (e) {
        Logger.root.severe('parse search results error: $e');
      }
    }
    return [];
  }

  @override
  void onReceivedError(WebResourceRequest request, WebResourceError error) {
    debugPrint("Can't load ${request.url}.. Error: ${error.description}");
  }

  @override
  void onProgressChanged(progress) {
    debugPrint("Progress: $progress");
  }

  @override
  Future<void> onExit() async {
    debugPrint("Browser closed!");
    await contentWebView?.dispose();
  }
}
