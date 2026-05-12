import 'package:flutter_test/flutter_test.dart';
import 'package:klipy_dart/klipy_dart.dart';
import 'package:klipy_flutter/src/layout/klipy_feed_row_layout_calculator.dart';

Map<String, dynamic> _gifJson(String id, List<int> dims) => {
  'id': id,
  'created': 0,
  'hasaudio': false,
  'hascaption': false,
  'itemurl': 'https://klipy.com/$id',
  'tags': <String>[],
  'title': id,
  'content_description': '',
  'url': 'https://klipy.com/$id',
  'media_formats': {
    'tinygif': {
      'url': 'https://example.com/$id.gif',
      'dims': dims,
      'duration': 0,
      'size': 1,
    },
  },
};

KlipyGifFeedItem _gif(String id, List<int> dims) =>
    KlipyFeedItem.fromJson(_gifJson(id, dims)) as KlipyGifFeedItem;

KlipyAdFeedItem _ad(int w, int h) => KlipyAdFeedItem.fromJson({
  'type': 'ad',
  'content': '<html></html>',
  'width': w,
  'height': h,
});

void _expectApprox(double a, double b, {double eps = 0.5}) {
  expect((a - b).abs(), lessThan(eps), reason: '$a vs $b');
}

void main() {
  const cw = 360.0;
  final calc = KlipyFeedRowLayoutCalculator(
    containerWidth: cw,
    crossAxisSpacing: 8,
    maxCellsPerRow: 2,
    wideAdAspectThreshold: 2,
    minRowHeight: 50,
    maxAdRowVisualHeight: 200,
    maxGifRowHeight: 360,
    adMaxResizePercent: 0.25,
  );

  test('two square gifs share one row; widths + spacing match container', () {
    final rows = calc.computeRows([_gif('a', [100, 100]), _gif('b', [80, 80])]);
    expect(rows, hasLength(1));
    expect(rows.single.cells, hasLength(2));
    final wSum =
        rows.single.cells[0].width + rows.single.cells[1].width + 8;
    _expectApprox(wSum, cw);
    expect(rows.single.cells[0].sourceIndex, 0);
    expect(rows.single.cells[1].sourceIndex, 1);
  });

  test('wide ad is not paired; follows a single-gif row', () {
    final rows = calc.computeRows([
      _gif('a', [100, 100]),
      _ad(320, 100),
    ]);
    expect(rows, hasLength(2));
    expect(rows[0].cells, hasLength(1));
    expect(rows[1].cells, hasLength(1));
    expect(rows[1].cells.single.item, isA<KlipyAdFeedItem>());
    expect(rows[1].cells.single.width, cw);
  });

  test('wide ad alone gets full width and capped height', () {
    final rows = calc.computeRows([_ad(320, 100)]);
    expect(rows, hasLength(1));
    final cell = rows.single.cells.single;
    expect(cell.width, cw);
    expect(cell.height, lessThanOrEqualTo(200));
  });

  test('narrow ad pairs with a gif in one row', () {
    final rows = calc.computeRows([_gif('a', [100, 100]), _ad(150, 150)]);
    expect(rows, hasLength(1));
    expect(rows.single.cells, hasLength(2));
  });

  test('recently_used_keep_alive yields zero-height row', () {
    const placeholder = KlipyUnknownFeedItem(
      payload: <String, dynamic>{},
      rawType: 'recently_used_keep_alive',
    );
    final rows = calc.computeRows([placeholder]);
    expect(rows.single.height, 0);
    expect(rows.single.cells.single.height, 0);
  });
}
