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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            final isInternalNavigation =
                url.startsWith('about:blank') ||
                url.startsWith('data:') ||
                url.startsWith('file:');
            return isInternalNavigation
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
