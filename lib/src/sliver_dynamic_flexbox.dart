import 'dart:async';

import 'package:extended_list_library/extended_list_library.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

export 'package:extended_list_library/extended_list_library.dart'
    show
        LastChildLayoutType,
        LastChildLayoutTypeBuilder,
        CollectGarbage,
        ViewportBuilder;

/// Callback to get the aspect ratio for a child at the given index.
typedef AspectRatioGetter = double Function(int index);

/// Delegate that controls the dynamic flexbox layout.
class SliverDynamicFlexboxDelegate extends ExtendedListDelegate {
  const SliverDynamicFlexboxDelegate({
    this.targetRowHeight = 200.0,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.minRowFillFactor = 0.8,
    this.defaultAspectRatio = 1.0,
    this.debounceDuration = const Duration(milliseconds: 150),
    this.aspectRatioChangeThreshold = 0.01,
    this.crossAxisExtentChangeThreshold = 1.0,
    super.lastChildLayoutTypeBuilder,
    super.collectGarbage,
    super.viewportBuilder,
    super.closeToTrailing,
    this.aspectRatioGetter,
  })  : assert(targetRowHeight > 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(minRowFillFactor > 0 && minRowFillFactor <= 1),
        assert(defaultAspectRatio > 0),
        assert(aspectRatioChangeThreshold >= 0),
        assert(crossAxisExtentChangeThreshold >= 0);

  final double targetRowHeight;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double minRowFillFactor;

  /// The default aspect ratio to use before a child's actual size is known.
  final double defaultAspectRatio;

  /// Duration to wait before applying batched size updates.
  /// When children's sizes change rapidly (e.g., images loading),
  /// updates are collected and applied together after this duration.
  final Duration debounceDuration;

  /// Threshold for aspect ratio change detection.
  ///
  /// Only when the difference between the current measured aspect ratio
  /// and the cached ratio exceeds this value will a layout update be scheduled.
  ///
  /// - Lower values: more sensitive, detects smaller changes but may cause
  ///   more frequent updates
  /// - Higher values: less sensitive, ignores minor variations but may miss
  ///   significant changes
  ///
  /// Default is 0.01 (1% change).
  final double aspectRatioChangeThreshold;

  /// Threshold for crossAxisExtent change to trigger cache clear.
  ///
  /// When the viewport width changes by more than this value, the aspect
  /// ratio cache is cleared to recalculate the layout.
  ///
  /// - Lower values: more responsive to width changes but may cause
  ///   unnecessary recalculations
  /// - Higher values: more stable but may not respond to small width changes
  ///
  /// Default is 1.0 pixel.
  final double crossAxisExtentChangeThreshold;

  /// Optional callback to provide aspect ratios for children.
  /// If provided, this takes precedence over measuring children.
  final AspectRatioGetter? aspectRatioGetter;

  LastChildLayoutType getLastChildLayoutType(int index) {
    if (lastChildLayoutTypeBuilder == null) {
      return LastChildLayoutType.none;
    }
    return lastChildLayoutTypeBuilder!(index);
  }

  bool shouldRelayout(SliverDynamicFlexboxDelegate oldDelegate) {
    return oldDelegate.targetRowHeight != targetRowHeight ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.minRowFillFactor != minRowFillFactor ||
        oldDelegate.defaultAspectRatio != defaultAspectRatio ||
        oldDelegate.debounceDuration != debounceDuration ||
        oldDelegate.aspectRatioChangeThreshold != aspectRatioChangeThreshold ||
        oldDelegate.crossAxisExtentChangeThreshold !=
            crossAxisExtentChangeThreshold ||
        oldDelegate.closeToTrailing != closeToTrailing;
  }
}

/// A sliver that places children in a dynamic flexbox layout.
///
/// Children are measured using their intrinsic dimensions and arranged
/// in rows to fill the available width.
///
/// ## Simple Usage - Just Works!
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverDynamicFlexbox(
///       flexboxDelegate: SliverDynamicFlexboxDelegate(
///         targetRowHeight: 200,
///         mainAxisSpacing: 4,
///         crossAxisSpacing: 4,
///       ),
///       childDelegate: SliverChildBuilderDelegate(
///         (context, index) => Image.network(
///           urls[index],
///           fit: BoxFit.cover,
///         ),
///         childCount: urls.length,
///       ),
///     ),
///   ],
/// )
/// ```
///
/// ## How It Works
///
/// 1. Each child's aspect ratio is measured from its intrinsic size
/// 2. Aspect ratios are cached for stable layout during scrolling
/// 3. When a child's intrinsic size changes (e.g., image loads),
///    the layout automatically detects and batches updates
/// 4. After debounce period, layout updates smoothly
class SliverDynamicFlexbox extends SliverMultiBoxAdaptorWidget {
  const SliverDynamicFlexbox({
    super.key,
    required SliverChildDelegate childDelegate,
    this.flexboxDelegate = const SliverDynamicFlexboxDelegate(),
  }) : super(delegate: childDelegate);

  final SliverDynamicFlexboxDelegate flexboxDelegate;

  @override
  RenderSliverDynamicFlexbox createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverDynamicFlexbox(
      childManager: element,
      flexboxDelegate: flexboxDelegate,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverDynamicFlexbox renderObject,
  ) {
    renderObject.flexboxDelegate = flexboxDelegate;
  }
}

/// Parent data for [RenderSliverDynamicFlexbox].
class SliverDynamicFlexboxParentData extends SliverMultiBoxAdaptorParentData {
  double crossAxisOffset = 0.0;
  double? lastMeasuredRatio;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

/// Render object for [SliverDynamicFlexbox].
class RenderSliverDynamicFlexbox extends RenderSliverMultiBoxAdaptor
    with ExtendedRenderObjectMixin {
  RenderSliverDynamicFlexbox({
    required super.childManager,
    required SliverDynamicFlexboxDelegate flexboxDelegate,
  }) : _flexboxDelegate = flexboxDelegate;

  SliverDynamicFlexboxDelegate _flexboxDelegate;
  SliverDynamicFlexboxDelegate get flexboxDelegate => _flexboxDelegate;
  set flexboxDelegate(SliverDynamicFlexboxDelegate value) {
    if (_flexboxDelegate == value) return;
    if (_flexboxDelegate.shouldRelayout(value)) {
      _aspectRatioCache.clear();
      markNeedsLayout();
    }
    _flexboxDelegate = value;
  }

  @override
  ExtendedListDelegate get extendedListDelegate => _flexboxDelegate;

  /// Cache for aspect ratios - stable until change detected.
  final Map<int, double> _aspectRatioCache = {};

  /// Indices needing update after debounce.
  final Set<int> _pendingUpdates = {};

  Timer? _debounceTimer;
  double? _lastCrossAxisExtent;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverDynamicFlexboxParentData) {
      child.parentData = SliverDynamicFlexboxParentData();
    }
  }

  @override
  double childCrossAxisPosition(RenderBox child) {
    final data = child.parentData as SliverDynamicFlexboxParentData;
    return data.crossAxisOffset;
  }

  /// Get aspect ratio, detecting changes automatically.
  double _getAspectRatio(int index, RenderBox child) {
    final parentData = child.parentData as SliverDynamicFlexboxParentData;

    // Use external getter if provided
    if (_flexboxDelegate.aspectRatioGetter != null) {
      final ratio = _flexboxDelegate.aspectRatioGetter!(index);
      _aspectRatioCache[index] = ratio;
      return ratio;
    }

    // Measure current intrinsic size
    final w = child.getMaxIntrinsicWidth(double.infinity);
    final h = child.getMaxIntrinsicHeight(double.infinity);

    double currentRatio;
    if (w > 0 && h > 0) {
      currentRatio = w / h;
    } else {
      currentRatio = _flexboxDelegate.defaultAspectRatio;
    }

    // Check if changed from last measurement using configurable threshold
    final lastRatio = parentData.lastMeasuredRatio;
    if (lastRatio != null &&
        (lastRatio - currentRatio).abs() >
            _flexboxDelegate.aspectRatioChangeThreshold) {
      _scheduleUpdate(index);
    }
    parentData.lastMeasuredRatio = currentRatio;

    // Return cached value if available (stable layout)
    if (_aspectRatioCache.containsKey(index)) {
      return _aspectRatioCache[index]!;
    }

    // Cache and return
    _aspectRatioCache[index] = currentRatio;
    return currentRatio;
  }

  void _scheduleUpdate(int index) {
    _pendingUpdates.add(index);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_flexboxDelegate.debounceDuration, _applyUpdates);
  }

  void _applyUpdates() {
    if (_pendingUpdates.isEmpty) return;

    for (final index in _pendingUpdates) {
      _aspectRatioCache.remove(index);
    }
    _pendingUpdates.clear();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) markNeedsLayout();
    });
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final crossAxisExtent = constraints.crossAxisExtent;

    // Clear cache when crossAxisExtent changes significantly
    if (_lastCrossAxisExtent != null &&
        (_lastCrossAxisExtent! - crossAxisExtent).abs() >
            _flexboxDelegate.crossAxisExtentChangeThreshold) {
      _aspectRatioCache.clear();
    }
    _lastCrossAxisExtent = crossAxisExtent;

    handleCloseToTrailingBegin(_flexboxDelegate.closeToTrailing);

    final scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    final remainingExtent = constraints.remainingCacheExtent;
    final targetEndScrollOffset = scrollOffset + remainingExtent;

    final measureConstraints = BoxConstraints(
      maxWidth: crossAxisExtent,
      maxHeight: double.infinity,
    );

    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    if (firstChild == null) {
      if (!addInitialChild()) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    final firstLayoutOffset = _getLayoutOffset(firstChild!);
    if (firstLayoutOffset == null) {
      int count = 0;
      RenderBox? child = firstChild;
      while (child != null && _getLayoutOffset(child) == null) {
        child = childAfter(child);
        count++;
      }
      collectGarbage(count, 0);
      if (firstChild == null) {
        if (!addInitialChild()) {
          geometry = SliverGeometry.zero;
          childManager.didFinishLayout();
          return;
        }
      }
    }

    while (indexOf(firstChild!) > 0) {
      final newChild = insertAndLayoutLeadingChild(
        measureConstraints,
        parentUsesSize: true,
      );
      if (newChild == null) break;
    }

    while (true) {
      final lastIndex = indexOf(lastChild!);
      final rows = _buildRowsUpTo(lastIndex, crossAxisExtent);

      if (rows.isEmpty) break;

      final currentEndOffset = rows.last.trailingOffset;
      if (currentEndOffset >= targetEndScrollOffset) break;

      final newChild = insertAndLayoutChild(
        measureConstraints,
        after: lastChild,
        parentUsesSize: true,
      );
      if (newChild == null) {
        reachedEnd = true;
        break;
      }
    }

    final lastIndex = indexOf(lastChild!);
    final allRows = _buildRowsUpTo(lastIndex, crossAxisExtent);

    final layoutMap = <int, _ChildLayout>{};
    final rowMap = <int, _RowLayout>{};
    for (final row in allRows) {
      for (final layout in row.childLayouts) {
        layoutMap[layout.index] = layout;
        rowMap[layout.index] = row;
      }
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as SliverDynamicFlexboxParentData;
      final index = parentData.index!;

      final layout = layoutMap[index];
      final row = rowMap[index];

      if (layout != null && row != null) {
        parentData.layoutOffset = row.scrollOffset;
        parentData.crossAxisOffset = layout.crossAxisOffset;

        child.layout(
          BoxConstraints.tight(Size(layout.width, layout.height)),
          parentUsesSize: true,
        );
      }

      child = childAfter(child);
    }

    child = firstChild;
    while (child != null) {
      final offset = _getLayoutOffset(child);
      final trailing = offset != null ? offset + paintExtentOf(child) : 0.0;
      if (trailing < scrollOffset) {
        leadingGarbage++;
      } else {
        break;
      }
      child = childAfter(child);
    }

    child = lastChild;
    while (child != null) {
      final offset = _getLayoutOffset(child);
      if (offset != null && offset > targetEndScrollOffset) {
        trailingGarbage++;
      } else {
        break;
      }
      child = childBefore(child);
    }

    collectGarbage(leadingGarbage, trailingGarbage);
    callCollectGarbage(
      collectGarbage: _flexboxDelegate.collectGarbage,
      leadingGarbage: leadingGarbage,
      trailingGarbage: trailingGarbage,
    );

    if (firstChild == null) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final endScrollOffset = allRows.isEmpty ? 0.0 : allRows.last.trailingOffset;

    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild!),
        lastIndex: indexOf(lastChild!),
        leadingScrollOffset: _getLayoutOffset(firstChild!) ?? 0.0,
        trailingScrollOffset: endScrollOffset,
      );
    }

    var finalEndScrollOffset = handleCloseToTrailingEnd(
      closeToTrailing,
      endScrollOffset,
    );
    if (finalEndScrollOffset != endScrollOffset) {
      estimatedMaxScrollOffset = finalEndScrollOffset;
    }

    var paintExtent = calculatePaintOffset(
      constraints,
      from: _getLayoutOffset(firstChild!) ?? 0.0,
      to: finalEndScrollOffset,
    );

    if (closeToTrailing) {
      paintExtent += closeToTrailingDistance;
    }

    final cacheExtent = calculateCacheOffset(
      constraints,
      from: _getLayoutOffset(firstChild!) ?? 0.0,
      to: finalEndScrollOffset,
    );

    callViewportBuilder(viewportBuilder: _flexboxDelegate.viewportBuilder);

    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      hasVisualOverflow: finalEndScrollOffset >
              constraints.scrollOffset + constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );

    if (reachedEnd) {
      childManager.setDidUnderflow(true);
    }

    childManager.didFinishLayout();
  }

  double? _getLayoutOffset(RenderBox child) {
    final data = child.parentData as SliverDynamicFlexboxParentData;
    return data.layoutOffset;
  }

  List<_RowLayout> _buildRowsUpTo(int maxIndex, double crossAxisExtent) {
    final rows = <_RowLayout>[];
    final targetHeight = _flexboxDelegate.targetRowHeight;
    final crossAxisSpacing = _flexboxDelegate.crossAxisSpacing;
    final mainAxisSpacing = _flexboxDelegate.mainAxisSpacing;
    final minFillFactor = _flexboxDelegate.minRowFillFactor;

    final children = <_ChildData>[];
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as SliverDynamicFlexboxParentData;
      final index = parentData.index!;
      if (index > maxIndex) break;

      final aspectRatio = _getAspectRatio(index, child);
      children.add(_ChildData(index: index, aspectRatio: aspectRatio));
      child = childAfter(child);
    }

    if (children.isEmpty) return rows;

    var currentRowChildren = <_ChildData>[];
    double currentScrollOffset = 0.0;

    double getTotalBaseWidth(List<_ChildData> items) {
      return items.fold<double>(
        0.0,
        (sum, c) => sum + targetHeight * c.aspectRatio,
      );
    }

    double getTotalSpacing(List<_ChildData> items) {
      return items.isEmpty ? 0.0 : crossAxisSpacing * (items.length - 1);
    }

    bool canFit(List<_ChildData> items, _ChildData newItem) {
      if (items.isEmpty) return true;
      final currentWidth = getTotalBaseWidth(items) + getTotalSpacing(items);
      final newWidth = targetHeight * newItem.aspectRatio;
      return currentWidth + crossAxisSpacing + newWidth <= crossAxisExtent;
    }

    _RowLayout buildRow(
      List<_ChildData> items,
      double scrollOffset,
      bool isLast,
    ) {
      final totalSpacing = getTotalSpacing(items);
      final availableWidth = crossAxisExtent - totalSpacing;
      final totalBaseWidth = getTotalBaseWidth(items);
      final fillFactor = totalBaseWidth / availableWidth;

      double scaleFactor;
      double height;

      if (isLast && fillFactor < minFillFactor) {
        scaleFactor = 1.0;
        height = targetHeight;
      } else {
        scaleFactor = availableWidth / totalBaseWidth;
        height = targetHeight * scaleFactor;
      }

      final childLayouts = <_ChildLayout>[];
      double offset = 0.0;

      for (final item in items) {
        final baseWidth = targetHeight * item.aspectRatio;
        final width = baseWidth * scaleFactor;
        childLayouts.add(
          _ChildLayout(
            index: item.index,
            crossAxisOffset: offset,
            width: width,
            height: height,
          ),
        );
        offset += width + crossAxisSpacing;
      }

      return _RowLayout(
        scrollOffset: scrollOffset,
        height: height,
        childLayouts: childLayouts,
      );
    }

    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final isLast = i == children.length - 1;

      if (!canFit(currentRowChildren, child)) {
        if (currentRowChildren.isNotEmpty) {
          rows.add(buildRow(currentRowChildren, currentScrollOffset, false));
          currentScrollOffset = rows.last.trailingOffset + mainAxisSpacing;
        }
        currentRowChildren = [];
      }

      currentRowChildren.add(child);

      if (isLast && currentRowChildren.isNotEmpty) {
        rows.add(buildRow(currentRowChildren, currentScrollOffset, true));
      }
    }

    return rows;
  }
}

class _ChildData {
  _ChildData({required this.index, required this.aspectRatio});
  final int index;
  final double aspectRatio;
}

class _RowLayout {
  _RowLayout({
    required this.scrollOffset,
    required this.height,
    required this.childLayouts,
  });

  final double scrollOffset;
  final double height;
  final List<_ChildLayout> childLayouts;

  double get trailingOffset => scrollOffset + height;
}

class _ChildLayout {
  _ChildLayout({
    required this.index,
    required this.crossAxisOffset,
    required this.width,
    required this.height,
  });

  final int index;
  final double crossAxisOffset;
  final double width;
  final double height;
}

/// A widget that wraps children for use in [SliverDynamicFlexbox].
///
/// This widget handles the complexity of unbounded constraints during
/// intrinsic size measurement. Use this when your child uses [Stack] with
/// [StackFit.expand] or other widgets that don't handle unbounded constraints.
///
/// ## Usage
///
/// ```dart
/// SliverDynamicFlexbox(
///   flexboxDelegate: SliverDynamicFlexboxDelegate(...),
///   childDelegate: SliverChildBuilderDelegate(
///     (context, index) => DynamicFlexItem(
///       child: Stack(
///         fit: StackFit.expand,
///         children: [
///           Image.network(urls[index], fit: BoxFit.cover),
///           Positioned(...),
///         ],
///       ),
///     ),
///   ),
/// )
/// ```
///
/// If your child is just an [Image], you don't need this wrapper - just use
/// the image directly.
class DynamicFlexItem extends SingleChildRenderObjectWidget {
  const DynamicFlexItem({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDynamicFlexItem();
  }
}

class _RenderDynamicFlexItem extends RenderProxyBox {
  @override
  double computeMinIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    return child!.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    return child!.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    return child!.getMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    return child!.getMaxIntrinsicHeight(width);
  }

  @override
  void performLayout() {
    if (child != null) {
      // For unbounded constraints, we need to use bounded constraints
      // to avoid issues with Stack/StackFit.expand
      BoxConstraints childConstraints;
      if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
        // Use intrinsic size to determine the bounds
        final targetWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : child!.getMaxIntrinsicWidth(double.infinity);
        final targetHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : child!.getMaxIntrinsicHeight(double.infinity);

        // Use tight constraints with the measured intrinsic size
        final width =
            targetWidth > 0 ? targetWidth : constraints.constrainWidth(200);
        final height =
            targetHeight > 0 ? targetHeight : constraints.constrainHeight(200);

        childConstraints = BoxConstraints.tight(Size(width, height));
      } else {
        childConstraints = constraints;
      }

      child!.layout(childConstraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.smallest;
    }
  }
}
