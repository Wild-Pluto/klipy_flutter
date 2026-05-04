import 'package:flutter/material.dart';
import 'package:klipy_flutter/klipy_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KlipyAdCell extends StatefulWidget {
  final KlipyAdFeedItem adItem;

  const KlipyAdCell({
    required this.adItem,
    super.key,
  });

  @override
  State<KlipyAdCell> createState() => _KlipyAdCellState();
}

class _KlipyAdCellState extends State<KlipyAdCell> {
  static const _logTag = '[KlipyAds][AdCell]';

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '$_logTag controller-created '
      'width=${widget.adItem.width} '
      'height=${widget.adItem.height}',
    );

    final iframeUrl = _extractIframeUrl(widget.adItem.content);
    if (iframeUrl != null) {
      debugPrint('$_logTag load-start mode=iframe-html src=$iframeUrl');
    } else {
      debugPrint(
        '$_logTag load-start mode=html length=${widget.adItem.content.length}',
      );
    }

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                debugPrint('$_logTag page-started url=$url');
              },
              onPageFinished: (url) {
                debugPrint('$_logTag load-completed url=$url');
              },
              onWebResourceError: (error) {
                debugPrint(
                  '$_logTag resource-error '
                  'code=${error.errorCode} '
                  'description=${error.description} '
                  'url=${error.url ?? 'unknown'}',
                );
              },
              onNavigationRequest: (request) {
                debugPrint('$_logTag navigation-request url=${request.url}');
                final url = request.url.toLowerCase();
                final isInternalNavigation =
                    url.startsWith('about:blank') ||
                    url.startsWith('data:') ||
                    url.startsWith('file:');
                final decision =
                    isInternalNavigation
                        ? NavigationDecision.navigate
                        : NavigationDecision.prevent;
                debugPrint('$_logTag navigation-decision decision=$decision');
                return decision;
              },
            ),
          )
          ..loadHtmlString(widget.adItem.content);
  }

  @override
  Widget build(BuildContext context) {
    final adWidth = widget.adItem.width > 0 ? widget.adItem.width : 320;
    final adHeight = widget.adItem.height > 0 ? widget.adItem.height : 180;
    final adAspectRatio = adWidth / adHeight;

    return AspectRatio(
      aspectRatio: adAspectRatio,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          debugPrint('$_logTag ad-cell-tap');
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }

  String? _extractIframeUrl(String html) {
    final regex = RegExp(
      r'<iframe[^>]*\ssrc="([^"]+)"',
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    return match?.group(1);
  }
}
