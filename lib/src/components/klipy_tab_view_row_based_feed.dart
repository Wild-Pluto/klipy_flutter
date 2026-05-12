import 'package:klipy_dart/klipy_dart.dart';
import 'package:flutter/material.dart';
import 'package:klipy_flutter/src/layout/klipy_feed_row_layout_calculator.dart';
import 'package:klipy_flutter/src/layout/klipy_feed_row_models.dart';

/// Sliver list that lays out [KlipyFeedItem]s using [KlipyFeedRowLayoutCalculator].
class KlipyTabViewRowBasedFeedSliver extends StatelessWidget {
  const KlipyTabViewRowBasedFeedSliver({
    super.key,
    required this.items,
    required this.feedWidth,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.maxCellsPerRow,
    required this.itemBuilder,
  });

  final List<KlipyFeedItem> items;
  final double feedWidth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int maxCellsPerRow;

  final Widget Function(KlipyFeedCell cell) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final calc = KlipyFeedRowLayoutCalculator(
      containerWidth: feedWidth,
      crossAxisSpacing: crossAxisSpacing,
      maxCellsPerRow: maxCellsPerRow,
      wideAdAspectThreshold: 2,
      minRowHeight: 50,
      maxAdRowVisualHeight: 200,
      maxGifRowHeight: 360,
      adMaxResizePercent: 0.25,
    );
    final rows = calc.computeRows(items);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final row = rows[index];
          final isLast = index == rows.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : mainAxisSpacing),
            child: _KlipyFeedRowView(
              row: row,
              itemBuilder: itemBuilder,
            ),
          );
        },
        childCount: rows.length,
      ),
    );
  }
}

class _KlipyFeedRowView extends StatelessWidget {
  const _KlipyFeedRowView({
    required this.row,
    required this.itemBuilder,
  });

  final KlipyFeedRow row;
  final Widget Function(KlipyFeedCell cell) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (row.height <= 0) {
      return _KlipyOffstageRowCells(cells: row.cells, itemBuilder: itemBuilder);
    }
    return SizedBox(
      height: row.height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final cell in row.cells)
              Positioned(
                left: cell.x,
                top: 0,
                width: cell.width,
                height: cell.height,
                child: itemBuilder(cell),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keeps zero-height placeholder cells in the tree (e.g. keep-alive slots).
class _KlipyOffstageRowCells extends StatelessWidget {
  const _KlipyOffstageRowCells({
    required this.cells,
    required this.itemBuilder,
  });

  final List<KlipyFeedCell> cells;
  final Widget Function(KlipyFeedCell cell) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final cell in cells)
          Offstage(
            offstage: true,
            child: itemBuilder(cell),
          ),
      ],
    );
  }
}
