import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flexbox/flexbox.dart';

void main() {
  group('FlexItemData', () {
    test('default values', () {
      const data = FlexItemData();
      expect(data.order, 1);
      expect(data.flexGrow, 0.0);
      expect(data.flexShrink, 1.0);
      expect(data.alignSelf, AlignSelf.auto);
      expect(data.flexBasisPercent, -1.0);
      expect(data.wrapBefore, false);
      expect(data.minWidth, null);
      expect(data.minHeight, null);
      expect(data.maxWidth, null);
      expect(data.maxHeight, null);
    });

    test('copyWith', () {
      const data = FlexItemData();
      final copied = data.copyWith(flexGrow: 2.0, order: 5);
      expect(copied.flexGrow, 2.0);
      expect(copied.order, 5);
      expect(copied.flexShrink, 1.0); // unchanged
    });

    test('equality', () {
      const data1 = FlexItemData(flexGrow: 1.0, order: 2);
      const data2 = FlexItemData(flexGrow: 1.0, order: 2);
      const data3 = FlexItemData(flexGrow: 2.0, order: 2);
      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });
  });

  group('Flexbox widget', () {
    testWidgets('renders children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Flexbox(
              children: [
                SizedBox(width: 100, height: 100),
                SizedBox(width: 100, height: 100),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Flexbox), findsOneWidget);
      expect(find.byType(SizedBox), findsNWidgets(2));
    });

    testWidgets('FlexItem wraps children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Flexbox(
              children: [
                FlexItem(flexGrow: 1, child: SizedBox(width: 100, height: 100)),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FlexItem), findsOneWidget);
    });

    testWidgets('flexGrow distributes space', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: Flexbox(
                flexDirection: FlexDirection.row,
                flexWrap: FlexWrap.noWrap,
                children: [
                  FlexItem(
                    flexGrow: 1,
                    child: Container(key: const Key('item1'), height: 50),
                  ),
                  FlexItem(
                    flexGrow: 2,
                    child: Container(key: const Key('item2'), height: 50),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1 = tester.getSize(find.byKey(const Key('item1')));
      final item2 = tester.getSize(find.byKey(const Key('item2')));

      // item2 should be approximately twice the width of item1
      expect(item2.width, closeTo(item1.width * 2, 1.0));
    });

    testWidgets('order changes layout order', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 100,
              child: Flexbox(
                flexDirection: FlexDirection.row,
                flexWrap: FlexWrap.noWrap,
                children: [
                  FlexItem(
                    order: 2,
                    child: SizedBox(
                      key: Key('item1'),
                      width: 100,
                      height: 50,
                    ),
                  ),
                  FlexItem(
                    order: 1,
                    child: SizedBox(
                      key: Key('item2'),
                      width: 100,
                      height: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1Pos = tester.getTopLeft(find.byKey(const Key('item1')));
      final item2Pos = tester.getTopLeft(find.byKey(const Key('item2')));

      // item2 (order: 1) should be before item1 (order: 2)
      expect(item2Pos.dx, lessThan(item1Pos.dx));
    });

    testWidgets('flexBasisPercent sets initial size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: Flexbox(
                flexDirection: FlexDirection.row,
                flexWrap: FlexWrap.noWrap,
                children: [
                  FlexItem(
                    flexBasisPercent: 0.5,
                    child: Container(key: const Key('item1'), height: 50),
                  ),
                  const SizedBox(key: Key('item2'), width: 100, height: 50),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1 = tester.getSize(find.byKey(const Key('item1')));

      // item1 should be 50% of parent width (400 * 0.5 = 200)
      expect(item1.width, closeTo(200, 1.0));
    });

    testWidgets('wrapBefore forces line break', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: Flexbox(
                flexDirection: FlexDirection.row,
                flexWrap: FlexWrap.wrap,
                children: [
                  SizedBox(key: Key('item1'), width: 100, height: 50),
                  FlexItem(
                    wrapBefore: true,
                    child: SizedBox(
                      key: Key('item2'),
                      width: 100,
                      height: 50,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1Pos = tester.getTopLeft(find.byKey(const Key('item1')));
      final item2Pos = tester.getTopLeft(find.byKey(const Key('item2')));

      // item2 should be on a new line (different y position)
      expect(item2Pos.dy, greaterThan(item1Pos.dy));
    });

    testWidgets('minWidth/maxWidth constraints are respected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: Flexbox(
                flexDirection: FlexDirection.row,
                flexWrap: FlexWrap.noWrap,
                children: [
                  FlexItem(
                    flexGrow: 1,
                    maxWidth: 100,
                    child: Container(key: const Key('item1'), height: 50),
                  ),
                  FlexItem(
                    flexGrow: 1,
                    child: Container(key: const Key('item2'), height: 50),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1 = tester.getSize(find.byKey(const Key('item1')));

      // item1 should be capped at maxWidth
      expect(item1.width, equals(100.0));
    });

    testWidgets('alignSelf overrides alignItems', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 100,
              child: Flexbox(
                flexDirection: FlexDirection.row,
                alignItems: AlignItems.flexStart,
                children: [
                  SizedBox(key: Key('item1'), width: 100, height: 30),
                  FlexItem(
                    alignSelf: AlignSelf.flexEnd,
                    child: SizedBox(
                      key: Key('item2'),
                      width: 100,
                      height: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final item1Rect = tester.getRect(find.byKey(const Key('item1')));
      final item2Rect = tester.getRect(find.byKey(const Key('item2')));

      // item1 should be at the top (flexStart)
      // item2 should be at the bottom (flexEnd via alignSelf)
      expect(item2Rect.bottom, greaterThan(item1Rect.bottom));
    });
  });

  group('Enums', () {
    test('FlexDirection.isVertical', () {
      expect(FlexDirection.row.isVertical, false);
      expect(FlexDirection.rowReverse.isVertical, false);
      expect(FlexDirection.column.isVertical, true);
      expect(FlexDirection.columnReverse.isVertical, true);
    });

    test('FlexDirection.isHorizontal', () {
      expect(FlexDirection.row.isHorizontal, true);
      expect(FlexDirection.rowReverse.isHorizontal, true);
      expect(FlexDirection.column.isHorizontal, false);
      expect(FlexDirection.columnReverse.isHorizontal, false);
    });

    test('FlexDirection.isReversed', () {
      expect(FlexDirection.row.isReversed, false);
      expect(FlexDirection.rowReverse.isReversed, true);
      expect(FlexDirection.column.isReversed, false);
      expect(FlexDirection.columnReverse.isReversed, true);
    });
  });
}
