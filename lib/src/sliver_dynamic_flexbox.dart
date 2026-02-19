import 'dart:async';
import 'dart:math' as math;

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
    this.maxAspectRatioChecksPerLayout = 8,
    this.aspectRatioCheckInterval = 12,
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
        assert(crossAxisExtentChangeThreshold >= 0),
        assert(maxAspectRatioChecksPerLayout > 0),
        assert(aspectRatioCheckInterval > 0);

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

  /// Maximum number of cached items to re-check via intrinsic measurement
  /// during a single layout pass.
  final int maxAspectRatioChecksPerLayout;

  /// Minimum number of layout passes between re-checks for the same item.
  final int aspectRatioCheckInterval;

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
    if (aspectRatioGetter != null || oldDelegate.aspectRatioGetter != null) {
      // Getter output may change without callback identity changes.
      return true;
    }
    return oldDelegate.targetRowHeight != targetRowHeight ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.minRowFillFactor != minRowFillFactor ||
        oldDelegate.defaultAspectRatio != defaultAspectRatio ||
        oldDelegate.debounceDuration != debounceDuration ||
        oldDelegate.aspectRatioChangeThreshold != aspectRatioChangeThreshold ||
        oldDelegate.crossAxisExtentChangeThreshold !=
            crossAxisExtentChangeThreshold ||
        oldDelegate.maxAspectRatioChecksPerLayout !=
            maxAspectRatioChecksPerLayout ||
        oldDelegate.aspectRatioCheckInterval != aspectRatioCheckInterval ||
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
    if (identical(_flexboxDelegate, value)) return;
    final oldDelegate = _flexboxDelegate;
    final needsRelayout = value.shouldRelayout(oldDelegate);
    _flexboxDelegate = value;
    if (needsRelayout) {
      final preserveAspectCache = oldDelegate.aspectRatioGetter != null &&
          value.aspectRatioGetter != null;
      if (preserveAspectCache) {
        _pendingUpdates.clear();
        _debounceTimer?.cancel();
        _debounceTimer = null;
        _lastAspectCheckLayoutPass.clear();
        _aspectProbeCursor = firstChild;
        _invalidateRowCache();
      } else {
        _clearAspectRatioCache(clearPendingUpdates: true);
      }
      markNeedsLayout();
    }
  }

  @override
  ExtendedListDelegate get extendedListDelegate => _flexboxDelegate;

  /// Cache for aspect ratios - stable until change detected.
  final Map<int, double> _aspectRatioCache = {};

  /// Indices needing update after debounce.
  final Set<int> _pendingUpdates = {};

  /// Last layout pass that performed an intrinsic check for a child index.
  final Map<int, int> _lastAspectCheckLayoutPass = {};

  Timer? _debounceTimer;
  double? _lastCrossAxisExtent;
  int _layoutPass = 0;
  int _remainingAspectChecks = 0;
  int _aspectRatioRevision = 0;
  int _maxSequentialCachedIndex = -1;
  RenderBox? _aspectProbeCursor;

  List<_RowLayout>? _rowCache;
  int? _rowCacheMaxIndex;
  double? _rowCacheCrossAxisExtent;
  int _rowCacheAspectRevision = -1;
  int _rowCacheLayoutPass = -1;
  bool _rowCacheBuiltByIndex = false;
  int? _rowCacheFirstAttachedIndex;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _clearAspectRatioCache({required bool clearPendingUpdates}) {
    _aspectRatioCache.clear();
    _lastAspectCheckLayoutPass.clear();
    _maxSequentialCachedIndex = -1;
    _aspectProbeCursor = null;
    if (clearPendingUpdates) {
      _pendingUpdates.clear();
      _debounceTimer?.cancel();
      _debounceTimer = null;
    }
    _aspectRatioRevision++;
    _invalidateRowCache();
  }

  void _invalidateRowCache() {
    _rowCache = null;
    _rowCacheMaxIndex = null;
    _rowCacheCrossAxisExtent = null;
    _rowCacheAspectRevision = -1;
    _rowCacheLayoutPass = -1;
    _rowCacheBuiltByIndex = false;
    _rowCacheFirstAttachedIndex = null;
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
    final aspectRatioGetter = _flexboxDelegate.aspectRatioGetter;
    if (aspectRatioGetter != null) {
      final ratio = _sanitizeAspectRatio(aspectRatioGetter(index));
      final cached = _aspectRatioCache[index];
      if (cached == null ||
          (cached - ratio).abs() >
              _flexboxDelegate.aspectRatioChangeThreshold) {
        _setCachedAspectRatio(index, ratio);
        _aspectRatioRevision++;
        _invalidateRowCache();
      }
      return ratio;
    }

    final cached = _aspectRatioCache[index];
    if (cached != null) {
      _probeCachedAspectRatio(
        index: index,
        child: child,
        cachedRatio: cached,
      );
      return _sanitizeAspectRatio(cached);
    }

    final currentRatio = _measureAspectRatio(child);
    parentData.lastMeasuredRatio = currentRatio;
    _setCachedAspectRatio(index, currentRatio);
    _aspectRatioRevision++;
    _invalidateRowCache();
    return currentRatio;
  }

  bool _isDefaultLikeAspectRatio(double ratio) {
    return (ratio - _flexboxDelegate.defaultAspectRatio).abs() <=
        _flexboxDelegate.aspectRatioChangeThreshold;
  }

  void _setCachedAspectRatio(int index, double ratio) {
    _aspectRatioCache[index] = ratio;
    if (index == _maxSequentialCachedIndex + 1) {
      while (_aspectRatioCache.containsKey(_maxSequentialCachedIndex + 1)) {
        _maxSequentialCachedIndex++;
      }
    }
  }

  bool _removeCachedAspectRatio(int index) {
    final removed = _aspectRatioCache.remove(index) != null;
    if (!removed) return false;
    if (index <= _maxSequentialCachedIndex) {
      _maxSequentialCachedIndex = index - 1;
      while (_aspectRatioCache.containsKey(_maxSequentialCachedIndex + 1)) {
        _maxSequentialCachedIndex++;
      }
    }
    return true;
  }

  bool _canBuildRowsFromIndex(int maxIndex) {
    if (maxIndex < 0) return true;
    if (_flexboxDelegate.aspectRatioGetter != null) return true;
    return _maxSequentialCachedIndex >= maxIndex;
  }

  double _getAspectRatioForIndex(int index) {
    final getter = _flexboxDelegate.aspectRatioGetter;
    if (getter != null) {
      final ratio = _sanitizeAspectRatio(getter(index));
      final cached = _aspectRatioCache[index];
      if (cached == null ||
          (cached - ratio).abs() >
              _flexboxDelegate.aspectRatioChangeThreshold) {
        _setCachedAspectRatio(index, ratio);
        _aspectRatioRevision++;
        _invalidateRowCache();
      }
      return ratio;
    }
    final cached = _aspectRatioCache[index];
    if (cached == null) return _flexboxDelegate.defaultAspectRatio;
    return _sanitizeAspectRatio(cached);
  }

  bool _shouldProbeAspectRatio(
    int index, {
    required bool prioritize,
  }) {
    if (_remainingAspectChecks <= 0) return false;
    final lastCheckedPass = _lastAspectCheckLayoutPass[index];
    if (lastCheckedPass == _layoutPass) {
      return false;
    }

    if (!prioritize) {
      if (lastCheckedPass != null &&
          (_layoutPass - lastCheckedPass) <
              _flexboxDelegate.aspectRatioCheckInterval) {
        return false;
      }
    }

    _remainingAspectChecks--;
    _lastAspectCheckLayoutPass[index] = _layoutPass;
    return true;
  }

  void _probeCachedAspectRatio({
    required int index,
    required RenderBox child,
    required double cachedRatio,
  }) {
    final shouldProbe = _shouldProbeAspectRatio(
      index,
      prioritize: _isDefaultLikeAspectRatio(cachedRatio),
    );
    if (!shouldProbe) return;

    final currentRatio = _measureAspectRatio(child);
    if ((_sanitizeAspectRatio(cachedRatio) - currentRatio).abs() >
        _flexboxDelegate.aspectRatioChangeThreshold) {
      _scheduleUpdate(index);
    }
    final parentData = child.parentData as SliverDynamicFlexboxParentData;
    parentData.lastMeasuredRatio = currentRatio;
  }

  double _measureAspectRatio(RenderBox child) {
    final width = child.getMaxIntrinsicWidth(double.infinity);
    final height = child.getMaxIntrinsicHeight(double.infinity);
    if (width.isFinite && height.isFinite && width > 0 && height > 0) {
      return _sanitizeAspectRatio(width / height);
    }
    return _flexboxDelegate.defaultAspectRatio;
  }

  double _sanitizeAspectRatio(double ratio) {
    if (ratio.isFinite && ratio > 0) {
      return ratio;
    }
    return _flexboxDelegate.defaultAspectRatio;
  }

  void _probeAspectRatioChanges() {
    if (_flexboxDelegate.aspectRatioGetter != null) return;
    if (_remainingAspectChecks <= 0) return;
    if (firstChild == null) return;

    RenderBox? startChild = _aspectProbeCursor;
    if (startChild == null || startChild.parent != this) {
      startChild = firstChild;
    }
    RenderBox? child = startChild;

    bool wrapped = false;
    int scanned = 0;
    final int maxScan = _remainingAspectChecks * 16;
    while (child != null && _remainingAspectChecks > 0 && scanned < maxScan) {
      scanned++;
      final parentData = child.parentData as SliverDynamicFlexboxParentData;
      final index = parentData.index;
      final cachedRatio = index != null ? _aspectRatioCache[index] : null;
      if (index != null && cachedRatio != null) {
        _probeCachedAspectRatio(
          index: index,
          child: child,
          cachedRatio: cachedRatio,
        );
      }

      final next = childAfter(child);
      if (next != null) {
        child = next;
      } else if (!wrapped) {
        wrapped = true;
        child = firstChild;
      } else {
        child = null;
      }

      if (wrapped && identical(child, startChild)) {
        break;
      }
    }

    _aspectProbeCursor = child ?? firstChild;
  }

  void _scheduleUpdate(int index) {
    _pendingUpdates.add(index);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_flexboxDelegate.debounceDuration, _applyUpdates);
  }

  void _applyUpdates() {
    if (_pendingUpdates.isEmpty) return;

    bool cacheChanged = false;
    for (final index in _pendingUpdates) {
      cacheChanged = _removeCachedAspectRatio(index) || cacheChanged;
      _lastAspectCheckLayoutPass.remove(index);
    }
    _pendingUpdates.clear();
    _debounceTimer = null;

    if (cacheChanged) {
      _aspectRatioRevision++;
      _invalidateRowCache();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) markNeedsLayout();
    });
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    _layoutPass++;
    _remainingAspectChecks = _flexboxDelegate.maxAspectRatioChecksPerLayout;

    final crossAxisExtent = constraints.crossAxisExtent;

    // Row layout depends on available cross-axis extent, so width changes
    // invalidate row cache. Keep aspect-ratio cache to avoid expensive
    // backfilling of leading children during resize.
    if (_lastCrossAxisExtent != null &&
        (_lastCrossAxisExtent! - crossAxisExtent).abs() >
            _flexboxDelegate.crossAxisExtentChangeThreshold) {
      _invalidateRowCache();
      _lastAspectCheckLayoutPass.clear();
      _aspectProbeCursor = firstChild;
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

    final firstIndex = indexOf(firstChild!);
    if (!_canBuildRowsFromIndex(firstIndex - 1)) {
      while (indexOf(firstChild!) > 0) {
        final newChild = insertAndLayoutLeadingChild(
          measureConstraints,
          parentUsesSize: true,
        );
        if (newChild == null) break;
      }
    }

    const int kInsertBatchSize = 24;
    List<_RowLayout> rowsForCurrentLast = const <_RowLayout>[];
    int rowsForCurrentLastIndex = -1;
    while (true) {
      final currentLastIndex = indexOf(lastChild!);
      final rows = _buildRowsUpTo(currentLastIndex, crossAxisExtent);
      rowsForCurrentLast = rows;
      rowsForCurrentLastIndex = currentLastIndex;

      if (rows.isEmpty) break;
      if (rows.last.trailingOffset >= targetEndScrollOffset) break;

      bool insertedAny = false;
      for (int i = 0; i < kInsertBatchSize; i++) {
        final newChild = insertAndLayoutChild(
          measureConstraints,
          after: lastChild,
          parentUsesSize: true,
        );
        if (newChild == null) {
          reachedEnd = true;
          break;
        }
        insertedAny = true;
      }

      if (!insertedAny || reachedEnd) break;
    }

    final finalLastIndex = indexOf(lastChild!);
    final allRows = rowsForCurrentLastIndex == finalLastIndex
        ? rowsForCurrentLast
        : _buildRowsUpTo(finalLastIndex, crossAxisExtent);

    // When scrolling backward, previously collected leading children may leave
    // firstChild entirely below the current viewport, which causes paintExtent
    // to drop to zero (white frame). Re-attach enough leading children so that
    // first attached row starts at or before the requested scroll offset.
    if (_canBuildRowsFromIndex(finalLastIndex) && allRows.isNotEmpty) {
      final targetFirstRowIndex =
          _findFirstRowIndexForScrollOffset(allRows, scrollOffset);
      final targetFirstIndex = allRows[targetFirstRowIndex].firstIndex;
      while (firstChild != null) {
        final currentFirstIndex = indexOf(firstChild!);
        if (currentFirstIndex <= 0 || currentFirstIndex <= targetFirstIndex) {
          break;
        }
        final insertedLeadingChild = insertAndLayoutLeadingChild(
          measureConstraints,
          parentUsesSize: true,
        );
        if (insertedLeadingChild == null) {
          break;
        }
      }
    }

    RenderBox? child = firstChild;
    int rowCursor = 0;
    int itemCursor = 0;
    while (child != null && rowCursor < allRows.length) {
      final parentData = child.parentData as SliverDynamicFlexboxParentData;
      final index = parentData.index!;

      while (
          rowCursor < allRows.length && allRows[rowCursor].lastIndex < index) {
        rowCursor++;
        itemCursor = 0;
      }
      if (rowCursor >= allRows.length) break;

      final row = allRows[rowCursor];
      final rowLayouts = row.childLayouts;
      while (itemCursor < rowLayouts.length &&
          rowLayouts[itemCursor].index < index) {
        itemCursor++;
      }

      _ChildLayoutWithRow? resolvedLayout;
      if (itemCursor < rowLayouts.length &&
          rowLayouts[itemCursor].index == index) {
        resolvedLayout = _ChildLayoutWithRow(
          row: row,
          layout: rowLayouts[itemCursor],
        );
      } else {
        resolvedLayout = _findChildLayout(allRows, index);
      }

      if (resolvedLayout != null) {
        parentData.layoutOffset = resolvedLayout.row.scrollOffset;
        parentData.crossAxisOffset = resolvedLayout.layout.crossAxisOffset;
        child.layout(
          BoxConstraints.tight(
            Size(
              resolvedLayout.layout.width,
              resolvedLayout.layout.height,
            ),
          ),
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

    int attachedChildCount = 0;
    for (RenderBox? attached = firstChild;
        attached != null;
        attached = childAfter(attached)) {
      attachedChildCount++;
    }
    // Never garbage collect every attached child in one pass. Doing so can
    // produce transient empty geometry (white flash) and scroll jump.
    if (attachedChildCount > 0 &&
        leadingGarbage + trailingGarbage >= attachedChildCount) {
      if (leadingGarbage >= trailingGarbage) {
        leadingGarbage = math.max(0, attachedChildCount - trailingGarbage - 1);
      } else {
        trailingGarbage = math.max(0, attachedChildCount - leadingGarbage - 1);
      }
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

    // Probe after child list stabilizes for this layout pass so scrolling
    // does not keep probing children that are about to be detached.
    _probeAspectRatioChanges();

    final postGarbageLastIndex = indexOf(lastChild!);
    final rowsForGeometry = postGarbageLastIndex == finalLastIndex
        ? allRows
        : _buildRowsUpTo(postGarbageLastIndex, crossAxisExtent);
    final endScrollOffset = rowsForGeometry.isNotEmpty
        ? rowsForGeometry.last.trailingOffset
        : (_getLayoutOffset(lastChild!) ?? 0.0) + paintExtentOf(lastChild!);

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
    if (maxIndex < 0 || firstChild == null) {
      return const <_RowLayout>[];
    }

    final firstAttachedIndex = indexOf(firstChild!);
    final canBuildByIndex = _canBuildRowsFromIndex(maxIndex);
    // aspectRatioGetter values can change without callback identity changes.
    // Rebuilding rows in getter mode avoids stale-cache mismatches.
    // But we still allow reuse within the same layout pass to avoid repeated
    // rebuilding during a single performLayout.
    final canReuseRowCache = _flexboxDelegate.aspectRatioGetter == null ||
        _rowCacheLayoutPass == _layoutPass;
    final hasValidCacheBase = canReuseRowCache &&
        _rowCache != null &&
        _rowCacheAspectRevision == _aspectRatioRevision &&
        _rowCacheCrossAxisExtent != null &&
        (_rowCacheCrossAxisExtent! - crossAxisExtent).abs() < 0.001;

    if (hasValidCacheBase && _rowCacheMaxIndex == maxIndex) {
      if (_rowCacheBuiltByIndex ||
          _rowCacheFirstAttachedIndex == firstAttachedIndex) {
        return _rowCache!;
      }
    }

    if (hasValidCacheBase &&
        canBuildByIndex &&
        _rowCacheBuiltByIndex &&
        _rowCacheMaxIndex != null &&
        _rowCacheMaxIndex! < maxIndex) {
      final rows = _extendRowsByIndex(
        previousRows: _rowCache!,
        maxIndex: maxIndex,
        crossAxisExtent: crossAxisExtent,
      );
      _rowCache = rows;
      _rowCacheMaxIndex = maxIndex;
      _rowCacheCrossAxisExtent = crossAxisExtent;
      _rowCacheAspectRevision = _aspectRatioRevision;
      _rowCacheLayoutPass = _layoutPass;
      _rowCacheBuiltByIndex = true;
      _rowCacheFirstAttachedIndex = null;
      return rows;
    }

    final rows = canBuildByIndex
        ? _buildRowsByIndex(maxIndex, crossAxisExtent)
        : _buildRowsByAttachedChildren(maxIndex, crossAxisExtent);

    _rowCache = rows;
    _rowCacheMaxIndex = maxIndex;
    _rowCacheCrossAxisExtent = crossAxisExtent;
    _rowCacheAspectRevision = _aspectRatioRevision;
    _rowCacheLayoutPass = _layoutPass;
    _rowCacheBuiltByIndex = canBuildByIndex;
    _rowCacheFirstAttachedIndex = canBuildByIndex ? null : firstAttachedIndex;

    return rows;
  }

  List<_RowLayout> _extendRowsByIndex({
    required List<_RowLayout> previousRows,
    required int maxIndex,
    required double crossAxisExtent,
  }) {
    if (previousRows.isEmpty) {
      return _buildRowsByIndex(maxIndex, crossAxisExtent);
    }

    final mainAxisSpacing = _flexboxDelegate.mainAxisSpacing;
    final preservedCount =
        previousRows.length > 1 ? previousRows.length - 1 : 0;
    final rows = <_RowLayout>[];
    if (preservedCount > 0) {
      rows.addAll(previousRows.getRange(0, preservedCount));
    }

    final droppedTailRow = previousRows[preservedCount];
    final startIndex = droppedTailRow.firstIndex;
    final startScrollOffset =
        rows.isEmpty ? 0.0 : rows.last.trailingOffset + mainAxisSpacing;
    rows.addAll(
      _buildRowsByIndexRange(
        startIndex: startIndex,
        maxIndex: maxIndex,
        crossAxisExtent: crossAxisExtent,
        startScrollOffset: startScrollOffset,
      ),
    );
    return rows;
  }

  List<_RowLayout> _buildRowsByAttachedChildren(
    int maxIndex,
    double crossAxisExtent,
  ) {
    final rows = <_RowLayout>[];
    final targetHeight = _flexboxDelegate.targetRowHeight;
    final crossAxisSpacing = _flexboxDelegate.crossAxisSpacing;
    final mainAxisSpacing = _flexboxDelegate.mainAxisSpacing;
    final minFillFactor = _flexboxDelegate.minRowFillFactor;

    final currentRowChildren = <_ChildData>[];
    double currentRowBaseWidth = 0.0;
    double currentScrollOffset =
        firstChild != null ? (_getLayoutOffset(firstChild!) ?? 0.0) : 0.0;

    void flushCurrentRow({required bool isLastRow}) {
      if (currentRowChildren.isEmpty) return;
      final row = _buildRowLayout(
        items: currentRowChildren,
        totalBaseWidth: currentRowBaseWidth,
        scrollOffset: currentScrollOffset,
        targetHeight: targetHeight,
        crossAxisExtent: crossAxisExtent,
        crossAxisSpacing: crossAxisSpacing,
        minFillFactor: minFillFactor,
        isLastRow: isLastRow,
      );
      rows.add(row);
      currentScrollOffset = row.trailingOffset + mainAxisSpacing;
      currentRowChildren.clear();
      currentRowBaseWidth = 0.0;
    }

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as SliverDynamicFlexboxParentData;
      final index = parentData.index!;
      if (index > maxIndex) break;

      final aspectRatio = _getAspectRatio(index, child);
      final baseWidth = targetHeight * aspectRatio;

      final projectedBaseWidth = currentRowBaseWidth + baseWidth;
      final projectedItemCount = currentRowChildren.length + 1;
      final projectedSpacing = crossAxisSpacing * (projectedItemCount - 1);
      final projectedWidth = projectedBaseWidth + projectedSpacing;

      if (currentRowChildren.isNotEmpty && projectedWidth > crossAxisExtent) {
        flushCurrentRow(isLastRow: false);
      }

      currentRowChildren.add(
        _ChildData(
          index: index,
          baseWidth: baseWidth,
        ),
      );
      currentRowBaseWidth += baseWidth;

      child = childAfter(child);
    }

    flushCurrentRow(isLastRow: true);

    return rows;
  }

  List<_RowLayout> _buildRowsByIndex(int maxIndex, double crossAxisExtent) {
    return _buildRowsByIndexRange(
      startIndex: 0,
      maxIndex: maxIndex,
      crossAxisExtent: crossAxisExtent,
      startScrollOffset: 0.0,
    );
  }

  List<_RowLayout> _buildRowsByIndexRange({
    required int startIndex,
    required int maxIndex,
    required double crossAxisExtent,
    required double startScrollOffset,
  }) {
    if (startIndex > maxIndex) {
      return const <_RowLayout>[];
    }

    final rows = <_RowLayout>[];
    final targetHeight = _flexboxDelegate.targetRowHeight;
    final crossAxisSpacing = _flexboxDelegate.crossAxisSpacing;
    final mainAxisSpacing = _flexboxDelegate.mainAxisSpacing;
    final minFillFactor = _flexboxDelegate.minRowFillFactor;

    final currentRowChildren = <_ChildData>[];
    double currentRowBaseWidth = 0.0;
    double currentScrollOffset = startScrollOffset;

    void flushCurrentRow({required bool isLastRow}) {
      if (currentRowChildren.isEmpty) return;
      final row = _buildRowLayout(
        items: currentRowChildren,
        totalBaseWidth: currentRowBaseWidth,
        scrollOffset: currentScrollOffset,
        targetHeight: targetHeight,
        crossAxisExtent: crossAxisExtent,
        crossAxisSpacing: crossAxisSpacing,
        minFillFactor: minFillFactor,
        isLastRow: isLastRow,
      );
      rows.add(row);
      currentScrollOffset = row.trailingOffset + mainAxisSpacing;
      currentRowChildren.clear();
      currentRowBaseWidth = 0.0;
    }

    for (int index = startIndex; index <= maxIndex; index++) {
      final aspectRatio = _getAspectRatioForIndex(index);
      final baseWidth = targetHeight * aspectRatio;

      final projectedBaseWidth = currentRowBaseWidth + baseWidth;
      final projectedItemCount = currentRowChildren.length + 1;
      final projectedSpacing = crossAxisSpacing * (projectedItemCount - 1);
      final projectedWidth = projectedBaseWidth + projectedSpacing;

      if (currentRowChildren.isNotEmpty && projectedWidth > crossAxisExtent) {
        flushCurrentRow(isLastRow: false);
      }

      currentRowChildren.add(
        _ChildData(
          index: index,
          baseWidth: baseWidth,
        ),
      );
      currentRowBaseWidth += baseWidth;
    }

    flushCurrentRow(isLastRow: true);

    return rows;
  }

  _RowLayout _buildRowLayout({
    required List<_ChildData> items,
    required double totalBaseWidth,
    required double scrollOffset,
    required double targetHeight,
    required double crossAxisExtent,
    required double crossAxisSpacing,
    required double minFillFactor,
    required bool isLastRow,
  }) {
    final totalSpacing = crossAxisSpacing * (items.length - 1);
    final availableWidth = crossAxisExtent - totalSpacing;
    final safeBaseWidth = totalBaseWidth > 0 ? totalBaseWidth : 1.0;
    final fillFactor =
        availableWidth > 0 ? safeBaseWidth / availableWidth : double.infinity;

    double scaleFactor = 1.0;
    if (availableWidth > 0) {
      if (isLastRow && fillFactor < minFillFactor) {
        scaleFactor = 1.0;
      } else {
        scaleFactor = availableWidth / safeBaseWidth;
      }
    }
    if (!scaleFactor.isFinite || scaleFactor <= 0) {
      scaleFactor = 1.0;
    }

    final rowHeight = targetHeight * scaleFactor;
    final childLayouts = <_ChildLayout>[];
    double crossOffset = 0.0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final width = item.baseWidth * scaleFactor;
      childLayouts.add(
        _ChildLayout(
          index: item.index,
          crossAxisOffset: crossOffset,
          width: width,
          height: rowHeight,
        ),
      );
      crossOffset += width;
      if (i < items.length - 1) {
        crossOffset += crossAxisSpacing;
      }
    }

    return _RowLayout(
      firstIndex: items.first.index,
      lastIndex: items.last.index,
      scrollOffset: scrollOffset,
      height: rowHeight,
      childLayouts: childLayouts,
    );
  }

  _ChildLayoutWithRow? _findChildLayout(List<_RowLayout> rows, int index) {
    if (rows.isEmpty) return null;

    int low = 0;
    int high = rows.length - 1;
    int rowIndex = -1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final row = rows[mid];
      if (index < row.firstIndex) {
        high = mid - 1;
      } else if (index > row.lastIndex) {
        low = mid + 1;
      } else {
        rowIndex = mid;
        break;
      }
    }
    if (rowIndex < 0) return null;

    final row = rows[rowIndex];
    final layouts = row.childLayouts;
    int itemLow = 0;
    int itemHigh = layouts.length - 1;
    while (itemLow <= itemHigh) {
      final mid = (itemLow + itemHigh) >> 1;
      final layout = layouts[mid];
      if (index < layout.index) {
        itemHigh = mid - 1;
      } else if (index > layout.index) {
        itemLow = mid + 1;
      } else {
        return _ChildLayoutWithRow(row: row, layout: layout);
      }
    }

    return null;
  }

  int _findFirstRowIndexForScrollOffset(
    List<_RowLayout> rows,
    double scrollOffset,
  ) {
    if (rows.isEmpty || scrollOffset <= 0.0) {
      return 0;
    }
    int low = 0;
    int high = rows.length - 1;
    int result = rows.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (rows[mid].trailingOffset > scrollOffset) {
        result = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return result;
  }
}

class _ChildData {
  _ChildData({
    required this.index,
    required this.baseWidth,
  });
  final int index;
  final double baseWidth;
}

class _RowLayout {
  _RowLayout({
    required this.firstIndex,
    required this.lastIndex,
    required this.scrollOffset,
    required this.height,
    required this.childLayouts,
  });

  final int firstIndex;
  final int lastIndex;
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

class _ChildLayoutWithRow {
  const _ChildLayoutWithRow({
    required this.row,
    required this.layout,
  });

  final _RowLayout row;
  final _ChildLayout layout;
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
