import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:klipy_flutter/klipy_flutter.dart';
import 'package:klipy_flutter_example/examples/dark_theme.dart';
import 'package:klipy_flutter_example/examples/localization.dart';
import 'package:klipy_flutter_example/widgets/webview_user_agent_loader.dart';

void main() async {
  // only used to load api key from .env file, not required
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KLIPY Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _fallbackUserAgent = 'KLIPYFlutterExample/1.0 (Flutter)';

  late KlipyClient klipyClient;
  String? _webViewUserAgent;

  // define a result that we can display later
  KlipyResultObject? selectedResult;

  @override
  void initState() {
    super.initState();
    klipyClient = _createKlipyClient(userAgent: _fallbackUserAgent);
  }

  KlipyClient _createKlipyClient({required String userAgent}) {
    // replace apiKey with an api key provided by KLIPY > https://docs.klipy.com/getting-started
    return KlipyClient(
      apiKey: FlutterConfig.get('KLIPY_API_KEY'),
      // Required for KLIPY ad serving in mixed feeds.
      adRequestContext: const KlipyAdRequestContext(
        customerId: 'example-user-id',
        adMinWidth: 50,
        adMaxWidth: 320,
        adMinHeight: 50,
        adMaxHeight: 180,
      ),
      // KLIPY ads require a browser-like WebView User-Agent. We resolve it
      // at runtime and fall back to an app UA if unavailable.
      userAgent: userAgent,
    );
  }

  void _onWebViewUserAgentResolved(String? userAgent) {
    final normalized = userAgent?.trim();
    if (!mounted || normalized == null || normalized.isEmpty) return;
    if (_webViewUserAgent == normalized) return;

    setState(() {
      _webViewUserAgent = normalized;
      klipyClient = _createKlipyClient(userAgent: normalized);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('KLIPY Flutter Demo'),
      ),
      body: Stack(
        children: [
          _exampleBody(),
          WebViewUserAgentLoader(onResolved: _onWebViewUserAgentResolved),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // A default implementation of klipy flutter. Displays the gif picker
          // as a bottom sheet and then updates the selectedResult in state.
          FloatingActionButton(
            onPressed: () async {
              final result =
                  await klipyClient.showAsBottomSheet(context: context);
              setState(() {
                selectedResult = result;
              });
            },
            tooltip: 'Default',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // Additional examples, see: https://github.com/Flyclops/klipy_flutter/tree/main/example/lib/examples
  Widget _exampleBody() {
    final selectedGif = selectedResult?.media.tinyGif ??
        selectedResult?.media.tinyGifTransparent;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text('Additional Examples'),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    // https://github.com/Flyclops/klipy_flutter/tree/main/example/lib/examples/dark_theme.dart
                    ElevatedButton(
                      onPressed: () => push(const DarkTheme()),
                      child: const Text('Dark Theme'),
                    ),
                    // https://github.com/Flyclops/klipy_flutter/tree/main/example/lib/examples/localization.dart
                    ElevatedButton(
                      onPressed: () => push(const Localization()),
                      child: const Text('Localization'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              selectedResult != null && selectedGif != null
                  ? KlipyMediaWidget(
                      media: Image.network(
                        selectedGif.url,
                        width: selectedGif.dimensions.width,
                        height: selectedGif.dimensions.height,
                      ),
                    )
                  : const Text('No GIF selected'),
              _webViewUserAgent != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'WebView UA resolved',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    )
                  : const SizedBox.shrink(),
              selectedGif != null
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(selectedGif.url),
                        const SizedBox(height: 16),
                        Text(
                            'Selected from ${selectedResult?.source ?? ''} tab'),
                      ],
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  void push(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }
}
