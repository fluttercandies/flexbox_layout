import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'sliver_flexbox_delegate.dart';

/// A sliver that places multiple children in a flexbox layout.
///
/// This widget is the sliver equivalent of [GridView] but with flexbox
/// layout capabilities. It can be used inside a [CustomScrollView] to create
/// scrollable lists with advanced flex-based layouts.
///
/// The layout of children is determined by the [flexboxDelegate], which
/// specifies how items should be arranged, sized, and aligned.
///
/// ## Example
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverFlexbox(
///       delegate: SliverChildBuilderDelegate(
///         (context, index) => Card(child: Text('Item $index')),
///         childCount: 100,
///       ),
///       flexboxDelegate: SliverFlexboxDelegateWithFixedCrossAxisCount(
///         crossAxisCount: 3,
///         mainAxisSpacing: 8,
///         crossAxisSpacing: 8,
///       ),
///     ),
///   ],
/// )
/// ```
///
/// See also:
/// * [FlexboxList], which combines this with [CustomScrollView] for convenience
/// * [SliverFlexboxDelegate], which controls the layout behavior
/// * [SliverFlexboxDelegateWithFixedCrossAxisCount], for grid-like layouts
/// * [SliverFlexboxDelegateWithMaxCrossAxisExtent], for responsive layouts
class SliverFlexbox extends SliverMultiBoxAdaptorWidget {
  /// Creates a sliver flexbox.
  ///
  /// The [delegate] parameter must not be null and controls which children
  /// are displayed. The [flexboxDelegate] parameter must not be null and
  /// controls how the children are laid out.
  const SliverFlexbox({
    super.key,
    required super.delegate,
    required this.flexboxDelegate,
  });

  /// The delegate that controls the flexbox layout.
  ///
  /// This delegate determines how children are sized, positioned, and
  /// arranged within the flexbox container.
  final SliverFlexboxDelegate flexboxDelegate;

  @override
  RenderSliverFlexbox createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverFlexbox(
      childManager: element,
      flexboxDelegate: flexboxDelegate,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverFlexbox renderObject,
  ) {
    renderObject.flexboxDelegate = flexboxDelegate;
  }
}

/// Parent data structure used by [RenderSliverFlexbox].
///
/// This extends [SliverMultiBoxAdaptorParentData] to include the
/// cross-axis offset for each child, which is needed for flexbox layout.
class SliverFlexboxParentData extends SliverMultiBoxAdaptorParentData {
  /// The offset of the child in the non-scrolling axis (cross axis).
  ///
  /// For vertical scrolling, this is the x-coordinate.
  /// For horizontal scrolling, this is the y-coordinate.
  double? crossAxisOffset;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

/// The render object for [SliverFlexbox].
///
/// This render object implements the flexbox layout algorithm within the
/// sliver protocol, allowing flexbox layouts to be used in scrollable
/// views with efficient child management.
///
/// It follows the same pattern as [RenderSliverGrid] from the Flutter
/// framework to ensure proper child garbage collection and reuse.
///
/// This render object is typically not used directly. Use [SliverFlexbox]
/// instead.
///
/// See also:
/// * [SliverFlexbox], the widget that creates this render object
/// * [SliverFlexboxDelegate], which controls the layout
class RenderSliverFlexbox extends RenderSliverMultiBoxAdaptor {
  /// Creates a render sliver flexbox.
  ///
  /// The [childManager] parameter must not be null and is used to manage
  /// the lifecycle of children. The [flexboxDelegate] parameter must not
  /// be null and controls the layout of children.
  RenderSliverFlexbox({
    required super.childManager,
    required SliverFlexboxDelegate flexboxDelegate,
  }) : _flexboxDelegate = flexboxDelegate;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverFlexboxParentData) {
      child.parentData = SliverFlexboxParentData();
    }
  }

  /// The flexbox delegate.
  ///
  /// This delegate controls how children are laid out within the sliver.
  /// When changed, the layout is marked as needing to be recomputed.
  SliverFlexboxDelegate get flexboxDelegate => _flexboxDelegate;
  SliverFlexboxDelegate _flexboxDelegate;
  SliverFlexboxLayout? _cachedLayout;
  double? _cachedCrossAxisExtent;
  int? _cachedChildCount;
  AxisDirection? _cachedAxisDirection;
  GrowthDirection? _cachedGrowthDirection;

  set flexboxDelegate(SliverFlexboxDelegate value) {
    if (identical(_flexboxDelegate, value)) {
      return;
    }
    final needsRelayout = value.runtimeType != _flexboxDelegate.runtimeType ||
        value.shouldRelayout(_flexboxDelegate);
    _flexboxDelegate = value;
    if (needsRelayout) {
      _invalidateLayoutCache();
      markNeedsLayout();
    }
  }

  void _invalidateLayoutCache() {
    _cachedLayout = null;
    _cachedCrossAxisExtent = null;
    _cachedChildCount = null;
    _cachedAxisDirection = null;
    _cachedGrowthDirection = null;
  }

  SliverFlexboxLayout _getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    if (_flexboxDelegate.shouldCacheLayout &&
        _cachedLayout != null &&
        _cachedChildCount == childCount &&
        _cachedAxisDirection == constraints.axisDirection &&
        _cachedGrowthDirection == constraints.growthDirection &&
        _cachedCrossAxisExtent != null &&
        (_cachedCrossAxisExtent! - constraints.crossAxisExtent).abs() < 0.001) {
      return _cachedLayout!;
    }

    final layout = _flexboxDelegate.getLayout(
      constraints,
      childCount: childCount,
    );
    if (_flexboxDelegate.shouldCacheLayout) {
      _cachedLayout = layout;
      _cachedChildCount = childCount;
      _cachedCrossAxisExtent = constraints.crossAxisExtent;
      _cachedAxisDirection = constraints.axisDirection;
      _cachedGrowthDirection = constraints.growthDirection;
    } else {
      _invalidateLayoutCache();
    }
    return layout;
  }

  /// Returns the cross-axis position of the given child.
  ///
  /// This is used by the parent to position the child within the viewport.
  @override
  double childCrossAxisPosition(RenderBox child) {
    final childParentData = child.parentData! as SliverFlexboxParentData;
    return childParentData.crossAxisOffset ?? 0;
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    // Calculate layout
    final int childCount = childManager.childCount;
    if (childCount == 0) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final SliverFlexboxLayout layout = _getLayout(
      constraints,
      childCount: childCount,
    );

    final int firstIndex = layout.getFirstChildIndexForScrollOffset(
      scrollOffset,
    );
    final int? targetLastIndex = targetEndScrollOffset.isFinite
        ? layout.getLastChildIndexForScrollOffset(targetEndScrollOffset)
        : null;

    if (firstChild != null) {
      final int leadingGarbage = calculateLeadingGarbage(
        firstIndex: firstIndex,
      );
      final int trailingGarbage = targetLastIndex != null
          ? calculateTrailingGarbage(lastIndex: targetLastIndex)
          : 0;
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    final SliverFlexboxChildGeometry firstChildGeometry =
        layout.getChildGeometry(firstIndex);

    if (firstChild == null) {
      if (!addInitialChild(
        index: firstIndex,
        layoutOffset: firstChildGeometry.scrollOffset,
      )) {
        // There are either no children, or we are past the end of all our children.
        final double max = layout.scrollExtent;
        geometry = SliverGeometry(scrollExtent: max, maxPaintExtent: max);
        childManager.didFinishLayout();
        return;
      }
    }

    final double leadingScrollOffset = firstChildGeometry.scrollOffset;
    double trailingScrollOffset = firstChildGeometry.trailingScrollOffset;
    RenderBox? trailingChildWithLayout;
    var reachedEnd = false;

    for (int index = indexOf(firstChild!) - 1; index >= firstIndex; --index) {
      final childGeometry = layout.getChildGeometry(index);
      final RenderBox child = insertAndLayoutLeadingChild(
        BoxConstraints.tightFor(
          width: childGeometry.crossAxisExtent,
          height: childGeometry.mainAxisExtent,
        ),
      )!;
      final childParentData = child.parentData! as SliverFlexboxParentData;
      childParentData.layoutOffset = childGeometry.scrollOffset;
      childParentData.crossAxisOffset = childGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingChildWithLayout = trailingChildWithLayout ?? child;
      trailingScrollOffset =
          trailingScrollOffset > childGeometry.trailingScrollOffset
              ? trailingScrollOffset
              : childGeometry.trailingScrollOffset;
    }

    if (trailingChildWithLayout == null) {
      firstChild!.layout(
        BoxConstraints.tightFor(
          width: firstChildGeometry.crossAxisExtent,
          height: firstChildGeometry.mainAxisExtent,
        ),
      );
      final childParentData =
          firstChild!.parentData! as SliverFlexboxParentData;
      childParentData.layoutOffset = firstChildGeometry.scrollOffset;
      childParentData.crossAxisOffset = firstChildGeometry.crossAxisOffset;
      trailingChildWithLayout = firstChild;
    }

    for (int index = indexOf(trailingChildWithLayout!) + 1;
        targetLastIndex == null || index <= targetLastIndex;
        ++index) {
      final childGeometry = layout.getChildGeometry(index);
      final BoxConstraints childConstraints = BoxConstraints.tightFor(
        width: childGeometry.crossAxisExtent,
        height: childGeometry.mainAxisExtent,
      );
      RenderBox? child = childAfter(trailingChildWithLayout!);
      if (child == null || indexOf(child) != index) {
        child = insertAndLayoutChild(
          childConstraints,
          after: trailingChildWithLayout,
        );
        if (child == null) {
          reachedEnd = true;
          // We have run out of children.
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      final childParentData = child.parentData! as SliverFlexboxParentData;
      childParentData.layoutOffset = childGeometry.scrollOffset;
      childParentData.crossAxisOffset = childGeometry.crossAxisOffset;
      assert(childParentData.index == index);
      trailingScrollOffset =
          trailingScrollOffset > childGeometry.trailingScrollOffset
              ? trailingScrollOffset
              : childGeometry.trailingScrollOffset;
    }

    final int lastIndex = indexOf(lastChild!);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild!) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    final double estimatedTotalExtent = reachedEnd
        ? trailingScrollOffset
        : childManager.estimateMaxScrollOffset(
            constraints,
            firstIndex: indexOf(firstChild!),
            lastIndex: lastIndex,
            leadingScrollOffset: leadingScrollOffset,
            trailingScrollOffset: trailingScrollOffset,
          );
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset < constraints.scrollOffset
          ? leadingScrollOffset
          : constraints.scrollOffset,
      to: trailingScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    geometry = SliverGeometry(
      scrollExtent: estimatedTotalExtent,
      paintExtent: paintExtent,
      maxPaintExtent: estimatedTotalExtent,
      cacheExtent: cacheExtent,
      hasVisualOverflow: estimatedTotalExtent > paintExtent ||
          constraints.scrollOffset > 0.0 ||
          constraints.overlap != 0.0,
    );

    // We may have started the layout while scrolled to the end, which
    // would not expose a new child.
    if (estimatedTotalExtent == trailingScrollOffset) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}
