// ignore_for_file: implementation_imports
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/src/foundation/extensions.dart';
import 'package:flutter_staggered_grid_view/src/rendering/sliver_simple_grid_delegate.dart';
import 'package:klipy_flutter/src/rendering/klipy_mixed_masonry_parent_data.dart';

class RenderSliverKlipyMixedMasonryGrid extends RenderSliverMultiBoxAdaptor {
  RenderSliverKlipyMixedMasonryGrid({
    required RenderSliverBoxChildManager childManager,
    required SliverSimpleGridDelegate gridDelegate,
    required double mainAxisSpacing,
    required double crossAxisSpacing,
    required bool Function(int index) isFullSpan,
  }) : assert(mainAxisSpacing >= 0),
       assert(crossAxisSpacing >= 0),
       _gridDelegate = gridDelegate,
       _mainAxisSpacing = mainAxisSpacing,
       _crossAxisSpacing = crossAxisSpacing,
       _isFullSpan = isFullSpan,
       super(childManager: childManager);
  bool Function(int index) _isFullSpan;
  bool Function(int index) get isFullSpan => _isFullSpan;
  set isFullSpan(bool Function(int index) value) {
    _isFullSpan = value;
    markNeedsLayout();
  }

  SliverSimpleGridDelegate get gridDelegate => _gridDelegate;
  SliverSimpleGridDelegate _gridDelegate;
  set gridDelegate(SliverSimpleGridDelegate value) {
    if (_gridDelegate == value) {
      return;
    }
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) {
      return;
    }
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  double get crossAxisSpacing => _crossAxisSpacing;
  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing == value) {
      return;
    }
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! KlipyMixedMasonryParentData) {
      child.parentData = KlipyMixedMasonryParentData();
    }
  }

  KlipyMixedMasonryParentData _getParentData(RenderObject child) {
    return child.parentData as KlipyMixedMasonryParentData;
  }

  double _stride = 0;
  int Function(int) _getCrossAxisIndex = (int index) => index;
  @override
  double childCrossAxisPosition(RenderBox child) {
    if (_getParentData(child).isFullSpan) {
      return 0;
    }
    final raw = _childCrossAxisIndex(child);
    return _getCrossAxisIndex(_safeCrossAxisIndex(raw)) * _stride;
  }

  int? _childCrossAxisIndex(RenderBox child) {
    return _getParentData(child).crossAxisIndex;
  }

  final _previousCrossAxisIndexes = <int>[];
  final _previousMainAxisExtents = <double>[];
  int _layoutCrossAxisCount = 1;

  int _safeCrossAxisIndex(int? raw) {
    final n = _layoutCrossAxisCount;
    if (n <= 0) return 0;
    final v = raw ?? 0;
    if (v < 0) return 0;
    if (v >= n) return n - 1;
    return v;
  }

  /// [_isFullSpan] may index app data; the sliver sometimes probes `index ==
  /// childCount` during layout — never forward those indices.
  bool _isFullSpanIndexSafe(int index) {
    if (index < 0) return false;
    final cap = childManager.estimatedChildCount;
    if (cap != null && index >= cap) return false;
    return _isFullSpan(index);
  }

  @override
  bool addInitialChild({int index = 0, double layoutOffset = 0.0}) {
    final hasFirstChild = super.addInitialChild(
      index: index,
      layoutOffset: layoutOffset,
    );
    if (hasFirstChild) {
      final parentData = _getParentData(firstChild!);
      parentData.applyZero();
    }
    return hasFirstChild;
  }

  @override
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    int count = leadingGarbage;
    RenderBox? child = firstChild!;
    while (count > 0 && child != null) {
      final crossAxisIndex = _childCrossAxisIndex(child);
      if (crossAxisIndex != null) {
        _previousCrossAxisIndexes.add(crossAxisIndex);
        _previousMainAxisExtents.add(paintExtentOf(child));
      }
      child = childAfter(child);
      count -= 1;
    }
    super.collectGarbage(leadingGarbage, trailingGarbage);
  }

  @override
  RenderBox? insertAndLayoutLeadingChild(
    BoxConstraints childConstraints, {
    bool parentUsesSize = false,
  }) {
    final child = super.insertAndLayoutLeadingChild(
      childConstraints,
      parentUsesSize: parentUsesSize,
    );
    if (child != null) {
      final idx = indexOf(child);
      final parentData = _getParentData(child);
      parentData.isFullSpan = false;
      if (_isFullSpanIndexSafe(idx)) {
        child.layout(
          constraints.asBoxConstraints(
            crossAxisExtent: constraints.crossAxisExtent,
          ),
          parentUsesSize: parentUsesSize,
        );
      }
      parentData.crossAxisIndex =
          _previousCrossAxisIndexes.isNotEmpty
              ? _previousCrossAxisIndexes.removeLast()
              : 0;
      parentData.lastMainAxisExtent =
          _previousMainAxisExtents.isNotEmpty
              ? _previousMainAxisExtents.removeLast()
              : 0;
      if (_isFullSpanIndexSafe(idx)) {
        parentData.crossAxisIndex = 0;
      }
    }
    return child;
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    final crossAxisCount = _gridDelegate.getCrossAxisCount(
      constraints,
      crossAxisSpacing,
    );
    if (crossAxisCount <= 0) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }
    _layoutCrossAxisCount = crossAxisCount;
    RenderBox? walk = firstChild;
    while (walk != null) {
      final pd = _getParentData(walk);
      pd.isFullSpan = false;
      final ci = pd.crossAxisIndex;
      if (ci != null && (ci < 0 || ci >= crossAxisCount)) {
        pd.crossAxisIndex = _safeCrossAxisIndex(ci);
      }
      walk = childAfter(walk);
    }
    _getCrossAxisIndex =
        axisDirectionIsReversed(constraints.crossAxisDirection)
            ? (int index) => crossAxisCount - index - 1
            : (int index) => index;
    _stride = (constraints.crossAxisExtent + crossAxisSpacing) / crossAxisCount;
    final childCrossAxisExtent = _stride - crossAxisSpacing;
    final columnChildConstraints = constraints.asBoxConstraints(
      crossAxisExtent: childCrossAxisExtent,
    );

    BoxConstraints constraintsForIndex(int index) {
      if (_isFullSpanIndexSafe(index)) {
        return constraints.asBoxConstraints(
          crossAxisExtent: constraints.crossAxisExtent,
        );
      }
      return columnChildConstraints;
    }

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    final double remainingExtent = constraints.remainingCacheExtent;
    final double targetEndScrollOffset = scrollOffset + remainingExtent;
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;
    final scrollOffsets = List.filled(crossAxisCount, 0.0);
    double positionChild(RenderBox child) {
      final idx = indexOf(child);
      final childParentData = _getParentData(child);
      if (_isFullSpanIndexSafe(idx)) {
        childParentData.isFullSpan = true;
        final layoutStart = scrollOffsets.reduce(math.max);
        childParentData.layoutOffset = layoutStart;
        childParentData.crossAxisIndex = 0;
        child.layout(
          constraints.asBoxConstraints(
            crossAxisExtent: constraints.crossAxisExtent,
          ),
          parentUsesSize: true,
        );
        final bottom =
            childScrollOffset(child)! + paintExtentOf(child) + mainAxisSpacing;
        for (var i = 0; i < crossAxisCount; i++) {
          scrollOffsets[i] = bottom;
        }
        return bottom;
      }
      childParentData.isFullSpan = false;
      final crossAxisIndex = scrollOffsets.findSmallestIndexWithMinimumValue();
      childParentData.layoutOffset = scrollOffsets[crossAxisIndex];
      childParentData.crossAxisIndex = crossAxisIndex;
      scrollOffsets[crossAxisIndex] =
          childScrollOffset(child)! + paintExtentOf(child) + mainAxisSpacing;
      return scrollOffsets[crossAxisIndex];
    }

    if (firstChild == null) {
      if (!addInitialChild()) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }
    RenderBox? leadingChildWithLayout, trailingChildWithLayout;
    RenderBox? earliestUsefulChild = firstChild;
    if (childScrollOffset(firstChild!) == null) {
      int leadingChildrenWithoutLayoutOffset = 0;
      while (earliestUsefulChild != null &&
          childScrollOffset(earliestUsefulChild) == null) {
        earliestUsefulChild = childAfter(earliestUsefulChild);
        leadingChildrenWithoutLayoutOffset += 1;
      }
      collectGarbage(leadingChildrenWithoutLayoutOffset, 0);
      if (firstChild == null) {
        if (!addInitialChild()) {
          geometry = SliverGeometry.zero;
          childManager.didFinishLayout();
          return;
        }
      }
    }
    scrollOffsets.fillRange(0, crossAxisCount, double.infinity);
    KlipyMixedMasonryParentData computeFirstChildParentData() {
      final firstChildParentData = _getParentData(firstChild!);
      final mainAxisExtent =
          firstChildParentData.lastMainAxisExtent! + mainAxisSpacing;
      final crossAxisIndex = _safeCrossAxisIndex(
        firstChildParentData.crossAxisIndex,
      );
      double offset = scrollOffsets[crossAxisIndex] - mainAxisExtent;
      for (int i = 0; i < crossAxisCount; i++) {
        if (i == crossAxisIndex) {
          continue;
        }
        final otherOffset = scrollOffsets[i];
        if ((offset - otherOffset).abs() < precisionErrorTolerance) {
          offset = otherOffset;
          break;
        }
      }
      return KlipyMixedMasonryParentData()
        ..layoutOffset = offset
        ..crossAxisIndex = crossAxisIndex
        ..isFullSpan = firstChildParentData.isFullSpan;
    }

    RenderBox? child = firstChild;
    if (child != null && indexOf(child) == 0) {
      final firstChildParentData = _getParentData(child);
      firstChildParentData.crossAxisIndex = 0;
    }
    while (child != null && scrollOffsets.any((x) => x.isInfinite)) {
      final crossI = _childCrossAxisIndex(child);
      if (crossI != null) {
        final childMainOffset = childScrollOffset(child)!;
        final idx = indexOf(child);
        if (_isFullSpanIndexSafe(idx)) {
          for (var i = 0; i < crossAxisCount; i++) {
            if (scrollOffsets[i] == double.infinity) {
              scrollOffsets[i] = childMainOffset;
            }
          }
        } else {
          if (scrollOffsets[_safeCrossAxisIndex(crossI)] == double.infinity) {
            scrollOffsets[_safeCrossAxisIndex(crossI)] = childMainOffset;
          }
        }
      }
      child = childAfter(child);
    }
    earliestUsefulChild = firstChild;
    while (scrollOffsets.any((x) => x > scrollOffset)) {
      earliestUsefulChild = insertAndLayoutLeadingChild(
        columnChildConstraints,
        parentUsesSize: true,
      );
      if (earliestUsefulChild == null) {
        final childParentData = _getParentData(firstChild!);
        childParentData.layoutOffset = 0;
        if (scrollOffset == 0) {
          firstChild!.layout(
            constraintsForIndex(indexOf(firstChild!)),
            parentUsesSize: true,
          );
          earliestUsefulChild = firstChild;
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          geometry = SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          );
          return;
        }
      }
      final earliestScrollOffset = scrollOffsets.reduce(math.min);
      if (earliestScrollOffset < -precisionErrorTolerance) {
        geometry = SliverGeometry(
          scrollOffsetCorrection: -earliestScrollOffset,
        );
        final childParentData = _getParentData(firstChild!);
        final compute = computeFirstChildParentData();
        childParentData.apply(compute);
        childParentData.layoutOffset = 0;
        return;
      }
      final firstChildParentData = computeFirstChildParentData();
      final childParentData = _getParentData(earliestUsefulChild);
      childParentData.apply(firstChildParentData);
      if (firstChildParentData.isFullSpan) {
        for (var i = 0; i < crossAxisCount; i++) {
          scrollOffsets[i] = firstChildParentData.layoutOffset!;
        }
      } else {
        scrollOffsets[_safeCrossAxisIndex(
              firstChildParentData.crossAxisIndex,
            )] =
            firstChildParentData.layoutOffset!;
      }
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }
    if (scrollOffset < precisionErrorTolerance) {
      while (indexOf(firstChild!) > 0) {
        final childParentData = _getParentData(firstChild!);
        earliestUsefulChild = insertAndLayoutLeadingChild(
          columnChildConstraints,
          parentUsesSize: true,
        );
        final firstChildParentData = computeFirstChildParentData();
        childParentData.apply(firstChildParentData);
        final firstChildScrollOffset = firstChildParentData.layoutOffset!;
        if (firstChildScrollOffset < -precisionErrorTolerance) {
          geometry = SliverGeometry(
            scrollOffsetCorrection: -firstChildScrollOffset,
          );
          return;
        }
      }
    }
    if (leadingChildWithLayout == null) {
      final firstVisible = earliestUsefulChild!;
      firstVisible.layout(
        constraintsForIndex(indexOf(firstVisible)),
        parentUsesSize: true,
      );
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }
    final leadingScrollOffset = scrollOffsets.reduce(math.min);
    bool inLayoutRange = true;
    child = earliestUsefulChild;
    final laidOut = child!;
    int index = indexOf(laidOut);
    final firstLaidOutChild = laidOut;
    final firstIdx = indexOf(firstLaidOutChild);
    final firstPd = _getParentData(firstLaidOutChild);
    firstPd.isFullSpan = _isFullSpanIndexSafe(firstIdx);
    final firstBottom =
        childScrollOffset(firstLaidOutChild)! +
        paintExtentOf(firstLaidOutChild) +
        mainAxisSpacing;
    if (firstPd.isFullSpan) {
      for (var i = 0; i < crossAxisCount; i++) {
        scrollOffsets[i] = firstBottom;
      }
    } else {
      scrollOffsets[_safeCrossAxisIndex(firstPd.crossAxisIndex)] = firstBottom;
    }
    for (int i = 0; i < scrollOffsets.length; i++) {
      if (scrollOffsets[i] == double.infinity) {
        scrollOffsets[i] = 0.0;
      }
    }
    bool foundFirstVisibleChild = scrollOffsets.any(
      (scrollOffset) => scrollOffset >= constraints.scrollOffset,
    );
    bool advance() {
      if (child == trailingChildWithLayout) {
        inLayoutRange = false;
      }
      child = childAfter(child!);
      if (child == null) {
        inLayoutRange = false;
      }
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child!) != index) {
          child = insertAndLayoutChild(
            constraintsForIndex(index),
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          if (child == null) {
            return false;
          }
        } else {
          child!.layout(constraintsForIndex(index), parentUsesSize: true);
        }
        trailingChildWithLayout = child;
      }
      positionChild(child!);
      if (!foundFirstVisibleChild &&
          scrollOffsets.any(
            (scrollOffset) => scrollOffset >= constraints.scrollOffset,
          )) {
        foundFirstVisibleChild = true;
      }
      return true;
    }

    while (scrollOffsets.every(
      (offset) => offset - mainAxisSpacing < scrollOffset,
    )) {
      leadingGarbage += 1;
      if (!advance()) {
        collectGarbage(leadingGarbage - 1, 0);
        final double extent = scrollOffsets.reduce(math.max) - mainAxisSpacing;
        geometry = SliverGeometry(
          scrollExtent: extent,
          maxPaintExtent: extent,
        );
        return;
      }
    }
    while (scrollOffsets.any(
      (offset) => offset - mainAxisSpacing < targetEndScrollOffset,
    )) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }
    if (child != null) {
      child = childAfter(child!);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child!);
      }
    }
    collectGarbage(leadingGarbage, trailingGarbage);
    final endScrollOffset = scrollOffsets.reduce(math.max) - mainAxisSpacing;
    final double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild!),
        lastIndex: indexOf(lastChild!),
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: endScrollOffset,
      );
    }
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      hasVisualOverflow:
          endScrollOffset > targetEndScrollOffsetForPaint ||
          constraints.scrollOffset > 0.0,
    );
    if (estimatedMaxScrollOffset == endScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}
