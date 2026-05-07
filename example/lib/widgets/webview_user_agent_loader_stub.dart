import 'package:flutter/widgets.dart';

class WebViewUserAgentLoader extends StatelessWidget {
  final ValueChanged<String?> onResolved;

  const WebViewUserAgentLoader({
    required this.onResolved,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // WebView is not available on this platform (e.g. Flutter Web).
    // Provide a null UA and render nothing.
    WidgetsBinding.instance.addPostFrameCallback((_) => onResolved(null));
    return const SizedBox.shrink();
  }
}

