import 'dart:math' as math;

import 'package:klipy_dart/klipy_dart.dart';

import 'klipy_feed_row_models.dart';

/// Builds row/cell geometry for the Klipy iOS-style row feed (max two cells per
/// row, wide ads on their own row).
///
/// Parameters are **named** at the call site to avoid swapping
/// `itemMinWidth` / `adMaxResizePercent`-style bugs.
class KlipyFeedRowLayoutCalculator {
  KlipyFeedRowLayoutCalculator({
    required this.containerWidth,
    required this.crossAxisSpacing,
    required this.maxCellsPerRow,
    required this.wideAdAspectThreshold,
    required this.minRowHeight,
    required this.maxAdRowVisualHeight,
    required this.maxGifRowHeight,
    required this.adMaxResizePercent,
  }) : assert(containerWidth > 0),
       assert(crossAxisSpacing >= 0),
       assert(maxCellsPerRow >= 1),
       assert(wideAdAspectThreshold > 0),
       assert(minRowHeight > 0),
       assert(maxAdRowVisualHeight >= minRowHeight),
       assert(maxGifRowHeight >= minRowHeight),
       assert(adMaxResizePercent >= 0 && adMaxResizePercent <= 1);

  /// Inner width of the feed (viewport after horizontal padding).
  final double containerWidth;

  /// Horizontal gap between cells in the same row.
  final double crossAxisSpacing;

  /// Maximum items packed into one row (comment picker uses `2`).
  final int maxCellsPerRow;

  /// When `adWidth / adHeight` is at or above this, the ad occupies a full
  /// row (wide banner).
  final double wideAdAspectThreshold;

  final double minRowHeight;
  final double maxAdRowVisualHeight;
  final double maxGifRowHeight;

  /// Upper bound on how much a slot may shrink a non-wide ad relative to an
  /// equal column share (iOS `GridMeta` default `0.25`).
  final double adMaxResizePercent;

  /// Default factory aligned with app ad slot caps (`KlipyAdCell` uses 200).
  factory KlipyFeedRowLayoutCalculator.forCommentPicker({
    required double containerWidth,
    double crossAxisSpacing = 8,
    int maxCellsPerRow = 2,
    double wideAdAspectThreshold = 2,
    double minRowHeight = 50,
    double maxAdRowVisualHeight = 200,
    double maxGifRowHeight = 360,
    double adMaxResizePercent = 0.25,
  }) => KlipyFeedRowLayoutCalculator(
    containerWidth: containerWidth,
    crossAxisSpacing: crossAxisSpacing,
    maxCellsPerRow: maxCellsPerRow,
    wideAdAspectThreshold: wideAdAspectThreshold,
    minRowHeight: minRowHeight,
    maxAdRowVisualHeight: maxAdRowVisualHeight,
    maxGifRowHeight: maxGifRowHeight,
    adMaxResizePercent: adMaxResizePercent,
  );

  List<KlipyFeedRow> computeRows(List<KlipyFeedItem> items) {
    final rows = <KlipyFeedRow>[];
    var i = 0;
    while (i < items.length) {
      final item = items[i];
      if (_isLayoutOnlyPlaceholder(item)) {
        rows.add(_zeroHeightRow(i, item));
        i++;
        continue;
      }
      if (item is KlipyAdFeedItem && _isWideBannerAd(item)) {
        rows.add(_fullWidthAdRow(i, item));
        i++;
        continue;
      }
      if (maxCellsPerRow >= 2 && i + 1 < items.length) {
        final next = items[i + 1];
        if (!_isLayoutOnlyPlaceholder(next) &&
            !_mustBreakPairForSecondSlot(next)) {
          rows.add(_twoCellRow(i, item, i + 1, next));
          i += 2;
          continue;
        }
      }
      rows.add(_singleCellRow(i, item));
      i++;
    }
    return rows;
  }

  bool _isLayoutOnlyPlaceholder(KlipyFeedItem item) {
    return item.type == 'recently_used_keep_alive';
  }

  KlipyFeedRow _zeroHeightRow(int index, KlipyFeedItem item) {
    return KlipyFeedRow(
      height: 0,
      cells: [
        KlipyFeedCell(
          sourceIndex: index,
          item: item,
          x: 0,
          width: containerWidth,
          height: 0,
        ),
      ],
    );
  }

  bool _mustBreakPairForSecondSlot(KlipyFeedItem second) {
    return second is KlipyAdFeedItem && _isWideBannerAd(second);
  }

  bool _isWideBannerAd(KlipyAdFeedItem ad) {
    final w = ad.width;
    final h = ad.height;
    if (w <= 0 || h <= 0) {
      return true;
    }
    return w / h >= wideAdAspectThreshold;
  }

  KlipyFeedRow _fullWidthAdRow(int index, KlipyAdFeedItem ad) {
    final aw = ad.width > 0 ? ad.width.toDouble() : 320;
    final ah = ad.height > 0 ? ad.height.toDouble() : 180;
    final slotH = (containerWidth * ah / aw).clamp(
      minRowHeight,
      maxAdRowVisualHeight,
    );
    return KlipyFeedRow(
      height: slotH,
      cells: [
        KlipyFeedCell(
          sourceIndex: index,
          item: ad,
          x: 0,
          width: containerWidth,
          height: slotH,
        ),
      ],
    );
  }

  KlipyFeedRow _singleCellRow(int index, KlipyFeedItem item) {
    final slotH = _singleCellHeight(item, containerWidth);
    return KlipyFeedRow(
      height: slotH,
      cells: [
        KlipyFeedCell(
          sourceIndex: index,
          item: item,
          x: 0,
          width: containerWidth,
          height: slotH,
        ),
      ],
    );
  }

  double _singleCellHeight(KlipyFeedItem item, double width) {
    if (item is KlipyGifFeedItem) {
      final ar = _gifAspectRatio(item);
      return (width / ar).clamp(minRowHeight, maxGifRowHeight);
    }
    if (item is KlipyAdFeedItem) {
      final aw = item.width > 0 ? item.width.toDouble() : 320;
      final ah = item.height > 0 ? item.height.toDouble() : 180;
      return (width * ah / aw).clamp(minRowHeight, maxAdRowVisualHeight);
    }
    if (item.type == 'recently_used_gif') {
      return width.clamp(minRowHeight, maxGifRowHeight);
    }
    return minRowHeight;
  }

  KlipyFeedRow _twoCellRow(
    int index0,
    KlipyFeedItem item0,
    int index1,
    KlipyFeedItem item1,
  ) {
    final halfEqual = (containerWidth - crossAxisSpacing) / 2;
    final minAdHalf = halfEqual * (1.0 - adMaxResizePercent).clamp(0.0, 1.0);

    var w0 = halfEqual;
    var w1 = halfEqual;
    var rowH = _pairRowHeightForWidths(item0, item1, w0, w1);
    rowH = rowH.clamp(
      minRowHeight,
      math.max(maxGifRowHeight, maxAdRowVisualHeight),
    );

    // Widen GIF-like columns when a narrow ad needs less than half width.
    _redistributeWidthsForPair(
      item0,
      item1,
      minAdHalf: minAdHalf,
      rowHeight: rowH,
      outW0: (v) => w0 = v,
      outW1: (v) => w1 = v,
    );

    rowH = _pairRowHeightForWidths(item0, item1, w0, w1).clamp(
      minRowHeight,
      math.max(maxGifRowHeight, maxAdRowVisualHeight),
    );

    final x1 = w0 + crossAxisSpacing;
    return KlipyFeedRow(
      height: rowH,
      cells: [
        KlipyFeedCell(
          sourceIndex: index0,
          item: item0,
          x: 0,
          width: w0,
          height: rowH,
        ),
        KlipyFeedCell(
          sourceIndex: index1,
          item: item1,
          x: x1,
          width: w1,
          height: rowH,
        ),
      ],
    );
  }

  void _redistributeWidthsForPair(
    KlipyFeedItem item0,
    KlipyFeedItem item1, {
    required double minAdHalf,
    required double rowHeight,
    required void Function(double) outW0,
    required void Function(double) outW1,
  }) {
    final ad0 = item0 is KlipyAdFeedItem ? item0 : null;
    final ad1 = item1 is KlipyAdFeedItem ? item1 : null;
    if (ad0 != null && ad1 != null) {
      return;
    }
    final narrowAd =
        ad0 != null && !_isWideBannerAd(ad0)
            ? ad0
            : ad1 != null && !_isWideBannerAd(ad1)
            ? ad1
            : null;
    if (narrowAd == null) {
      return;
    }

    final aw = narrowAd.width > 0 ? narrowAd.width.toDouble() : 300;
    final ah = narrowAd.height > 0 ? narrowAd.height.toDouble() : 180;
    final naturalW = rowHeight * (aw / ah);
    final adIsFirst = identical(narrowAd, ad0);
    final equalHalf = (containerWidth - crossAxisSpacing) / 2;
    final maxAdW = equalHalf * (1.0 + adMaxResizePercent);
    var targetAdW = naturalW.clamp(minAdHalf, maxAdW);
    targetAdW = math.min(targetAdW, containerWidth - crossAxisSpacing - 1);
    final gifW = containerWidth - crossAxisSpacing - targetAdW;
    if (gifW < 1) {
      return;
    }
    if (adIsFirst) {
      outW0(targetAdW);
      outW1(gifW);
    } else {
      outW0(gifW);
      outW1(targetAdW);
    }
  }

  double _pairRowHeightForWidths(
    KlipyFeedItem a,
    KlipyFeedItem b,
    double w0,
    double w1,
  ) {
    return math.max(
      _cellHeightForWidth(a, w0),
      _cellHeightForWidth(b, w1),
    );
  }

  double _cellHeightForWidth(KlipyFeedItem item, double width) {
    if (item is KlipyGifFeedItem) {
      final ar = _gifAspectRatio(item);
      return (width / ar).clamp(minRowHeight, maxGifRowHeight);
    }
    if (item is KlipyAdFeedItem) {
      final aw = item.width > 0 ? item.width.toDouble() : 320;
      final ah = item.height > 0 ? item.height.toDouble() : 180;
      return (width * ah / aw).clamp(minRowHeight, maxAdRowVisualHeight);
    }
    if (item.type == 'recently_used_gif') {
      return width.clamp(minRowHeight, maxGifRowHeight);
    }
    return minRowHeight;
  }

  double _gifAspectRatio(KlipyGifFeedItem item) {
    final media =
        item.result.media.tinyGifTransparent ?? item.result.media.tinyGif;
    final ar = media?.dimensions.aspectRatio;
    if (ar != null && ar > 0) {
      return ar;
    }
    return 1;
  }
}
