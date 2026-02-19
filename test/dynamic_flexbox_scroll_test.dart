import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _IntrinsicRatioBox extends LeafRenderObjectWidget {
  const _IntrinsicRatioBox({
    required this.controller,
    super.key,
  });

  final ValueNotifier<double> controller;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderIntrinsicRatioBox(controller);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderIntrinsicRatioBox renderObject,
  ) {
    renderObject.controller = controller;
  }
}

class _RenderIntrinsicRatioBox extends RenderBox {
  _RenderIntrinsicRatioBox(this._controller);

  ValueNotifier<double> _controller;

  set controller(ValueNotifier<double> value) {
    if (identical(_controller, value)) return;
    if (attached) {
      _controller.removeListener(_handleRatioChanged);
    }
    _controller = value;
    if (attached) {
      _controller.addListener(_handleRatioChanged);
    }
    markNeedsLayout();
  }

  void _handleRatioChanged() {
    markNeedsLayout();
  }

  double get _ratio {
    final value = _controller.value;
    if (value.isFinite && value > 0.0) {
      return value;
    }
    return 1.0;
  }

  static const double _baseExtent = 100.0;

  @override
  double computeMaxIntrinsicWidth(double height) => _baseExtent * _ratio;

  @override
  double computeMinIntrinsicWidth(double height) => _baseExtent * _ratio;

  @override
  double computeMaxIntrinsicHeight(double width) => _baseExtent;

  @override
  double computeMinIntrinsicHeight(double width) => _baseExtent;

  @override
  void performLayout() {
    size = constraints.constrain(const Size(_baseExtent, _baseExtent));
  }

  @override
  void detach() {
    _controller.removeListener(_handleRatioChanged);
    super.detach();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.addListener(_handleRatioChanged);
  }
}

void _verifyVisibleChildLayoutIntegrity(
    RenderSliverDynamicFlexbox renderSliver) {
  final rows = <double, List<RenderBox>>{};
  for (RenderBox? child = renderSliver.firstChild;
      child != null;
      child = renderSliver.childAfter(child)) {
    final parentData = child.parentData! as SliverDynamicFlexboxParentData;
    expect(parentData.layoutOffset, isNotNull);
    expect(parentData.crossAxisOffset >= 0.0, isTrue);
    expect(child.size.width > 0.0, isTrue);
    expect(child.size.height > 0.0, isTrue);

    final rowKey = parentData.layoutOffset!;
    rows.putIfAbsent(rowKey, () => <RenderBox>[]).add(child);
  }

  for (final rowChildren in rows.values) {
    rowChildren.sort((a, b) {
      final aData = a.parentData! as SliverDynamicFlexboxParentData;
      final bData = b.parentData! as SliverDynamicFlexboxParentData;
      return aData.crossAxisOffset.compareTo(bData.crossAxisOffset);
    });

    double trailing = -1.0;
    for (final child in rowChildren) {
      final data = child.parentData! as SliverDynamicFlexboxParentData;
      final leading = data.crossAxisOffset;
      expect(leading + 0.01 >= trailing, isTrue);
      trailing = leading + child.size.width;
    }
  }
}

void main() {
  testWidgets('DynamicFlexboxList keeps valid layout after scrolling',
      (tester) async {
    final ratios = List<double>.generate(
      600,
      (index) => 0.75 + (index % 7) * 0.2,
      growable: false,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 420,
          height: 720,
          child: DynamicFlexboxList(
            itemCount: ratios.length,
            targetRowHeight: 180,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            aspectRatioGetter: (index) => ratios[index],
            itemBuilder: (context, index) {
              return SizedBox(
                height: 100,
                child: ColoredBox(
                  color: Color(0xFF000000 + (index % 255)),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    RenderSliverDynamicFlexbox renderSliver =
        tester.renderObject(find.byType(SliverDynamicFlexbox));
    expect(renderSliver.geometry, isNotNull);
    expect(renderSliver.geometry!.paintExtent > 0, isTrue);
    _verifyVisibleChildLayoutIntegrity(renderSliver);

    await tester.drag(find.byType(DynamicFlexboxList), const Offset(0, -2500));
    await tester.pumpAndSettle();
    renderSliver = tester.renderObject(find.byType(SliverDynamicFlexbox));
    expect(renderSliver.geometry, isNotNull);
    expect(renderSliver.geometry!.paintExtent > 0, isTrue);
    _verifyVisibleChildLayoutIntegrity(renderSliver);

    await tester.drag(find.byType(DynamicFlexboxList), const Offset(0, 1800));
    await tester.pumpAndSettle();
    renderSliver = tester.renderObject(find.byType(SliverDynamicFlexbox));
    expect(renderSliver.geometry, isNotNull);
    expect(renderSliver.geometry!.paintExtent > 0, isTrue);
    _verifyVisibleChildLayoutIntegrity(renderSliver);
  });

  testWidgets('DynamicFlexboxList keeps valid layout after viewport resize',
      (tester) async {
    final ratios = List<double>.generate(
      600,
      (index) => 0.75 + (index % 7) * 0.2,
      growable: false,
    );

    Widget buildGallery(double width) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: width,
          height: 720,
          child: DynamicFlexboxList(
            itemCount: ratios.length,
            targetRowHeight: 180,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            aspectRatioGetter: (index) => ratios[index],
            itemBuilder: (context, index) {
              return SizedBox(
                height: 100,
                child: ColoredBox(
                  color: Color(0xFF000000 + (index % 255)),
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildGallery(420));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(DynamicFlexboxList), const Offset(0, -1800));
    await tester.pumpAndSettle();

    var renderSliver = tester.renderObject<RenderSliverDynamicFlexbox>(
      find.byType(SliverDynamicFlexbox),
    );
    _verifyVisibleChildLayoutIntegrity(renderSliver);

    await tester.pumpWidget(buildGallery(320));
    await tester.pumpAndSettle();

    renderSliver = tester.renderObject<RenderSliverDynamicFlexbox>(
      find.byType(SliverDynamicFlexbox),
    );
    _verifyVisibleChildLayoutIntegrity(renderSliver);
  });

  testWidgets('DynamicFlexboxList keeps non-empty geometry during rapid scroll',
      (tester) async {
    final ratios = List<double>.generate(
      1200,
      (index) => 0.7 + (index % 9) * 0.15,
      growable: false,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 420,
          height: 720,
          child: DynamicFlexboxList(
            itemCount: ratios.length,
            targetRowHeight: 170,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            aspectRatioGetter: (index) => ratios[index],
            itemBuilder: (context, index) {
              return SizedBox(
                height: 100,
                child: ColoredBox(
                  color: Color(0xFF000000 + (index % 255)),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (int i = 0; i < 8; i++) {
      await tester.drag(find.byType(DynamicFlexboxList), const Offset(0, -900));
      await tester.pump(const Duration(milliseconds: 16));

      final renderSliver = tester.renderObject<RenderSliverDynamicFlexbox>(
        find.byType(SliverDynamicFlexbox),
      );
      expect(renderSliver.firstChild, isNotNull);
      final geometry = renderSliver.geometry;
      expect(geometry, isNotNull);
      expect(geometry!.paintExtent > 0, isTrue);
      _verifyVisibleChildLayoutIntegrity(renderSliver);
    }
  });

  testWidgets(
      'DynamicFlexboxList updates reattached cached item after intrinsic ratio changes',
      (tester) async {
    final controllers = List<ValueNotifier<double>>.generate(
      260,
      (_) => ValueNotifier<double>(1.0),
      growable: false,
    );
    final scrollController = ScrollController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 420,
          height: 720,
          child: DynamicFlexboxList(
            itemCount: controllers.length,
            scrollController: scrollController,
            targetRowHeight: 180,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            debounceDuration: const Duration(milliseconds: 24),
            maxAspectRatioChecksPerLayout: 8,
            aspectRatioCheckInterval: 12,
            itemBuilder: (context, index) {
              return _IntrinsicRatioBox(
                key: ValueKey<String>('ratio-item-$index'),
                controller: controllers[index],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final targetFinder = find.byKey(const ValueKey<String>('ratio-item-0'));
    expect(targetFinder, findsOneWidget);
    final initialSize = tester.getSize(targetFinder);

    scrollController.jumpTo(4200.0);
    await tester.pumpAndSettle();

    controllers[0].value = 2.6;

    scrollController.jumpTo(0.0);
    await tester.pump();

    final staleSize = tester.getSize(targetFinder);

    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump();

    final updatedSize = tester.getSize(targetFinder);
    expect(updatedSize.width, isNot(staleSize.width));
    expect(updatedSize.height, isNot(staleSize.height));
    expect(updatedSize.width, isNot(initialSize.width));
    expect(updatedSize.height, isNot(initialSize.height));

    for (final controller in controllers) {
      controller.dispose();
    }
    scrollController.dispose();
  });
}
