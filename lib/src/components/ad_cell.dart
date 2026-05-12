import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klipy_flutter/klipy_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KlipyAdCell extends StatefulWidget {
  const KlipyAdCell({
    required this.adItem,
    this.slotFillColor,
    super.key,
  });

  final KlipyAdFeedItem adItem;

  /// Paints under the web slot (same as [KlipyTabViewStyle.mediaBackgroundColor])
  /// so row-tall cells and sub-pixel layout do not show a fringe under the ad.
  final Color? slotFillColor;

  @override
  State<KlipyAdCell> createState() => _KlipyAdCellState();
}

class _KlipyAdCellState extends State<KlipyAdCell> {
  static const _logTag = '[KlipyAds][AdCell]';

  /// Matches Klipy request `ad-max-height`; slot height never exceeds this.
  static const _maxAdHeight = 200.0;

  /// Klipy ad HTML often uses a fixed-width root; this CSS + viewport meta
  /// widens common tags. Avoid `body{display:flex}` — it pinned creatives to
  /// the top-left in WKWebView.
  static const _fullBleedDomScript = r'''
(function() {
  try {
    var id = 'klipy-ad-fullbleed-style';
    var head = document.head;
    if (head && !document.getElementById(id)) {
      var s = document.createElement('style');
      s.id = id;
      s.textContent =
        'html,body{width:100%!important;height:100%!important;margin:0!important;' +
        'padding:0!important;overflow:hidden!important;box-sizing:border-box!important;' +
        'background:transparent!important}' +
        'body{display:block!important;text-align:center!important}' +
        'body>*{width:100%!important;max-width:100%!important;margin:0 auto!important;' +
        'box-sizing:border-box!important}' +
        'iframe,img,video,canvas,svg{display:block;width:100%!important;height:100%!important;' +
        'max-width:100%!important;max-height:100%!important;object-fit:cover!important;' +
        'margin:0 auto!important;border:0!important}';
      head.appendChild(s);
    }
    var d = document.documentElement;
    var b = document.body;
    if (d) {
      d.style.width = '100%';
      d.style.height = '100%';
      d.style.margin = '0';
      d.style.padding = '0';
    }
    if (b) {
      b.style.width = '100%';
      b.style.height = '100%';
      b.style.margin = '0';
      b.style.padding = '0';
      b.style.display = 'block';
      b.style.textAlign = 'center';
    }
    if (head) {
      var m = document.querySelector('meta[name="viewport"]');
      if (!m) {
        m = document.createElement('meta');
        m.setAttribute('name', 'viewport');
        head.appendChild(m);
      }
      m.setAttribute(
        'content',
        'width=device-width, initial-scale=1, maximum-scale=1, ' +
          'viewport-fit=cover',
      );
    }
  } catch (e) {}
})();
''';

  late final WebViewController _controller;
  String? _directAdUrl;

  /// iOS: [ValueKey] on `content.hashCode` alone can collide; duplicate keys
  /// trigger `PlatformException(recreating_view, ...)`.
  final UniqueKey _webViewSlotKey = UniqueKey();

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
                _runFullBleedScripts();
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

  void _runFullBleedScripts() {
    void run(String phase) {
      _controller.runJavaScript(_fullBleedDomScript).catchError((Object e) {
        debugPrint('$_logTag fullbleed-script-error $phase $e');
      });
    }

    run('primary');
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      run('delayed');
    });
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
        final intrinsicW = adWidth.toDouble();
        final intrinsicH = adHeight.toDouble();
        final naturalHeight = availableWidth / safeAspectRatio;
        var slotHeight = naturalHeight;
        if (!slotHeight.isFinite || slotHeight <= 0) {
          slotHeight = 100.0;
        }
        final maxCapped = slotHeight > _maxAdHeight;
        if (maxCapped) {
          slotHeight = _maxAdHeight;
        }

        final paintedAfterFitWidth =
            intrinsicW > 0
                ? intrinsicH * (availableWidth / intrinsicW)
                : slotHeight;
        final insidePad = (slotHeight -
                math.min(paintedAfterFitWidth, slotHeight))
            .clamp(0.0, double.infinity);

        if (kDebugMode) {
          debugPrint(
            '$_logTag layout '
            'api=${widget.adItem.width}x${widget.adItem.height} '
            'crossMaxW=${availableWidth.toStringAsFixed(1)} '
            'aspect=${safeAspectRatio.toStringAsFixed(3)} '
            'naturalH=${naturalHeight.toStringAsFixed(1)} '
            'paintedFitWH=${paintedAfterFitWidth.toStringAsFixed(1)} '
            'slotH=${slotHeight.toStringAsFixed(1)} '
            'maxCap=$maxCapped '
            'insidePadY=${insidePad.toStringAsFixed(1)}',
          );
        }

        // Row-based feed: the row height follows max(GIF, ad). The WebView
        // slot stays `slotHeight` (API aspect); fill extra space so the
        // parent `ColoredBox` does not show a band under the creative.
        final maxH = constraints.maxHeight;
        final fillHeight =
            constraints.hasBoundedHeight && maxH.isFinite && maxH > 0
                ? math.max(slotHeight, maxH)
                : slotHeight;

        final dpr = MediaQuery.devicePixelRatioOf(context);
        final innerHeight = math.min(
          slotHeight + 1 / dpr,
          fillHeight,
        );

        return SizedBox(
          width: availableWidth,
          height: fillHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              if (widget.slotFillColor != null)
                Positioned.fill(
                  child: ColoredBox(color: widget.slotFillColor!),
                ),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: availableWidth,
                  height: innerHeight,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      debugPrint('$_logTag ad-cell-tap');
                    },
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: intrinsicW,
                          height: intrinsicH,
                          child: WebViewWidget(
                            key: _webViewSlotKey,
                            controller: _controller,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
