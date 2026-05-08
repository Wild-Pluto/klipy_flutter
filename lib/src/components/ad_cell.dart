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
  static const _minAdHeight = 80.0;
  static const _maxAdHeight = 220.0;

  late final WebViewController _controller;
  String? _directAdUrl;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '$_logTag controller-created '
      'width=${widget.adItem.width} '
      'height=${widget.adItem.height}',
    );

    final rawContent = widget.adItem.content.trim();
    final iframeUrl = _extractIframeUrl(rawContent);
    final directUrl = _extractDirectUrl(rawContent);
    _directAdUrl = directUrl;

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
                final requestedUri = Uri.tryParse(request.url);
                final isInternalNavigation =
                    url.startsWith('about:blank') ||
                    url.startsWith('data:') ||
                    url.startsWith('file:');
                final isInitialDirectAdRequest =
                    _directAdUrl != null && request.url == _directAdUrl;
                final isKlipyMainFrame =
                    requestedUri != null &&
                    (requestedUri.scheme == 'https' ||
                        requestedUri.scheme == 'http') &&
                    requestedUri.host.toLowerCase().endsWith('klipy.com');
                final allow =
                    isInternalNavigation ||
                    isInitialDirectAdRequest ||
                    isKlipyMainFrame;
                final decision =
                    allow
                        ? NavigationDecision.navigate
                        : NavigationDecision.prevent;
                debugPrint('$_logTag navigation-decision decision=$decision');
                return decision;
              },
            ),
          );

    if (directUrl != null) {
      debugPrint('$_logTag load-start mode=url src=$directUrl');
      _controller.loadRequest(Uri.parse(directUrl));
      return;
    }

    if (iframeUrl != null) {
      debugPrint('$_logTag load-start mode=iframe-html src=$iframeUrl');
    } else {
      debugPrint('$_logTag load-start mode=html length=${rawContent.length}');
    }
    _controller.loadHtmlString(rawContent);
  }

  @override
  Widget build(BuildContext context) {
    final adWidth = widget.adItem.width > 0 ? widget.adItem.width : 320;
    final adHeight = widget.adItem.height > 0 ? widget.adItem.height : 180;
    final adAspectRatio = adWidth / adHeight;
    final safeAspectRatio = adAspectRatio > 0 ? adAspectRatio : (16 / 9);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final naturalHeight = availableWidth / safeAspectRatio;
        final appliedHeight =
            naturalHeight.clamp(_minAdHeight, _maxAdHeight).toDouble();

        debugPrint(
          '$_logTag dimensions '
          'received=${widget.adItem.width}x${widget.adItem.height} '
          'applied=${availableWidth.toStringAsFixed(1)}x${appliedHeight.toStringAsFixed(1)} '
          'aspect=${safeAspectRatio.toStringAsFixed(3)}',
        );

        return SizedBox(
          width: availableWidth,
          height: appliedHeight,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              debugPrint('$_logTag ad-cell-tap');
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: WebViewWidget(
                key: ValueKey('ad-webview-${widget.adItem.content.hashCode}'),
                controller: _controller,
              ),
            ),
          ),
        );
      },
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

  String? _extractDirectUrl(String content) {
    final parsed = Uri.tryParse(content);
    if (parsed == null) return null;

    final scheme = parsed.scheme.toLowerCase();
    final isHttp = scheme == 'http' || scheme == 'https';
    if (!isHttp) return null;
    if (parsed.host.isEmpty) return null;

    return parsed.toString();
  }
}
