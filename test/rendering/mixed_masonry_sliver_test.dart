import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klipy_flutter/src/components/sliver_klipy_mixed_masonry_grid.dart';

void main() {
  testWidgets(
    'SliverKlipyMixedMasonryGrid: 8 items, one full-span, no layout exceptions',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverKlipyMixedMasonryGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childCount: 8,
                  isFullSpan: (i) => i == 4,
                  itemBuilder: (context, i) {
                    if (i == 4) {
                      return const SizedBox(height: 40, child: Text('ad'));
                    }
                    return SizedBox(
                      height: 40.0 + (i % 3) * 12,
                      child: Text('cell $i'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'isFullSpan / itemBuilder never see index outside 0..childCount-1 (N=8)',
    (WidgetTester tester) async {
      const n = 8;
      var maxIsFullSpan = -1;
      var maxBuilder = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverKlipyMixedMasonryGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childCount: n,
                  isFullSpan: (i) {
                    expect(i, greaterThanOrEqualTo(0));
                    expect(i, lessThan(n));
                    if (i > maxIsFullSpan) maxIsFullSpan = i;
                    return i == 4;
                  },
                  itemBuilder: (context, i) {
                    expect(i, greaterThanOrEqualTo(0));
                    expect(i, lessThan(n));
                    if (i > maxBuilder) maxBuilder = i;
                    if (i == 4) {
                      return const SizedBox(height: 40, child: Text('ad'));
                    }
                    return SizedBox(
                      height: 40.0 + (i % 3) * 12,
                      child: Text('$i'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      expect(maxIsFullSpan, lessThan(n));
      expect(maxBuilder, lessThan(n));
    },
  );

  testWidgets(
    'full-span slot keeps cross-axis extent after pagination (no column width)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const crossAxisCount = 2;
      const crossAxisSpacing = 4.0;
      final widthsAtIndex4 = <double>[];

      Future<void> pumpWithCount(int childCount) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverKlipyMixedMasonryGrid.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: 4,
                    childCount: childCount,
                    isFullSpan: (i) => i == 4,
                    itemBuilder: (context, i) {
                      if (i == 4) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            widthsAtIndex4.add(constraints.maxWidth);
                            return SizedBox(
                              height: 40,
                              width: constraints.maxWidth,
                              child: const Text('wide-ad'),
                            );
                          },
                        );
                      }
                      return SizedBox(
                        height: 40.0 + (i % 3) * 12,
                        child: Text('cell $i'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpWithCount(8);
      expect(tester.takeException(), isNull);

      const viewportW = 412.0;
      final columnW =
          (viewportW - crossAxisSpacing * (crossAxisCount - 1)) /
          crossAxisCount;
      expect(columnW, closeTo(204, 1));

      void assertWideNotColumnWidth() {
        expect(widthsAtIndex4, isNotEmpty);
        for (final w in widthsAtIndex4) {
          expect(
            w,
            greaterThan(columnW + 40),
            reason: 'full-span should exceed one column (~$columnW), got $w',
          );
        }
      }

      assertWideNotColumnWidth();
      widthsAtIndex4.clear();

      await pumpWithCount(16);
      expect(tester.takeException(), isNull);
      assertWideNotColumnWidth();
    },
  );
}
