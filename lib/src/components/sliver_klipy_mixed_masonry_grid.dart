import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:klipy_flutter/src/rendering/render_sliver_klipy_mixed_masonry_grid.dart';

/// One masonry sliver that can place **full cross-axis** children (wide ads)
/// without splitting into multiple [SliverMasonryGrid] slices.
class SliverKlipyMixedMasonryGrid extends SliverMultiBoxAdaptorWidget {
  const SliverKlipyMixedMasonryGrid({
    Key? key,
    required SliverChildDelegate delegate,
    required this.gridDelegate,
    required this.isFullSpan,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        super(key: key, delegate: delegate);

  SliverKlipyMixedMasonryGrid.count({
    Key? key,
    required int crossAxisCount,
    required IndexedWidgetBuilder itemBuilder,
    int? childCount,
    required bool Function(int index) isFullSpan,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
  }) : this(
          key: key,
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: childCount,
          ),
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
          ),
          isFullSpan: isFullSpan,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
        );

  final SliverSimpleGridDelegate gridDelegate;
  final bool Function(int index) isFullSpan;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  RenderSliverKlipyMixedMasonryGrid createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverKlipyMixedMasonryGrid(
      childManager: element,
      gridDelegate: gridDelegate,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      isFullSpan: isFullSpan,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverKlipyMixedMasonryGrid renderObject,
  ) {
    renderObject
      ..gridDelegate = gridDelegate
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing
      ..isFullSpan = isFullSpan;
  }
}
