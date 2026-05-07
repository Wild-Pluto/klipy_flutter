import 'package:flutter/material.dart';

class KlipyAttributionStyle {
  final Brightness brightnes;
  final double height;
  final EdgeInsets padding;

  const KlipyAttributionStyle({
    this.brightnes = Brightness.light,
    this.height = 20,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });
}

class KlipyAttribution extends StatelessWidget {
  final KlipyAttributionStyle style;

  const KlipyAttribution({
    this.style = const KlipyAttributionStyle(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath =
        style.brightnes == Brightness.light
            ? 'packages/klipy_flutter/assets/powered_by_dark.png'
            : 'packages/klipy_flutter/assets/powered_by_light.png';
    return Padding(
      // If safe area is required, add it.
      padding:
          MediaQuery.of(context).padding.bottom > 0
              ? style.padding.copyWith(
                bottom: MediaQuery.of(context).padding.bottom,
              )
              : style.padding,
      child: Center(
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          child: Image.asset(
            logoPath,
            height: style.height,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
