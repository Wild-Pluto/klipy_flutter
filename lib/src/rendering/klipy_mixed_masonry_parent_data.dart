import 'package:flutter/rendering.dart';

class KlipyMixedMasonryParentData extends SliverMultiBoxAdaptorParentData {
  int? crossAxisIndex;
  double? lastMainAxisExtent;
  bool isFullSpan = false;

  @override
  String toString() =>
      'crossAxisIndex=$crossAxisIndex; isFullSpan=$isFullSpan; ${super.toString()}';
}

extension KlipyMixedMasonryParentDataApply on KlipyMixedMasonryParentData {
  void applyZero() {
    layoutOffset = 0.0;
    crossAxisIndex = 0;
    isFullSpan = false;
  }

  void apply(KlipyMixedMasonryParentData parentData) {
    layoutOffset = parentData.layoutOffset;
    crossAxisIndex = parentData.crossAxisIndex;
    isFullSpan = parentData.isFullSpan;
  }
}
