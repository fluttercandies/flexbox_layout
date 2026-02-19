import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Builds a stable animation id for an item index.
typedef FlexboxItemAnimationIdBuilder = Object? Function(int index);

/// Runtime values exposed to a custom item entrance transition builder.
class FlexboxItemTransitionValues {
  const FlexboxItemTransitionValues({
    required this.index,
    required this.config,
    required this.animation,
    required this.linearAnimation,
  });

  /// Item index for the current child.
  final int index;

  /// Animation config used by this transition.
  final FlexboxItemAnimationConfig config;

  /// Curved progress animation.
  final Animation<double> animation;

  /// Linear progress animation (before curve transform).
  final Animation<double> linearAnimation;

  /// Current curved progress in `[0, 1]`.
  double get value => animation.value;

  /// Current linear progress in `[0, 1]`.
  double get linearValue => linearAnimation.value;

  /// Returns a normalized sub-progress for a phase inside `[begin, end]`.
  ///
  /// Useful for multi-stage transitions. For example, fade in for
  /// `interval(0.0, 0.3)` and rotate for `interval(0.2, 1.0)`.
  double interval(
    double begin,
    double end, {
    Curve curve = Curves.linear,
    bool useLinearProgress = false,
  }) {
    assert(begin >= 0 && begin <= 1);
    assert(end >= 0 && end <= 1);
    assert(end >= begin);

    final progress = useLinearProgress ? linearValue : value;
    if (end == begin) {
      return progress >= end ? 1 : 0;
    }

    final normalized =
        ((progress - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();
    return curve.transform(normalized);
  }

  /// Interpolates a double value with the current progress.
  double tweenDouble(
    double begin,
    double end, {
    Curve curve = Curves.linear,
    bool useLinearProgress = false,
  }) {
    final progress =
        (useLinearProgress ? linearValue : value).clamp(0.0, 1.0).toDouble();
    return begin + (end - begin) * curve.transform(progress);
  }
}

/// Builds custom transition for item animation.
///
/// This enables advanced effects such as blur, rotation, shader masks,
/// and multi-stage compositions while still reusing controller/stagger logic.
typedef FlexboxItemTransitionBuilder = Widget Function(
  BuildContext context,
  Widget child,
  FlexboxItemTransitionValues values,
);

/// Configuration for item entrance animation.
class FlexboxItemAnimationConfig {
  /// Creates animation config.
  const FlexboxItemAnimationConfig({
    this.duration = const Duration(milliseconds: 320),
    this.staggerDelay = const Duration(milliseconds: 28),
    this.maxStaggeredItems = 12,
    this.curve = Curves.easeOutCubic,
    this.slideDistance = 10,
    this.beginScale = 0.985,
    this.beginOpacity = 0,
  })  : assert(maxStaggeredItems >= 0),
        assert(slideDistance >= 0),
        assert(beginScale > 0 && beginScale <= 1),
        assert(beginOpacity >= 0 && beginOpacity <= 1);

  /// Total animation duration.
  final Duration duration;

  /// Delay step per item for batch stagger animation.
  final Duration staggerDelay;

  /// Caps stagger delay so large indexes do not wait too long.
  final int maxStaggeredItems;

  /// Curve for transition interpolation.
  final Curve curve;

  /// Initial downward translation in logical pixels.
  final double slideDistance;

  /// Initial scale value.
  final double beginScale;

  /// Initial opacity value.
  final double beginOpacity;

  FlexboxItemAnimationConfig copyWith({
    Duration? duration,
    Duration? staggerDelay,
    int? maxStaggeredItems,
    Curve? curve,
    double? slideDistance,
    double? beginScale,
    double? beginOpacity,
  }) {
    return FlexboxItemAnimationConfig(
      duration: duration ?? this.duration,
      staggerDelay: staggerDelay ?? this.staggerDelay,
      maxStaggeredItems: maxStaggeredItems ?? this.maxStaggeredItems,
      curve: curve ?? this.curve,
      slideDistance: slideDistance ?? this.slideDistance,
      beginScale: beginScale ?? this.beginScale,
      beginOpacity: beginOpacity ?? this.beginOpacity,
    );
  }
}

/// Controls which items should play item entrance animation.
///
/// Modes:
/// - [autoAnimateUnseenItems] = true: every unseen item animates once.
/// - [autoAnimateUnseenItems] = false: only queued indexes animate.
///
/// This controller is passive: enqueue/reset operations do not trigger widget
/// rebuilds. Rebuild the list (for example via `setState`) after changing its
/// state so transitions can re-evaluate.
class FlexboxItemAnimationController {
  /// Auto mode constructor.
  FlexboxItemAnimationController.auto({this.maxTrackedAnimationIds = 3000})
      : autoAnimateUnseenItems = true,
        assert(maxTrackedAnimationIds == null || maxTrackedAnimationIds > 0);

  /// Manual mode constructor.
  FlexboxItemAnimationController.manual({this.maxTrackedAnimationIds = 3000})
      : autoAnimateUnseenItems = false,
        assert(maxTrackedAnimationIds == null || maxTrackedAnimationIds > 0);

  /// Whether unseen items should animate automatically.
  final bool autoAnimateUnseenItems;

  /// Max number of animation ids to retain.
  ///
  /// Use `null` for unbounded retention.
  ///
  /// For long-running infinite feeds, consider setting a finite value to
  /// bound memory.
  final int? maxTrackedAnimationIds;

  final Set<int> _pendingIndexes = <int>{};
  final Map<int, int> _pendingBatchStartByIndex = <int, int>{};

  final Set<Object> _animatedIds = <Object>{};
  final Queue<Object> _animatedIdQueue = Queue<Object>();

  int? _autoStaggerStartIndex;

  /// Queues an inclusive index range for manual-mode animation.
  void enqueueRange({
    required int startIndex,
    required int endIndexInclusive,
  }) {
    assert(startIndex >= 0);
    assert(endIndexInclusive >= 0);
    if (endIndexInclusive < startIndex) return;

    for (int i = startIndex; i <= endIndexInclusive; i++) {
      _pendingIndexes.add(i);
      _pendingBatchStartByIndex[i] = startIndex;
    }
  }

  /// Queues first [itemCount] items, equivalent to `[0..itemCount-1]`.
  void enqueueInitialItems(int itemCount) {
    assert(itemCount >= 0);
    if (itemCount <= 0) return;
    enqueueRange(startIndex: 0, endIndexInclusive: itemCount - 1);
  }

  /// Clears queued items.
  void clearQueuedItems() {
    _pendingIndexes.clear();
    _pendingBatchStartByIndex.clear();
  }

  /// Clears animated id history.
  void clearAnimationHistory() {
    _animatedIds.clear();
    _animatedIdQueue.clear();
    _autoStaggerStartIndex = null;
  }

  /// Resets controller state.
  ///
  /// Set [keepAnimationHistory] to `true` when you want to clear queued
  /// indexes but still prevent previously animated items from replaying.
  void reset({bool keepAnimationHistory = false}) {
    clearQueuedItems();
    if (!keepAnimationHistory) {
      clearAnimationHistory();
    }
  }

  /// Whether item should start animation now.
  bool shouldStartAnimation({required int index, required Object animationId}) {
    assert(index >= 0);
    if (_animatedIds.contains(animationId)) return false;
    return autoAnimateUnseenItems || _pendingIndexes.contains(index);
  }

  /// Marks animation as started for this item.
  void markAnimationStarted({required int index, required Object animationId}) {
    assert(index >= 0);
    _pendingIndexes.remove(index);
    _pendingBatchStartByIndex.remove(index);

    if (_animatedIds.add(animationId)) {
      _animatedIdQueue.addLast(animationId);
      _pruneAnimationIdsIfNeeded();
    }

    if (autoAnimateUnseenItems) {
      _autoStaggerStartIndex ??= index;
    }
  }

  /// Returns stagger step used for delay calculation.
  int staggerStepFor(int index) {
    assert(index >= 0);
    final pendingBatchStart = _pendingBatchStartByIndex[index];
    if (pendingBatchStart != null) {
      return index - pendingBatchStart;
    }

    if (!autoAnimateUnseenItems) {
      return 0;
    }

    final start = _autoStaggerStartIndex ?? index;
    return index - start;
  }

  void _pruneAnimationIdsIfNeeded() {
    final max = maxTrackedAnimationIds;
    if (max == null) return;

    while (_animatedIds.length > max && _animatedIdQueue.isNotEmpty) {
      final removed = _animatedIdQueue.removeFirst();
      _animatedIds.remove(removed);
    }
  }

  int get pendingCount => _pendingIndexes.length;
  int get trackedAnimationIdCount => _animatedIds.length;
}

/// Default transition implementation for [FlexboxItemTransition].
Widget defaultFlexboxItemTransitionBuilder(
  BuildContext context,
  Widget child,
  FlexboxItemTransitionValues values,
) {
  final config = values.config;
  final progress = values.value;
  final opacity = config.beginOpacity + (1 - config.beginOpacity) * progress;
  final scale = config.beginScale + (1 - config.beginScale) * progress;

  return Opacity(
    opacity: opacity,
    child: Transform.translate(
      offset: Offset(0, (1 - progress) * config.slideDistance),
      child: Transform.scale(scale: scale, child: child),
    ),
  );
}

/// Wraps a child with item entrance animation.
class FlexboxItemTransition extends StatefulWidget {
  const FlexboxItemTransition({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
    this.animationId,
    this.config = const FlexboxItemAnimationConfig(),
    this.transitionBuilder,
  });

  final FlexboxItemAnimationController controller;
  final int index;

  /// Stable id for one-time animation deduplication.
  ///
  /// If null, [index] is used.
  final Object? animationId;

  final FlexboxItemAnimationConfig config;
  final FlexboxItemTransitionBuilder? transitionBuilder;
  final Widget child;

  @override
  State<FlexboxItemTransition> createState() => _FlexboxItemTransitionState();
}

class _FlexboxItemTransitionState extends State<FlexboxItemTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _linearAnimation;
  late Animation<double> _animation;

  bool _scheduled = false;
  bool _shouldAnimate = false;
  int _scheduleToken = 0;

  Object get _animationId => widget.animationId ?? widget.index;

  Object _animationIdFrom(FlexboxItemTransition target) {
    return target.animationId ?? target.index;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.config.duration,
    );
    _linearAnimation = _controller;
    _animation =
        CurvedAnimation(parent: _linearAnimation, curve: widget.config.curve);
    _shouldAnimate = _computeShouldAnimate();

    if (_shouldAnimate) {
      _controller.value = 0;
      _scheduleAnimation();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FlexboxItemTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.config.duration != widget.config.duration) {
      _controller.duration = widget.config.duration;
    }
    if (oldWidget.config.curve != widget.config.curve) {
      _animation =
          CurvedAnimation(parent: _linearAnimation, curve: widget.config.curve);
    }

    final identityChanged = oldWidget.index != widget.index ||
        _animationIdFrom(oldWidget) != _animationId ||
        oldWidget.controller != widget.controller;

    if (identityChanged) {
      _cancelPendingSchedule();
    }

    final nextShouldAnimate = _computeShouldAnimate();
    if (nextShouldAnimate) {
      final animationCompleted =
          _controller.status == AnimationStatus.completed ||
              _controller.value >= 1;
      final shouldRestart =
          identityChanged || !_shouldAnimate || animationCompleted;

      _shouldAnimate = true;
      if (shouldRestart) {
        _controller.value = 0;
        _scheduleAnimation();
      }
      return;
    }

    _shouldAnimate = false;
    _cancelPendingSchedule();
    _controller.value = 1;
  }

  bool _computeShouldAnimate() {
    return widget.controller.shouldStartAnimation(
      index: widget.index,
      animationId: _animationId,
    );
  }

  void _cancelPendingSchedule() {
    _scheduleToken++;
    _scheduled = false;
  }

  void _scheduleAnimation() {
    if (_scheduled) return;
    _scheduled = true;

    final token = ++_scheduleToken;
    final scheduledIndex = widget.index;
    final scheduledAnimationId = _animationId;
    final scheduledController = widget.controller;

    final stagger = scheduledController
        .staggerStepFor(scheduledIndex)
        .clamp(0, widget.config.maxStaggeredItems);

    final delayMs = widget.config.staggerDelay.inMilliseconds * stagger;

    void startScheduledAnimation() {
      if (!mounted) return;
      if (token != _scheduleToken) return;
      if (!_shouldAnimate) return;
      if (widget.index != scheduledIndex) return;
      if (_animationId != scheduledAnimationId) return;

      _scheduled = false;
      scheduledController.markAnimationStarted(
        index: scheduledIndex,
        animationId: scheduledAnimationId,
      );
      _controller.forward(from: 0);
    }

    if (delayMs == 0) {
      startScheduledAnimation();
      return;
    }

    Future<void>.delayed(
      Duration(milliseconds: delayMs),
      startScheduledAnimation,
    );
  }

  @override
  void dispose() {
    _cancelPendingSchedule();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.value >= 1 && !_shouldAnimate) {
      return widget.child;
    }

    final transitionBuilder =
        widget.transitionBuilder ?? defaultFlexboxItemTransitionBuilder;

    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final values = FlexboxItemTransitionValues(
          index: widget.index,
          config: widget.config,
          animation: _animation,
          linearAnimation: _linearAnimation,
        );
        return transitionBuilder(context, child!, values);
      },
    );
  }
}

/// Wraps an [itemBuilder] with item entrance animation.
NullableIndexedWidgetBuilder withFlexboxItemAnimation({
  required NullableIndexedWidgetBuilder itemBuilder,
  required FlexboxItemAnimationController controller,
  FlexboxItemAnimationConfig config = const FlexboxItemAnimationConfig(),
  FlexboxItemAnimationIdBuilder? animationIdBuilder,
  FlexboxItemTransitionBuilder? transitionBuilder,
}) {
  return (context, index) {
    final child = itemBuilder(context, index);
    if (child == null) return null;

    return FlexboxItemTransition(
      index: index,
      animationId: animationIdBuilder?.call(index),
      controller: controller,
      config: config,
      transitionBuilder: transitionBuilder,
      child: child,
    );
  };
}

/// High-level helper that bundles controller + config + wrapping behavior.
///
/// This keeps call sites small and reduces boilerplate in stateful pages.
class FlexboxItemAnimator {
  FlexboxItemAnimator.auto({
    int? maxTrackedAnimationIds = 3000,
    this.config = const FlexboxItemAnimationConfig(),
    this.animationIdBuilder,
    this.transitionBuilder,
  }) : controller = FlexboxItemAnimationController.auto(
          maxTrackedAnimationIds: maxTrackedAnimationIds,
        );

  FlexboxItemAnimator.manual({
    int? maxTrackedAnimationIds = 3000,
    this.config = const FlexboxItemAnimationConfig(),
    this.animationIdBuilder,
    this.transitionBuilder,
  }) : controller = FlexboxItemAnimationController.manual(
          maxTrackedAnimationIds: maxTrackedAnimationIds,
        );

  final FlexboxItemAnimationController controller;
  final FlexboxItemAnimationConfig config;
  final FlexboxItemAnimationIdBuilder? animationIdBuilder;
  final FlexboxItemTransitionBuilder? transitionBuilder;

  NullableIndexedWidgetBuilder wrap(NullableIndexedWidgetBuilder itemBuilder) {
    return withFlexboxItemAnimation(
      itemBuilder: itemBuilder,
      controller: controller,
      config: config,
      animationIdBuilder: animationIdBuilder,
      transitionBuilder: transitionBuilder,
    );
  }

  void enqueueRange({
    required int startIndex,
    required int endIndexInclusive,
  }) {
    controller.enqueueRange(
      startIndex: startIndex,
      endIndexInclusive: endIndexInclusive,
    );
  }

  void enqueueInitialItems(int itemCount) {
    controller.enqueueInitialItems(itemCount);
  }

  void clearQueuedItems() => controller.clearQueuedItems();
  void clearAnimationHistory() => controller.clearAnimationHistory();

  void reset({bool keepAnimationHistory = false}) {
    controller.reset(keepAnimationHistory: keepAnimationHistory);
  }
}
