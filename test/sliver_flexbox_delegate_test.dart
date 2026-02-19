import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const SliverConstraints _testConstraints = SliverConstraints(
  axisDirection: AxisDirection.down,
  growthDirection: GrowthDirection.forward,
  userScrollDirection: ScrollDirection.idle,
  scrollOffset: 0,
  precedingScrollExtent: 0,
  overlap: 0,
  remainingPaintExtent: 1000,
  crossAxisExtent: 320,
  crossAxisDirection: AxisDirection.right,
  viewportMainAxisExtent: 1000,
  remainingCacheExtent: 1000,
  cacheOrigin: 0,
);

void main() {
  test('fixedCrossAxisCount applies maxLines limit', () {
    const delegate = SliverFlexboxDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      maxLines: 2,
    );

    final layout = delegate.getLayout(_testConstraints, childCount: 20);
    expect(layout.lines.length, 2);
    expect(layout.lines.last.lastIndex, 5);
  });

  test('maxCrossAxisExtent applies maxLines limit', () {
    const delegate = SliverFlexboxDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 100,
      maxLines: 2,
    );

    final layout = delegate.getLayout(_testConstraints, childCount: 20);
    expect(layout.lines.length, 2);
    expect(layout.lines.last.lastIndex, 7);
  });

  test('fixedCrossAxisCount clamps negative usable extent when spacing is huge',
      () {
    const delegate = SliverFlexboxDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 300,
      childAspectRatio: 1,
    );

    final layout = delegate.getLayout(_testConstraints, childCount: 3);
    expect(layout.lines, isNotEmpty);
    for (final line in layout.lines) {
      expect(line.mainAxisExtent >= 0, isTrue);
      for (final item in line.items) {
        expect(item.mainAxisExtent >= 0, isTrue);
      }
    }
  });

  test('aspectRatio delegate keeps overflow items in last allowed line', () {
    final delegate = SliverFlexboxDelegateWithAspectRatios(
      aspectRatios: const [1, 1, 1, 1, 1],
      targetRowHeight: 100,
      maxLines: 1,
    );

    final layout = delegate.getLayout(_testConstraints, childCount: 5);
    expect(layout.lines.length, 1);
    expect(layout.lines.first.itemCount, 5);
  });

  test('directExtent delegate keeps overflow items in last allowed line', () {
    const delegate = SliverFlexboxDelegateWithDirectExtent(
      aspectRatios: [1, 1, 1, 1, 1],
      targetExtent: 100,
      maxLines: 1,
    );

    final layout = delegate.getLayout(_testConstraints, childCount: 5);
    expect(layout.lines.length, 1);
    expect(layout.lines.first.itemCount, 5);
  });
}
