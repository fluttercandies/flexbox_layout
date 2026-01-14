import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart' hide ViewportBuilder;

import 'sliver_dynamic_flexbox.dart';

int _defaultSemanticIndexCallback(Widget widget, int localIndex) => localIndex;

/// A scrollable list that displays children in a dynamic flexbox layout.
///
/// Unlike [FlexboxList] which requires pre-calculated aspect ratios,
/// this widget measures children during layout to determine their sizes.
/// This is useful for content with unknown sizes, such as:
/// - Network images that load asynchronously
/// - Text content with variable lengths
/// - Dynamic content that changes size
///
/// The widget supports infinite scrolling and item reuse for optimal
/// performance with large datasets.
///
/// ## Basic Usage
///
/// ```dart
/// DynamicFlexboxList(
///   targetRowHeight: 200,
///   mainAxisSpacing: 8,
///   crossAxisSpacing: 8,
///   itemBuilder: (context, index) => Image.network(
///     urls[index],
///     fit: BoxFit.cover,
///   ),
///   itemCount: urls.length,
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
///
/// For use in a [CustomScrollView], see [SliverDynamicFlexbox].
class DynamicFlexboxList extends StatelessWidget {
  /// Creates a scrollable dynamic flexbox list.
  const DynamicFlexboxList({
    super.key,
    required this.itemBuilder,
    this.itemCount,
    this.targetRowHeight = 200.0,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.minRowFillFactor = 0.8,
    this.lastChildLayoutTypeBuilder,
    this.collectGarbage,
    this.viewportBuilder,
    this.closeToTrailing = false,
    this.defaultAspectRatio = 1.0,
    this.debounceDuration = const Duration(milliseconds: 150),
    this.aspectRatioChangeThreshold = 0.01,
    this.crossAxisExtentChangeThreshold = 1.0,
    this.aspectRatioGetter,
    this.scrollController,
    this.primary,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.padding,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.dragStartBehavior,
    this.keyboardDismissBehavior,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.findChildIndexCallback,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback,
    this.semanticIndexOffset = 0,
  })  : assert(targetRowHeight > 0),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(minRowFillFactor > 0 && minRowFillFactor <= 1),
        assert(aspectRatioChangeThreshold >= 0),
        assert(crossAxisExtentChangeThreshold >= 0);

  /// Called to build children for the list.
  ///
  /// The children are measured during layout, so they should have intrinsic
  /// sizes. For images, use [Image.network] or [Image.asset] directly.
  final NullableIndexedWidgetBuilder itemBuilder;

  /// The number of items in the list.
  ///
  /// If null, the list is unbounded and [itemBuilder] will be called
  /// indefinitely.
  final int? itemCount;

  /// The target height for each row.
  ///
  /// Items will be scaled to approximately this height while filling rows.
  final double targetRowHeight;

  /// The spacing between rows in the main axis (scroll direction).
  final double mainAxisSpacing;

  /// The spacing between items in the cross axis.
  final double crossAxisSpacing;

  /// The minimum fill factor for the last row.
  ///
  /// If the last row fills less than this factor of the available width,
  /// items won't be scaled up. Default is 0.8 (80%).
  final double minRowFillFactor;

  /// Builder to determine the layout type for the last child.
  final LastChildLayoutTypeBuilder? lastChildLayoutTypeBuilder;

  /// Callback when children are garbage collected.
  final CollectGarbage? collectGarbage;

  /// Callback that reports the currently visible range.
  final ViewportBuilder? viewportBuilder;

  /// When true, children are positioned close to the trailing edge.
  final bool closeToTrailing;

  /// The default aspect ratio to use before a child's actual size is known.
  final double defaultAspectRatio;

  /// Duration to wait before applying batched size updates.
  final Duration debounceDuration;

  /// Threshold for aspect ratio change detection.
  ///
  /// Only when the difference between the current measured aspect ratio
  /// and the cached ratio exceeds this value will a layout update be scheduled.
  /// Default is 0.01 (1% change).
  final double aspectRatioChangeThreshold;

  /// Threshold for crossAxisExtent change to trigger cache clear.
  ///
  /// When the viewport width changes by more than this value, the aspect
  /// ratio cache is cleared to recalculate the layout.
  /// Default is 1.0 pixel.
  final double crossAxisExtentChangeThreshold;

  /// Optional callback to provide aspect ratios for children.
  final AspectRatioGetter? aspectRatioGetter;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  final ScrollController? scrollController;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  final bool? primary;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// The axis along which the scroll view scrolls.
  final Axis scrollDirection;

  /// Whether the scroll view scrolls in the reading direction.
  final bool reverse;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry? padding;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  final bool shrinkWrap;

  /// The viewport has an area before and after the visible area to cache items
  /// that are about to become visible when the user scrolls.
  final double? cacheExtent;

  /// Determines the way that drag start behavior is handled.
  final DragStartBehavior? dragStartBehavior;

  /// Defines how this [ScrollView] will dismiss the keyboard automatically.
  final ScrollViewKeyboardDismissBehavior? keyboardDismissBehavior;

  /// Restoration ID to save and restore the scroll offset of the scrollable.
  final String? restorationId;

  /// The content will be clipped (or not) according to this option.
  final Clip clipBehavior;

  /// Called to find the index of a child based on its key.
  final ChildIndexGetter? findChildIndexCallback;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [IndexedSemantics].
  final bool addSemanticIndexes;

  /// A callback that returns the semantic index of the child at the given
  /// index.
  final SemanticIndexCallback? semanticIndexCallback;

  /// An offset added to the semantic indexes of the children.
  final int semanticIndexOffset;

  @override
  Widget build(BuildContext context) {
    final sliverDelegate = SliverChildBuilderDelegate(
      itemBuilder,
      childCount: itemCount,
      findChildIndexCallback: findChildIndexCallback,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      semanticIndexCallback:
          semanticIndexCallback ?? _defaultSemanticIndexCallback,
      semanticIndexOffset: semanticIndexOffset,
    );

    Widget sliver = SliverDynamicFlexbox(
      flexboxDelegate: SliverDynamicFlexboxDelegate(
        targetRowHeight: targetRowHeight,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        minRowFillFactor: minRowFillFactor,
        defaultAspectRatio: defaultAspectRatio,
        debounceDuration: debounceDuration,
        aspectRatioChangeThreshold: aspectRatioChangeThreshold,
        crossAxisExtentChangeThreshold: crossAxisExtentChangeThreshold,
        lastChildLayoutTypeBuilder: lastChildLayoutTypeBuilder,
        collectGarbage: collectGarbage,
        viewportBuilder: viewportBuilder,
        closeToTrailing: closeToTrailing,
        aspectRatioGetter: aspectRatioGetter,
      ),
      childDelegate: sliverDelegate,
    );

    if (padding != null) {
      sliver = SliverPadding(padding: padding!, sliver: sliver);
    }

    return CustomScrollView(
      controller: scrollController,
      primary: primary,
      physics: physics,
      scrollDirection: scrollDirection,
      reverse: reverse,
      shrinkWrap: shrinkWrap,
      cacheExtent: cacheExtent,
      dragStartBehavior: dragStartBehavior ?? DragStartBehavior.start,
      keyboardDismissBehavior:
          keyboardDismissBehavior ?? ScrollViewKeyboardDismissBehavior.manual,
      restorationId: restorationId,
      clipBehavior: clipBehavior,
      slivers: [sliver],
    );
  }
}
