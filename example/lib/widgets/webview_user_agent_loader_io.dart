import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewUserAgentLoader extends StatefulWidget {
  final ValueChanged<String?> onResolved;

  const WebViewUserAgentLoader({
    required this.onResolved,
    super.key,
  });

  @override
  State<WebViewUserAgentLoader> createState() => _WebViewUserAgentLoaderState();
}

class _WebViewUserAgentLoaderState extends State<WebViewUserAgentLoader> {
  static const _userAgentJavaScript = 'navigator.userAgent';
  static const _blankHtml = '<html><head></head><body></body></html>';

  late final WebViewController _controller;
  bool _hasResolved = false;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) => unawaited(_resolveUserAgent()),
            ),
          );

    unawaited(_controller.loadHtmlString(_blankHtml));
  }

  Future<void> _resolveUserAgent() async {
    if (_hasResolved) return;
    _hasResolved = true;

    try {
      final result = await _controller.runJavaScriptReturningResult(
        _userAgentJavaScript,
      );
      widget.onResolved(_normalizeJavaScriptResult(result));
    } catch (_) {
      widget.onResolved(null);
    }
  }

  String? _normalizeJavaScriptResult(Object? result) {
    if (result == null) return null;

    final raw = result.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;

    // Some platforms return a quoted string representation.
    if (raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')) {
      return raw.substring(1, raw.length - 1);
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    // Invisible 1x1 WebView to allow JS evaluation of navigator.userAgent.
    return IgnorePointer(
      ignoring: true,
      child: Opacity(
        opacity: 0,
        child: SizedBox(
          width: 1,
          height: 1,
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}

