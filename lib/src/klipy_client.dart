import 'package:flutter/material.dart';
import 'package:klipy_dart/klipy_dart.dart' as klipy_dart;
import 'package:klipy_flutter/klipy_flutter.dart';
import 'package:klipy_flutter/src/components/components.dart';
import 'package:klipy_flutter/src/providers/providers.dart';
import 'package:provider/provider.dart';

const klipyDefaultAnimationStyle = AnimationStyle(
  duration: Duration(milliseconds: 250),
  reverseDuration: Duration(milliseconds: 200),
);

class KlipyStyle {
  final AnimationStyle? animationStyle;
  final KlipyAttributionStyle attributionStyle;

  /// Background color of the sheet.
  final Color color;
  final KlipyDragHandleStyle dragHandleStyle;
  final String? fontFamily;
  final KlipySearchFieldStyle searchFieldStyle;
  final KlipySelectedCategoryStyle selectedCategoryStyle;

  /// Shape for the sheet.
  final ShapeBorder shape;
  final KlipyTabBarStyle tabBarStyle;
  final KlipyTabViewStyle tabViewStyle;

  const KlipyStyle({
    this.animationStyle,
    this.attributionStyle = const KlipyAttributionStyle(),
    this.color = const Color(0xFFF9F8F2),
    this.dragHandleStyle = const KlipyDragHandleStyle(),
    this.fontFamily,
    this.searchFieldStyle = const KlipySearchFieldStyle(),
    this.selectedCategoryStyle = const KlipySelectedCategoryStyle(),
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
    ),
    this.tabBarStyle = const KlipyTabBarStyle(),
    this.tabViewStyle = const KlipyTabViewStyle(),
  });
}

class KlipyClient extends klipy_dart.KlipyClient {
  const KlipyClient({
    required super.apiKey,
    super.adRequestContext,
    super.client = const klipy_dart.KlipyHttpClient(),
    super.country = 'US',
    super.locale = 'en_US',
    super.networkTimeout = const Duration(seconds: 5),
    super.userAgent,
  });

  /// Shows a bottom sheet modal that allows you to select a KLIPY media object for use.
  ///
  /// If you pass in a `searchFieldWidget` you must also pass in a `searchFieldController`. The controller will automatically be disposed of.
  ///
  /// You must have valid [KLIPY attribution](https://docs.klipy.com/attribution) in order to use this within your app.
  Future<KlipyResultObject?> showAsBottomSheet({
    required BuildContext context,
    KlipyAttributionType attributionType = KlipyAttributionType.poweredBy,
    // Whether to cover the app bar with the bottom sheet.
    bool coverAppBar = false,
    Duration debounce = const Duration(milliseconds: 300),
    double? initialExtent,
    int initialTabIndex = 1,
    ScrollViewKeyboardDismissBehavior keyboardDismissBehavior =
        ScrollViewKeyboardDismissBehavior.manual,
    double maxExtent = 1,
    double minExtent = 0.7,
    String queryText = '',
    TextEditingController? searchFieldController,
    String searchFieldHintText = 'Search KLIPY',
    Widget? searchFieldWidget,
    // A list of target sizes that the showModalBottomSheet should snap to.
    // The [minChildSize] and [maxChildSize] are implicitly included in snap sizes and do not need to be specified here.
    List<double>? snapSizes,
    KlipyStyle style = const KlipyStyle(),
    List<KlipyTab>? tabs,
    bool useSafeArea = true,
  }) {
    final tabsToDisplay =
        tabs ??
        [
          KlipyTab(
            name: 'Emojis',
            view: KlipyViewEmojis(client: this, style: style.tabViewStyle),
          ),
          KlipyTab(
            name: 'GIFs',
            view: KlipyViewGifs(client: this, style: style.tabViewStyle),
          ),
          KlipyTab(
            name: 'Stickers',
            view: KlipyViewStickers(client: this, style: style.tabViewStyle),
          ),
        ];

    return showModalBottomSheet<KlipyResultObject>(
      clipBehavior: Clip.antiAlias,
      context: context,
      isScrollControlled: true,
      shape: style.shape,
      sheetAnimationStyle: style.animationStyle ?? klipyDefaultAnimationStyle,
      useSafeArea: useSafeArea,
      builder: (context) {
        return DefaultTextStyle.merge(
          style: TextStyle(fontFamily: style.fontFamily),
          child: Padding(
            padding: EdgeInsets.only(
              // move the sheet up when the keyboard is shown
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create:
                      (context) => KlipyAppBarProvider(
                        queryText,
                        debounce,
                        keyboardDismissBehavior: keyboardDismissBehavior,
                      ),
                ),
                ChangeNotifierProvider(
                  create:
                      (context) => KlipySheetProvider(
                        initialExtent: initialExtent,
                        maxExtent: maxExtent,
                        minExtent: minExtent,
                        scrollController: DraggableScrollableController(),
                      ),
                ),
                ChangeNotifierProvider(
                  create:
                      (context) => KlipyTabProvider(
                        attributionType: attributionType,
                        client: this,
                        selectedTab: tabsToDisplay[initialTabIndex],
                      ),
                ),
              ],
              child: KlipySheet(
                attributionType: attributionType,
                coverAppBar: coverAppBar,
                initialTabIndex: initialTabIndex,
                searchFieldController: searchFieldController,
                searchFieldHintText: searchFieldHintText,
                searchFieldWidget: searchFieldWidget,
                snapSizes: snapSizes,
                style: style,
                tabs: tabsToDisplay,
              ),
            ),
          ),
        );
      },
    );
  }
}
