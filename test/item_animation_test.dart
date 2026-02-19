import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexboxItemAnimationController', () {
    test('animates unseen items once in auto mode', () {
      final controller = FlexboxItemAnimationController.auto();

      expect(
        controller.shouldStartAnimation(index: 0, animationId: 'a'),
        isTrue,
      );
      controller.markAnimationStarted(index: 0, animationId: 'a');

      expect(
        controller.shouldStartAnimation(index: 0, animationId: 'a'),
        isFalse,
      );
      expect(
        controller.shouldStartAnimation(index: 1, animationId: 'b'),
        isTrue,
      );
    });

    test('batch mode only animates queued range', () {
      final controller = FlexboxItemAnimationController.manual();

      expect(
          controller.shouldStartAnimation(index: 4, animationId: 4), isFalse);

      controller.enqueueRange(startIndex: 5, endIndexInclusive: 7);

      expect(
          controller.shouldStartAnimation(index: 4, animationId: 4), isFalse);
      expect(controller.shouldStartAnimation(index: 5, animationId: 5), isTrue);
      expect(controller.shouldStartAnimation(index: 7, animationId: 7), isTrue);

      controller.markAnimationStarted(index: 6, animationId: 6);
      expect(
          controller.shouldStartAnimation(index: 6, animationId: 6), isFalse);
    });

    test('reset can preserve or clear animation history', () {
      final controller = FlexboxItemAnimationController.auto();

      controller.markAnimationStarted(index: 0, animationId: 'a');
      controller.reset(keepAnimationHistory: true);
      expect(
        controller.shouldStartAnimation(index: 0, animationId: 'a'),
        isFalse,
      );

      controller.reset();
      expect(
        controller.shouldStartAnimation(index: 0, animationId: 'a'),
        isTrue,
      );
    });

    test('stagger step remains stable across multiple queued batches', () {
      final controller = FlexboxItemAnimationController.manual();

      controller.enqueueRange(startIndex: 10, endIndexInclusive: 12);
      controller.enqueueRange(startIndex: 20, endIndexInclusive: 22);

      expect(controller.staggerStepFor(10), 0);
      expect(controller.staggerStepFor(11), 1);
      expect(controller.staggerStepFor(20), 0);
      expect(controller.staggerStepFor(22), 2);
    });

    test('prunes old animation ids when cache exceeds max', () {
      final controller = FlexboxItemAnimationController.auto(
        maxTrackedAnimationIds: 2,
      );

      controller.markAnimationStarted(index: 0, animationId: 'a');
      controller.markAnimationStarted(index: 1, animationId: 'b');
      controller.markAnimationStarted(index: 2, animationId: 'c');

      expect(controller.trackedAnimationIdCount, 2);
      expect(
          controller.shouldStartAnimation(index: 0, animationId: 'a'), isTrue);
      expect(
        controller.shouldStartAnimation(index: 1, animationId: 'b'),
        isFalse,
      );
      expect(
        controller.shouldStartAnimation(index: 2, animationId: 'c'),
        isFalse,
      );
    });

    test('default history is bounded to avoid unbounded growth', () {
      final controller = FlexboxItemAnimationController.auto();
      for (int i = 0; i < 5000; i++) {
        controller.markAnimationStarted(index: i, animationId: i);
      }
      expect(controller.trackedAnimationIdCount, 3000);
    });

    test('history can be unbounded when maxTrackedAnimationIds is null', () {
      final controller =
          FlexboxItemAnimationController.auto(maxTrackedAnimationIds: null);
      for (int i = 0; i < 5000; i++) {
        controller.markAnimationStarted(index: i, animationId: i);
      }
      expect(controller.trackedAnimationIdCount, 5000);
    });

    test('named constructors create expected modes', () {
      final autoController = FlexboxItemAnimationController.auto();
      final manualController = FlexboxItemAnimationController.manual();

      expect(autoController.autoAnimateUnseenItems, isTrue);
      expect(manualController.autoAnimateUnseenItems, isFalse);
    });
  });

  group('FlexboxItemTransitionValues', () {
    test('supports interval and tween helpers', () {
      const values = FlexboxItemTransitionValues(
        index: 0,
        config: FlexboxItemAnimationConfig(),
        animation: AlwaysStoppedAnimation<double>(0.5),
        linearAnimation: AlwaysStoppedAnimation<double>(0.25),
      );

      expect(values.interval(0, 1), closeTo(0.5, 0.0001));
      expect(values.interval(0.4, 0.8), closeTo(0.25, 0.0001));
      expect(
        values.interval(0.4, 0.8, useLinearProgress: true),
        closeTo(0.0, 0.0001),
      );
      expect(values.tweenDouble(10, 20), closeTo(15, 0.0001));
      expect(
        values.tweenDouble(10, 20, useLinearProgress: true),
        closeTo(12.5, 0.0001),
      );
    });
  });

  group('FlexboxItemTransition', () {
    testWidgets('supports custom transition builder', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlexboxItemTransition(
            controller: FlexboxItemAnimationController.auto(),
            index: 0,
            transitionBuilder: (context, child, values) {
              return KeyedSubtree(
                key: ValueKey<String>('custom-${values.index}'),
                child: child,
              );
            },
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(find.byKey(const ValueKey<String>('custom-0')), findsOneWidget);
    });

    testWidgets('restarts from progress zero when animation is re-enabled', (
      tester,
    ) async {
      final controller = FlexboxItemAnimationController.manual();

      late StateSetter setHostState;
      const config = FlexboxItemAnimationConfig(
        beginOpacity: 0.25,
        staggerDelay: Duration.zero,
        duration: Duration(milliseconds: 200),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return FlexboxItemTransition(
                controller: controller,
                index: 0,
                config: config,
                child: const SizedBox(width: 10, height: 10),
              );
            },
          ),
        ),
      );

      expect(find.byType(Opacity), findsNothing);

      controller.enqueueRange(startIndex: 0, endIndexInclusive: 0);
      setHostState(() {});
      await tester.pump();

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, closeTo(0.25, 0.0001));
    });

    testWidgets('does not consume animation id before delayed start', (
      tester,
    ) async {
      final controller = FlexboxItemAnimationController.manual();
      controller.enqueueRange(startIndex: 2, endIndexInclusive: 3);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FlexboxItemTransition(
            controller: controller,
            index: 3,
            config: const FlexboxItemAnimationConfig(
              staggerDelay: Duration(milliseconds: 60),
              duration: Duration(milliseconds: 100),
            ),
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      expect(controller.shouldStartAnimation(index: 3, animationId: 3), isTrue);
      await tester.pump(const Duration(milliseconds: 40));
      expect(controller.shouldStartAnimation(index: 3, animationId: 3), isTrue);
      await tester.pump(const Duration(milliseconds: 30));
      expect(
          controller.shouldStartAnimation(index: 3, animationId: 3), isFalse);
    });

    testWidgets(
      'restarts when animation id changes on reused widget state',
      (tester) async {
        final controller = FlexboxItemAnimationController.auto();

        late StateSetter setHostState;
        Object animationId = 'a';
        const config = FlexboxItemAnimationConfig(
          beginOpacity: 0.2,
          staggerDelay: Duration.zero,
          duration: Duration(milliseconds: 120),
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return FlexboxItemTransition(
                  controller: controller,
                  index: 0,
                  animationId: animationId,
                  config: config,
                  child: const SizedBox(width: 10, height: 10),
                );
              },
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));

        animationId = 'b';
        setHostState(() {});
        await tester.pump();

        final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacityWidget.opacity, closeTo(0.2, 0.0001));
      },
    );

    testWidgets(
      'ignores stale delayed callback when widget identity changes',
      (tester) async {
        final controller = FlexboxItemAnimationController.manual();
        controller.enqueueRange(startIndex: 0, endIndexInclusive: 1);

        late StateSetter setHostState;
        int currentIndex = 1;
        Object currentAnimationId = 'old';

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return FlexboxItemTransition(
                  controller: controller,
                  index: currentIndex,
                  animationId: currentAnimationId,
                  config: const FlexboxItemAnimationConfig(
                    staggerDelay: Duration(milliseconds: 60),
                    duration: Duration(milliseconds: 100),
                  ),
                  child: const SizedBox(width: 10, height: 10),
                );
              },
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 20));

        currentIndex = 99;
        currentAnimationId = 'new';
        setHostState(() {});
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 80));

        expect(controller.trackedAnimationIdCount, 0);
        expect(
          controller.shouldStartAnimation(index: 1, animationId: 'old'),
          isTrue,
        );
      },
    );
  });

  group('FlexboxItemAnimator', () {
    testWidgets('wrap delegates to configured controller and builders', (
      tester,
    ) async {
      final animator = FlexboxItemAnimator.manual(
        animationIdBuilder: (index) => 'id-$index',
      );
      animator.enqueueRange(startIndex: 0, endIndexInclusive: 0);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 1, height: 1),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final wrapped = animator.wrap((context, index) => const SizedBox());
      final wrappedWidget = wrapped(context, 0);
      expect(wrappedWidget, isA<FlexboxItemTransition>());
      expect(
        animator.controller.shouldStartAnimation(index: 0, animationId: 'id-0'),
        isTrue,
      );
    });
  });
}
