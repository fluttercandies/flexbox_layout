import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _TickerHost extends StatefulWidget {
  const _TickerHost({required this.controller});

  final FlexboxScaleController controller;

  @override
  State<_TickerHost> createState() => _TickerHostState();
}

class _TickerHostState extends State<_TickerHost>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.controller.attachTickerProvider(this);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

void main() {
  test('onScaleEnd snaps to nearest point when snap is enabled', () {
    final controller = FlexboxScaleController(
      initialExtent: 150,
      minExtent: 100,
      maxExtent: 300,
      snapPoints: const [100, 140, 180, 220, 260, 300],
      enableSnap: true,
    );

    controller.onScaleStart(ScaleStartDetails());
    controller.onScaleUpdate(ScaleUpdateDetails(scale: 1.12));
    controller.onScaleEnd(ScaleEndDetails(velocity: Velocity.zero));

    expect(controller.isScaling, isFalse);
    expect(controller.currentExtent, 180);
    expect(controller.fillFactor, 1.0);
  });

  test('onScaleEnd keeps extent when snap is disabled', () {
    final controller = FlexboxScaleController(
      initialExtent: 150,
      minExtent: 100,
      maxExtent: 300,
      snapPoints: const [100, 140, 180, 220, 260, 300],
      enableSnap: false,
    );

    controller.onScaleStart(ScaleStartDetails());
    controller.onScaleUpdate(ScaleUpdateDetails(scale: 1.12));
    controller.onScaleEnd(ScaleEndDetails(velocity: Velocity.zero));

    expect(controller.isScaling, isFalse);
    expect(controller.currentExtent, closeTo(168, 1e-9));
    expect(controller.fillFactor, 1.0);
  });

  testWidgets('animateToExtent emits intermediate values with ticker',
      (tester) async {
    final controller = FlexboxScaleController(
      initialExtent: 150,
      minExtent: 100,
      maxExtent: 300,
      snapPoints: const [100, 140, 180, 220, 260, 300],
      enableSnap: true,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: _TickerHost(controller: controller),
    ));

    final values = <double>[];
    controller.addListener(() {
      final current = controller.currentExtent;
      if (values.isEmpty || (values.last - current).abs() > 1e-6) {
        values.add(current);
      }
    });

    controller.animateToExtent(220);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpAndSettle();

    expect(controller.currentExtent, closeTo(220, 1e-3));
    expect(values.length, greaterThan(1));
  });
}
