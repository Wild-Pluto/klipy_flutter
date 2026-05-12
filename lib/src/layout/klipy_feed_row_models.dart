import 'package:klipy_dart/klipy_dart.dart';

/// One positioned cell inside a [KlipyFeedRow].
class KlipyFeedCell {
  const KlipyFeedCell({
    required this.sourceIndex,
    required this.item,
    required this.x,
    required this.width,
    required this.height,
  });

  /// Index in the original flat [KlipyFeedItem] list (for keys / callbacks).
  final int sourceIndex;
  final KlipyFeedItem item;
  final double x;
  final double width;
  final double height;
}

/// One horizontal row in the row-based feed.
class KlipyFeedRow {
  const KlipyFeedRow({required this.cells, required this.height});

  final List<KlipyFeedCell> cells;
  final double height;
}
