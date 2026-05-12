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
}
