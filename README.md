# ⚠️ NOT MAINTAINED ⚠️
After exploring the option of using KLIPY we have decided against it.

If you are interested in taking over this repo and package please do not hesitate to reach out via the issues and we will get it sorted out.

# KLIPY Flutter

<p align="center">
  <a href="https://pub.dartlang.org/packages/klipy_flutter"><img src="https://img.shields.io/pub/v/klipy_flutter.svg" alt="KLIPY Flutter Pub Package" /></a>
  <a href="https://github.com/Flyclops/klipy_flutter/actions/workflows/main.yml"><img src="https://github.com/flyclops/klipy_flutter/actions/workflows/main.yml/badge.svg" alt="Build Status" /></a>
  <a href="https://coveralls.io/github/Flyclops/klipy_flutter?branch=main"><img src="https://coveralls.io/repos/github/Flyclops/klipy_flutter/badge.svg?branch=main" alt="Coverage Status" /></a>
 <a href="https://github.com/flyclops/klipy_flutter/stargazers"><img src="https://img.shields.io/github/stars/flyclops/klipy_flutter?style=flat" alt="KLIPY Dart Stars" /></a>
  <a href="https://github.com/Flyclops/klipy_flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-BSD_3--Clause-blue.svg" alt="License BSD 3-Clause" /></a>
</p>

This package integrates [KLIPY GIF search](https://klipy.com/) into [Flutter](https://flutter.dev/) by utilizing the [klipy_dart](https://pub.dev/packages/klipy_dart) package to communicate directly with the [KLIPY API](https://docs.klipy.com/getting-started) via [http](https://pub.dev/packages/http). It is currently using the [migration from Tenor](https://docs.klipy.com/migrate-from-tenor) option.

The package currently provides an opinionated yet customizable UI experience for searching and selecting from a list of GIFs/Stickers from the KLIPY GIF search API.

<p align="center"><img src="https://github.com/flyclops/klipy_flutter/raw/main/example/assets/demo.gif" width="200" alt="KLIPY Flutter Demo"/></p>

<p align="center"><strong><sup>Show some ❤️ and <a href="https://github.com/flyclops/klipy_flutter">star the repo</a> to support this package.</sup></strong></p>

## What to know

- In order to start using KLIPY Dart you must obtain an API key by registering your project with [KLIPY](https://docs.klipy.com/getting-started).
- KLIPY requires proper [attribution](https://docs.klipy.com/attribution) for projects using their API. This package does not handle the attribution process, so you will need to take care of it yourself.

## Obtaining KLIPY API key

1. Log in to the [partner panel](https://partner.klipy.com)
2. Add a [new platform](https://partner.klipy.com/api-keys)
3. Click `Create Key`
4. Copy the generated API key
5. Provide this API key as a parameter to `KlipyClient(apiKey: 'YOUR_API_KEY')`

## Usage

### Installation

```
flutter pub add klipy_flutter
```

<sup>Having trouble? Read the pub.dev <a href="https://pub.dev/packages/klipy_flutter/install">installation page</a>.</sup>

### Import

Import the package into the dart file where it will be used:

```
import 'package:klipy_flutter/klipy_flutter.dart';
```

### Initialize

You must pass in a valid `apiKey` provided by [KLIPY](https://docs.klipy.com/getting-started).

```
final klipyClient = KlipyClient(apiKey: 'YOUR_API_KEY');
```

For KLIPY ads support, pass `adRequestContext` and a proper `userAgent`:

```
final klipyClient = KlipyClient(
  apiKey: 'YOUR_API_KEY',
  adRequestContext: const KlipyAdRequestContext(
    customerId: 'stable-user-id',
    adMinWidth: 50,
    adMaxWidth: 320,
    adMinHeight: 50,
    adMaxHeight: 180,
  ),
  // IMPORTANT:
  // For KLIPY ads, this must be a *browser-like WebView User-Agent*.
  // See: https://docs.klipy.com/advertisements/receiving-an-ad/browser-like-user-agent
  userAgent: webViewUserAgentString,
);
```

#### Getting a browser-like WebView User-Agent (recommended for ads)

KLIPY ads require a **WebView** User-Agent (not an app-style UA like `MyApp/1.0 (Flutter)`).
Fetch it once on app startup, cache it, and pass it into `KlipyClient(userAgent: ...)`.

Example approach (using `webview_flutter`):

```
Future<String?> resolveWebViewUserAgent() async {
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  // Load any document so we can evaluate navigator.userAgent
  await controller.loadHtmlString('<html><body></body></html>');

  final result = await controller.runJavaScriptReturningResult('navigator.userAgent');
  final ua = result?.toString();

  // Depending on platform, this may come back quoted. Normalize if needed.
  return ua?.replaceAll(RegExp('^\"|\"$'), '');
}
```

## Example

For more elaborate examples feel free to check out [example/lib/main.dart](https://github.com/Flyclops/klipy_flutter/blob/main/example/lib/main.dart).

Here's how to display the UI as a bottom sheet and then print the user's selection. If `null` is returned, it means the user closed the sheet without choosing a GIF.

```
final klipyClient = KlipyClient(apiKey: 'YOUR_API_KEY');
final KlipyResultObject? result = await klipyClient.showAsBottomSheet(context: context);
print(result?.media.tinyGif?.url);
```
## Migrating from `tenor_flutter` to `klipy_flutter`
- [Get an API key](https://github.com/Flyclops/klipy_flutter/tree/main?tab=readme-ov-file#obtaining-klipy-api-key) and update it in your app
- Change all references of:
  - `import 'package:tenor_flutter/tenor_flutter.dart';` to `import 'package:klipy_flutter/klipy_flutter.dart';`
  - `TenorResult` to `KlipyResultObject`
  - `TenorMediaObject` to `KlipyMediaObject`
  - `TenorStyle` to `KlipyStyle`
  - `TenorSelectedCategoryStyle` to `KlipySelectedCategoryStyle`
  - `Tenor` to `KlipyClient`
- Remove the following parameters from `Tenor`/`KlipyClient`:
  - `clientKey`
    - If you would like to distinguish between projects/devices then consider creating seperate [API keys](https://partner.klipy.com/api-keys) under the same platform. 
  - `contentFilter`
    - This can be set in the [Partner Panel](https://docs.klipy.com/migrate-from-tenor/content-filtering)
- Update attribution to [support KLIPY rules](https://docs.klipy.com/attribution)


## Don't need the UI?

If you're seeking a solution that allows for full customization without the need of dependencies then consider [KLIPY Dart](https://github.com/Flyclops/klipy_dart).

## What's next?

- Documentation
- Tests _([Contributions](https://github.com/Flyclops/klipy_flutter/blob/main/CONTRIBUTING.md) welcome)_ ^\_^
- Further improvements

## Contributing

If you read this far then you are awesome! There are a multiple ways in which you can [contribute](https://github.com/Flyclops/klipy_flutter/blob/main/CONTRIBUTING.md):

- Pick up any issue marked with "[good first issue](https://github.com/flyclops/klipy_flutter/issues?q=is:open+is:issue+label:%22good+first+issue%22)"
- Propose any feature, enhancement
- Report a bug
- Fix a bug
- Write and improve some documentation
- Send in a Pull Request 🙏
