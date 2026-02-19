import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'enums.dart';
import 'flex_item_data.dart';
import 'flex_line.dart';

/// Parent data for use with [RenderFlexbox].
///
/// This class stores layout-specific information for each child in a
/// [RenderFlexbox] container. It extends [ContainerBoxParentData] to
/// include flexbox-specific properties.
///
/// ## Properties
///
/// * [flexItemData] - The flex properties for this child
/// * [measuredWidth] / [measuredHeight] - The child's measured size
/// * [frozen] - Whether this child's size is fixed during flex calculation
/// * [flexLineIndex] - Which flex line this child belongs to
///
/// See also:
/// * [FlexItemData], which holds the flex properties
/// * [FlexItem], the widget that sets this parent data
class FlexboxParentData extends ContainerBoxParentData<RenderBox> {
  /// The flex item data for this child.
  ///
  /// This contains all the flex properties (flexGrow, flexShrink, etc.)
  /// that control how this child behaves in the flexbox layout.
  FlexItemData flexItemData = const FlexItemData();

  /// The measured width of this child.
  ///
  /// This is set during the layout phase and may differ from the child's
  /// final size if flex properties cause it to grow or shrink.
  double? measuredWidth;

  /// The measured height of this child.
  ///
  /// This is set during the layout phase and may differ from the child's
  /// final size if flex properties cause it to grow or shrink.
  double? measuredHeight;

  /// Whether this child is frozen during flex calculation.
  ///
  /// A frozen child has reached its minimum or maximum size constraint
  /// and will not be further adjusted during flex grow/shrink calculations.
  bool frozen = false;

  /// The flex line index this child belongs to.
  ///
  /// This is set during layout to track which flex line (row or column)
  /// the child was placed in.
  int? flexLineIndex;

  /// Resets the parent data to its initial state.
  ///
  /// This clears all layout measurements and flags, preparing the parent
  /// data for a new layout cycle.
  void reset() {
    measuredWidth = null;
    measuredHeight = null;
    frozen = false;
    flexLineIndex = null;
  }

  @override
  String toString() {
    return 'FlexboxParentData(flexItemData: $flexItemData)';
  }
}

/// A render object that implements the CSS Flexbox layout algorithm.
///
/// [RenderFlexbox] is the rendering backend for the [Flexbox] widget. It
/// implements the full CSS Flexbox specification, including:
///
/// * Direction-based layout ([FlexDirection])
/// * Flex wrapping ([FlexWrap])
/// * Main axis alignment ([JustifyContent])
/// * Cross axis alignment ([AlignItems], [AlignContent])
/// * Flexible sizing with grow/shrink ([FlexItemData.flexGrow], [FlexItemData.flexShrink])
/// * Aspect ratio-based sizing ([FlexItemData.flexBasisPercent])
///
/// ## Layout Algorithm
///
/// 1. Children are measured and grouped into flex lines
/// 2. For each line, items are grown or shrunk based on available space
/// 3. Cross-axis alignment is applied to each line
/// 4. Children are positioned according to alignment properties
///
/// ## Flex Grow and Shrink
///
/// When space is distributed, children with higher [FlexItemData.flexGrow]
/// values receive more space. When space must be reclaimed, children with
/// higher [FlexItemData.flexShrink] values shrink more.
///
/// This render object is typically not used directly. Use [Flexbox] instead.
///
/// See also:
/// * [Flexbox], the widget that creates this render object
/// * [FlexItemData], which holds the flex properties for each child
/// * [FlexboxParentData], which stores layout information for each child
class RenderFlexbox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexboxParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexboxParentData> {
  /// Creates a new [RenderFlexbox].
  ///
  /// The [flexDirection] parameter defaults to [FlexDirection.row].
  /// The [flexWrap] parameter defaults to [FlexWrap.wrap].
  /// The [justifyContent] parameter defaults to [JustifyContent.flexStart].
  /// The [alignItems] parameter defaults to [AlignItems.flexStart].
  /// The [alignContent] parameter defaults to [AlignContent.flexStart].
  /// The [textDirection] parameter defaults to [TextDirection.ltr].
  RenderFlexbox({
    List<RenderBox>? children,
    FlexDirection flexDirection = FlexDirection.row,
    FlexWrap flexWrap = FlexWrap.wrap,
    JustifyContent justifyContent = JustifyContent.flexStart,
    AlignItems alignItems = AlignItems.flexStart,
    AlignContent alignContent = AlignContent.flexStart,
    TextDirection textDirection = TextDirection.ltr,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    int? maxLines,
  })  : _flexDirection = flexDirection,
        _flexWrap = flexWrap,
        _justifyContent = justifyContent,
        _alignItems = alignItems,
        _alignContent = alignContent,
        _textDirection = textDirection,
        _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing,
        _maxLines = maxLines {
    addAll(children);
  }

  /// The direction in which flex items are placed.
  FlexDirection get flexDirection => _flexDirection;
  FlexDirection _flexDirection;
  set flexDirection(FlexDirection value) {
    if (_flexDirection == value) return;
    _flexDirection = value;
    markNeedsLayout();
  }

  /// How flex items wrap.
  FlexWrap get flexWrap => _flexWrap;
  FlexWrap _flexWrap;
  set flexWrap(FlexWrap value) {
    if (_flexWrap == value) return;
    _flexWrap = value;
    markNeedsLayout();
  }

  /// How flex items are aligned along the main axis.
  JustifyContent get justifyContent => _justifyContent;
  JustifyContent _justifyContent;
  set justifyContent(JustifyContent value) {
    if (_justifyContent == value) return;
    _justifyContent = value;
    markNeedsLayout();
  }

  /// How flex items are aligned along the cross axis.
  AlignItems get alignItems => _alignItems;
  AlignItems _alignItems;
  set alignItems(AlignItems value) {
    if (_alignItems == value) return;
    _alignItems = value;
    markNeedsLayout();
  }

  /// How flex lines are aligned in the cross axis.
  AlignContent get alignContent => _alignContent;
  AlignContent _alignContent;
  set alignContent(AlignContent value) {
    if (_alignContent == value) return;
    _alignContent = value;
    markNeedsLayout();
  }

  /// The text direction used to resolve the start and end of the layout.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The spacing between flex items along the main axis.
  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  /// The spacing between flex lines along the cross axis.
  double get crossAxisSpacing => _crossAxisSpacing;
  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing == value) return;
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  /// The maximum number of flex lines. If null, there is no limit.
  int? get maxLines => _maxLines;
  int? _maxLines;
  set maxLines(int? value) {
    if (_maxLines == value) return;
    _maxLines = value;
    markNeedsLayout();
  }

  /// Whether the main axis is horizontal.
  bool get _isMainAxisHorizontal => _flexDirection.isHorizontal;

  /// The flex lines calculated during layout.
  final List<FlexLine> _flexLines = [];

  /// Reordered children for O(1) index access during layout.
  List<RenderBox> _reorderedChildren = const [];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexboxParentData) {
      child.parentData = FlexboxParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(height, (child, extent) {
      return child.getMinIntrinsicWidth(extent);
    });
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(height, (child, extent) {
      return child.getMaxIntrinsicWidth(extent);
    });
  }

  double _computeIntrinsicWidth(
    double height,
    double Function(RenderBox child, double extent) intrinsicWidth,
  ) {
    if (_isMainAxisHorizontal) {
      double width = 0;
      RenderBox? child = firstChild;
      while (child != null) {
        width += intrinsicWidth(child, height);
        child = childAfter(child);
      }
      return width;
    } else {
      double maxWidth = 0;
      RenderBox? child = firstChild;
      while (child != null) {
        maxWidth = math.max(maxWidth, intrinsicWidth(child, height));
        child = childAfter(child);
      }
      return maxWidth;
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width, (child, extent) {
      return child.getMinIntrinsicHeight(extent);
    });
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width, (child, extent) {
      return child.getMaxIntrinsicHeight(extent);
    });
  }

  double _computeIntrinsicHeight(
    double width,
    double Function(RenderBox child, double extent) intrinsicHeight,
  ) {
    if (!_isMainAxisHorizontal) {
      double height = 0;
      RenderBox? child = firstChild;
      while (child != null) {
        height += intrinsicHeight(child, width);
        child = childAfter(child);
      }
      return height;
    } else {
      double maxHeight = 0;
      RenderBox? child = firstChild;
      while (child != null) {
        maxHeight = math.max(maxHeight, intrinsicHeight(child, width));
        child = childAfter(child);
      }
      return maxHeight;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeLayout(constraints, dry: true);
  }

  @override
  void performLayout() {
    size = _computeLayout(constraints, dry: false);
  }

  Size _computeLayout(BoxConstraints constraints, {required bool dry}) {
    _flexLines.clear();
    _reorderedChildren = _createReorderedChildren();

    // Reset parent data
    for (final child in _reorderedChildren) {
      final parentData = child.parentData! as FlexboxParentData;
      parentData.reset();
    }

    // Calculate flex lines
    if (_isMainAxisHorizontal) {
      _calculateHorizontalFlexLines(constraints);
    } else {
      _calculateVerticalFlexLines(constraints);
    }

    // Determine main size (expand or shrink)
    _determineMainSize(constraints);

    // Determine cross size
    _determineCrossSize(constraints);

    // Stretch views if needed
    if (!dry) {
      _stretchViews();
    }

    // Calculate final size
    final computedSize = _calculateFinalSize(constraints);

    // Layout children
    if (!dry) {
      _layoutChildren(constraints, computedSize);
    }

    return computedSize;
  }

  List<RenderBox> _createReorderedChildren() {
    final children = <RenderBox>[];
    bool needsSort = false;
    int? previousOrder;

    for (RenderBox? child = firstChild;
        child != null;
        child = childAfter(child)) {
      final parentData = child.parentData! as FlexboxParentData;
      final order = parentData.flexItemData.order;
      if (previousOrder != null && order < previousOrder) {
        needsSort = true;
      }
      previousOrder = order;
      children.add(child);
    }

    if (!needsSort || children.length <= 1) {
      return children;
    }

    final orderedChildren = List<_OrderedChild>.generate(
      children.length,
      (index) {
        final child = children[index];
        final order =
            (child.parentData! as FlexboxParentData).flexItemData.order;
        return _OrderedChild(
          child: child,
          order: order,
          originalIndex: index,
        );
      },
      growable: false,
    );

    orderedChildren.sort((a, b) {
      final orderCompare = a.order.compareTo(b.order);
      if (orderCompare != 0) return orderCompare;
      // Keep source order stable when "order" is identical.
      return a.originalIndex.compareTo(b.originalIndex);
    });

    return List<RenderBox>.generate(
      orderedChildren.length,
      (index) => orderedChildren[index].child,
      growable: false,
    );
  }

  RenderBox? _getReorderedChildAt(int index) {
    if (index < 0 || index >= _reorderedChildren.length) {
      return null;
    }
    return _reorderedChildren[index];
  }

  void _calculateHorizontalFlexLines(BoxConstraints constraints) {
    _calculateFlexLines(
      constraints,
      mainSize: constraints.maxWidth,
      crossSize: constraints.maxHeight,
    );
  }

  void _calculateVerticalFlexLines(BoxConstraints constraints) {
    _calculateFlexLines(
      constraints,
      mainSize: constraints.maxHeight,
      crossSize: constraints.maxWidth,
    );
  }

  void _calculateFlexLines(
    BoxConstraints constraints, {
    required double mainSize,
    required double crossSize,
  }) {
    final childCount = this.childCount;
    if (childCount == 0) return;

    int indexInFlexLine = 0;
    double largestSizeInCross = 0;
    int lastProcessedIndex = -1;

    var flexLine = FlexLine();
    flexLine.firstIndex = 0;

    for (int i = 0; i < childCount; i++) {
      final child = _getReorderedChildAt(i);
      if (child == null) continue;
      lastProcessedIndex = i;

      final parentData = child.parentData! as FlexboxParentData;
      final flexItemData = parentData.flexItemData;

      // Calculate initial main size based on flexBasisPercent
      double? flexBasisMainSize;
      if (flexItemData.flexBasisPercent > 0 &&
          flexItemData.flexBasisPercent <= 1.0 &&
          mainSize.isFinite) {
        flexBasisMainSize = mainSize * flexItemData.flexBasisPercent;
      }

      // Measure child
      final childConstraints = _createChildConstraints(
        flexItemData,
        mainSize,
        crossSize,
        flexBasisMainSize: flexBasisMainSize,
      );

      child.layout(childConstraints, parentUsesSize: true);
      parentData.measuredWidth = child.size.width;
      parentData.measuredHeight = child.size.height;

      // Check size constraints
      _checkSizeConstraints(child, flexItemData);

      // Check if wrap is required
      final childMainSizeWithSpacing = _getChildMainSize(child) +
          (indexInFlexLine > 0 ? _mainAxisSpacing : 0);

      if (_isWrapRequired(
        mainSize,
        flexLine.mainSize,
        childMainSizeWithSpacing,
        flexItemData,
        i,
        indexInFlexLine,
      )) {
        if (flexLine.itemCountNotGone > 0) {
          flexLine.lastIndex = i - 1;
          _flexLines.add(flexLine);
        }

        flexLine = FlexLine();
        flexLine.firstIndex = i;
        indexInFlexLine = 0;
        largestSizeInCross = 0;
      }

      // Update flex line
      flexLine.itemCount++;
      flexLine.anyItemsHaveFlexGrow |= flexItemData.flexGrow > kFlexGrowDefault;
      flexLine.anyItemsHaveFlexShrink |=
          flexItemData.flexShrink > kFlexShrinkNotSet;

      parentData.flexLineIndex = _flexLines.length;

      flexLine.mainSize += _getChildMainSize(child) +
          (indexInFlexLine > 0 ? _mainAxisSpacing : 0);
      flexLine.totalFlexGrow += flexItemData.flexGrow;
      flexLine.totalFlexShrink += flexItemData.flexShrink;

      final childCrossSize = _getChildCrossSize(child);
      largestSizeInCross = math.max(largestSizeInCross, childCrossSize);
      flexLine.crossSize = math.max(flexLine.crossSize, largestSizeInCross);

      if (flexItemData.alignSelf == AlignSelf.stretch ||
          (flexItemData.alignSelf == AlignSelf.auto &&
              _alignItems == AlignItems.stretch)) {
        flexLine.indicesAlignSelfStretch.add(i);
      }

      // Handle baseline
      if (_isMainAxisHorizontal && _alignItems == AlignItems.baseline) {
        final baseline = child.getDistanceToBaseline(TextBaseline.alphabetic);
        if (baseline != null) {
          if (_flexWrap != FlexWrap.wrapReverse) {
            flexLine.maxBaseline = math.max(flexLine.maxBaseline, baseline);
          } else {
            flexLine.maxBaseline = math.max(
              flexLine.maxBaseline,
              child.size.height - baseline,
            );
          }
        }
      }

      indexInFlexLine++;
    }

    // Add the last flex line
    if (flexLine.itemCount > 0) {
      flexLine.lastIndex = lastProcessedIndex;
      _flexLines.add(flexLine);
    }
  }

  BoxConstraints _createChildConstraints(
    FlexItemData flexItemData,
    double mainSize,
    double crossSize, {
    double? flexBasisMainSize,
  }) {
    final minWidth = flexItemData.minWidth ?? 0;
    final minHeight = flexItemData.minHeight ?? 0;
    final maxWidth = flexItemData.maxWidth ?? double.infinity;
    final maxHeight = flexItemData.maxHeight ?? double.infinity;
    final effectiveCrossLimit = crossSize.isFinite ? math.max(0.0, crossSize) : double.infinity;

    if (_isMainAxisHorizontal) {
      // If flexBasisPercent is set, use it as the exact width
      if (flexBasisMainSize != null) {
        final constrainedWidth = flexBasisMainSize.clamp(minWidth, maxWidth);
        return BoxConstraints(
          minWidth: constrainedWidth,
          maxWidth: constrainedWidth,
          minHeight: minHeight,
          maxHeight: math.min(maxHeight, effectiveCrossLimit),
        );
      }
      return BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
        minHeight: minHeight,
        maxHeight: math.min(maxHeight, effectiveCrossLimit),
      );
    } else {
      // If flexBasisPercent is set, use it as the exact height
      if (flexBasisMainSize != null) {
        final constrainedHeight = flexBasisMainSize.clamp(minHeight, maxHeight);
        return BoxConstraints(
          minWidth: minWidth,
          maxWidth: math.min(maxWidth, effectiveCrossLimit),
          minHeight: constrainedHeight,
          maxHeight: constrainedHeight,
        );
      }
      return BoxConstraints(
        minWidth: minWidth,
        maxWidth: math.min(maxWidth, effectiveCrossLimit),
        minHeight: minHeight,
        maxHeight: maxHeight,
      );
    }
  }

  void _checkSizeConstraints(RenderBox child, FlexItemData flexItemData) {
    final parentData = child.parentData! as FlexboxParentData;
    var width = parentData.measuredWidth!;
    var height = parentData.measuredHeight!;
    bool needsRemeasure = false;

    if (flexItemData.minWidth != null && width < flexItemData.minWidth!) {
      width = flexItemData.minWidth!;
      needsRemeasure = true;
    }
    if (flexItemData.maxWidth != null && width > flexItemData.maxWidth!) {
      width = flexItemData.maxWidth!;
      needsRemeasure = true;
    }
    if (flexItemData.minHeight != null && height < flexItemData.minHeight!) {
      height = flexItemData.minHeight!;
      needsRemeasure = true;
    }
    if (flexItemData.maxHeight != null && height > flexItemData.maxHeight!) {
      height = flexItemData.maxHeight!;
      needsRemeasure = true;
    }

    if (needsRemeasure) {
      child.layout(
        BoxConstraints.tight(Size(width, height)),
        parentUsesSize: true,
      );
      parentData.measuredWidth = child.size.width;
      parentData.measuredHeight = child.size.height;
    }
  }

  bool _isWrapRequired(
    double maxSize,
    double currentLength,
    double childLength,
    FlexItemData flexItemData,
    int index,
    int indexInFlexLine,
  ) {
    if (_flexWrap == FlexWrap.noWrap) return false;
    // _flexLines only contains finalized lines; the current in-progress line
    // should also count toward maxLines.
    if (_maxLines != null && (_flexLines.length + 1) >= _maxLines!) {
      return false;
    }
    if (flexItemData.wrapBefore && indexInFlexLine > 0) return true;
    return maxSize.isFinite && currentLength + childLength > maxSize;
  }

  double _getChildMainSize(RenderBox child) {
    return _isMainAxisHorizontal ? child.size.width : child.size.height;
  }

  double _getChildCrossSize(RenderBox child) {
    return _isMainAxisHorizontal ? child.size.height : child.size.width;
  }

  void _determineMainSize(BoxConstraints constraints) {
    final mainSize = _isMainAxisHorizontal
        ? (constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _getLargestMainSize())
        : (constraints.hasBoundedHeight
            ? constraints.maxHeight
            : _getLargestMainSize());

    for (final flexLine in _flexLines) {
      if (flexLine.mainSize < mainSize && flexLine.anyItemsHaveFlexGrow) {
        _expandFlexItems(flexLine, mainSize);
      } else if (flexLine.mainSize > mainSize &&
          flexLine.anyItemsHaveFlexShrink) {
        _shrinkFlexItems(flexLine, mainSize);
      }
    }
  }

  double _getLargestMainSize() {
    double largest = 0;
    for (final flexLine in _flexLines) {
      largest = math.max(largest, flexLine.mainSize);
    }
    return largest;
  }

  void _expandFlexItems(FlexLine flexLine, double maxMainSize) {
    if (flexLine.totalFlexGrow <= 0 || maxMainSize < flexLine.mainSize) return;

    // Reset frozen state
    for (int i = flexLine.firstIndex; i <= flexLine.lastIndex; i++) {
      final child = _getReorderedChildAt(i);
      if (child == null) continue;
      final parentData = child.parentData! as FlexboxParentData;
      parentData.frozen = false;
    }

    bool needsReexpand = true;
    while (needsReexpand) {
      needsReexpand = false;
      final freeSpace = maxMainSize - flexLine.mainSize;
      if (freeSpace <= 0 || flexLine.totalFlexGrow <= 0) break;

      final unitSpace = freeSpace / flexLine.totalFlexGrow;
      double accumulatedRoundError = 0;
      double newMainSize = 0;

      for (int i = flexLine.firstIndex; i <= flexLine.lastIndex; i++) {
        final child = _getReorderedChildAt(i);
        if (child == null) continue;

        final parentData = child.parentData! as FlexboxParentData;
        final flexItemData = parentData.flexItemData;

        if (parentData.frozen || flexItemData.flexGrow <= 0) {
          newMainSize += _getChildMainSize(child);
          if (i > flexLine.firstIndex) newMainSize += _mainAxisSpacing;
          continue;
        }

        final childMainSize = _getChildMainSize(child);
        double rawNewSize = childMainSize + unitSpace * flexItemData.flexGrow;

        if (i == flexLine.lastIndex) {
          rawNewSize += accumulatedRoundError;
        }

        double newSize = rawNewSize.roundToDouble();
        final maxSize = _isMainAxisHorizontal
            ? flexItemData.maxWidth
            : flexItemData.maxHeight;

        if (maxSize != null && newSize > maxSize) {
          needsReexpand = true;
          newSize = maxSize;
          parentData.frozen = true;
          flexLine.totalFlexGrow -= flexItemData.flexGrow;
        } else {
          accumulatedRoundError += rawNewSize - newSize;
          if (accumulatedRoundError > 1.0) {
            newSize += 1;
            accumulatedRoundError -= 1.0;
          } else if (accumulatedRoundError < -1.0) {
            newSize -= 1;
            accumulatedRoundError += 1.0;
          }
        }

        // Re-measure child
        if (_isMainAxisHorizontal) {
          child.layout(
            BoxConstraints(
              minWidth: newSize,
              maxWidth: newSize,
              maxHeight: flexLine.crossSize,
            ),
            parentUsesSize: true,
          );
        } else {
          child.layout(
            BoxConstraints(
              maxWidth: flexLine.crossSize,
              minHeight: newSize,
              maxHeight: newSize,
            ),
            parentUsesSize: true,
          );
        }

        parentData.measuredWidth = child.size.width;
        parentData.measuredHeight = child.size.height;

        newMainSize += _getChildMainSize(child);
        if (i > flexLine.firstIndex) newMainSize += _mainAxisSpacing;

        // Update cross size
        final crossSize = _getChildCrossSize(child);
        flexLine.crossSize = math.max(flexLine.crossSize, crossSize);
      }

      flexLine.mainSize = newMainSize;
    }
  }

  void _shrinkFlexItems(FlexLine flexLine, double maxMainSize) {
    if (flexLine.totalFlexShrink <= 0 || maxMainSize > flexLine.mainSize) {
      return;
    }

    // Reset frozen state
    for (int i = flexLine.firstIndex; i <= flexLine.lastIndex; i++) {
      final child = _getReorderedChildAt(i);
      if (child == null) continue;
      final parentData = child.parentData! as FlexboxParentData;
      parentData.frozen = false;
    }

    bool needsReshrink = true;
    while (needsReshrink) {
      needsReshrink = false;
      final overflowSpace = flexLine.mainSize - maxMainSize;
      if (overflowSpace <= 0 || flexLine.totalFlexShrink <= 0) break;

      final unitShrink = overflowSpace / flexLine.totalFlexShrink;
      double accumulatedRoundError = 0;
      double newMainSize = 0;

      for (int i = flexLine.firstIndex; i <= flexLine.lastIndex; i++) {
        final child = _getReorderedChildAt(i);
        if (child == null) continue;

        final parentData = child.parentData! as FlexboxParentData;
        final flexItemData = parentData.flexItemData;

        if (parentData.frozen || flexItemData.flexShrink <= 0) {
          newMainSize += _getChildMainSize(child);
          if (i > flexLine.firstIndex) newMainSize += _mainAxisSpacing;
          continue;
        }

        final childMainSize = _getChildMainSize(child);
        double rawNewSize =
            childMainSize - unitShrink * flexItemData.flexShrink;

        if (i == flexLine.lastIndex) {
          rawNewSize += accumulatedRoundError;
        }

        double newSize = rawNewSize.roundToDouble();
        final minSize = _isMainAxisHorizontal
            ? flexItemData.minWidth
            : flexItemData.minHeight;

        if (minSize != null && newSize < minSize) {
          needsReshrink = true;
          newSize = minSize;
          parentData.frozen = true;
          flexLine.totalFlexShrink -= flexItemData.flexShrink;
        } else if (newSize < 0) {
          needsReshrink = true;
          newSize = 0;
          parentData.frozen = true;
          flexLine.totalFlexShrink -= flexItemData.flexShrink;
        } else {
          accumulatedRoundError += rawNewSize - newSize;
          if (accumulatedRoundError > 1.0) {
            newSize += 1;
            accumulatedRoundError -= 1.0;
          } else if (accumulatedRoundError < -1.0) {
            newSize -= 1;
            accumulatedRoundError += 1.0;
          }
        }

        // Re-measure child
        if (_isMainAxisHorizontal) {
          child.layout(
            BoxConstraints(
              minWidth: newSize,
              maxWidth: newSize,
              maxHeight: flexLine.crossSize,
            ),
            parentUsesSize: true,
          );
        } else {
          child.layout(
            BoxConstraints(
              maxWidth: flexLine.crossSize,
              minHeight: newSize,
              maxHeight: newSize,
            ),
            parentUsesSize: true,
          );
        }

        parentData.measuredWidth = child.size.width;
        parentData.measuredHeight = child.size.height;

        newMainSize += _getChildMainSize(child);
        if (i > flexLine.firstIndex) newMainSize += _mainAxisSpacing;

        // Update cross size
        final crossSize = _getChildCrossSize(child);
        flexLine.crossSize = math.max(flexLine.crossSize, crossSize);
      }

      flexLine.mainSize = newMainSize;
    }
  }

  void _determineCrossSize(BoxConstraints constraints) {
    final crossSize =
        _isMainAxisHorizontal ? constraints.maxHeight : constraints.maxWidth;

    if (!crossSize.isFinite) return;

    final totalCrossSize = _getSumOfCrossSize();
    if (_flexLines.length == 1) {
      _flexLines[0].crossSize = crossSize;
    } else if (_flexLines.length >= 2) {
      switch (_alignContent) {
        case AlignContent.stretch:
          if (totalCrossSize >= crossSize) break;
          final freeSpace = crossSize - totalCrossSize;
          final spacePerLine = freeSpace / _flexLines.length;
          for (final flexLine in _flexLines) {
            flexLine.crossSize += spacePerLine;
          }
          break;
        case AlignContent.flexStart:
          // No adjustment needed
          break;
        case AlignContent.flexEnd:
          // Will be handled in layout
          break;
        case AlignContent.center:
          // Will be handled in layout
          break;
        case AlignContent.spaceBetween:
          // Will be handled in layout
          break;
        case AlignContent.spaceAround:
          // Will be handled in layout
          break;
      }
    }
  }

  double _getSumOfCrossSize() {
    double sum = 0;
    for (int i = 0; i < _flexLines.length; i++) {
      sum += _flexLines[i].crossSize;
      if (i > 0) sum += _crossAxisSpacing;
    }
    return sum;
  }

  void _stretchViews() {
    for (final flexLine in _flexLines) {
      for (final index in flexLine.indicesAlignSelfStretch) {
        final child = _getReorderedChildAt(index);
        if (child == null) continue;

        final parentData = child.parentData! as FlexboxParentData;
        final flexItemData = parentData.flexItemData;

        if (_isMainAxisHorizontal) {
          var newHeight = flexLine.crossSize;
          if (flexItemData.minHeight != null) {
            newHeight = math.max(newHeight, flexItemData.minHeight!);
          }
          if (flexItemData.maxHeight != null) {
            newHeight = math.min(newHeight, flexItemData.maxHeight!);
          }

          child.layout(
            BoxConstraints(
              minWidth: child.size.width,
              maxWidth: child.size.width,
              minHeight: newHeight,
              maxHeight: newHeight,
            ),
            parentUsesSize: true,
          );
        } else {
          var newWidth = flexLine.crossSize;
          if (flexItemData.minWidth != null) {
            newWidth = math.max(newWidth, flexItemData.minWidth!);
          }
          if (flexItemData.maxWidth != null) {
            newWidth = math.min(newWidth, flexItemData.maxWidth!);
          }

          child.layout(
            BoxConstraints(
              minWidth: newWidth,
              maxWidth: newWidth,
              minHeight: child.size.height,
              maxHeight: child.size.height,
            ),
            parentUsesSize: true,
          );
        }

        parentData.measuredWidth = child.size.width;
        parentData.measuredHeight = child.size.height;
      }
    }
  }

  Size _calculateFinalSize(BoxConstraints constraints) {
    double width;
    double height;

    if (_isMainAxisHorizontal) {
      width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : _getLargestMainSize();
      height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : _getSumOfCrossSize();
    } else {
      width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : _getSumOfCrossSize();
      height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : _getLargestMainSize();
    }

    return constraints.constrain(Size(width, height));
  }

  void _layoutChildren(BoxConstraints constraints, Size computedSize) {
    if (_flexLines.isEmpty) return;

    final isRtl = _textDirection == TextDirection.rtl;

    switch (_flexDirection) {
      case FlexDirection.row:
        _layoutHorizontal(computedSize, isRtl: isRtl, isReverse: false);
        break;
      case FlexDirection.rowReverse:
        _layoutHorizontal(computedSize, isRtl: !isRtl, isReverse: true);
        break;
      case FlexDirection.column:
        _layoutVertical(computedSize, isRtl: isRtl, isReverse: false);
        break;
      case FlexDirection.columnReverse:
        _layoutVertical(computedSize, isRtl: isRtl, isReverse: true);
        break;
    }
  }

  void _layoutHorizontal(
    Size computedSize, {
    required bool isRtl,
    required bool isReverse,
  }) {
    final totalCrossSize = _getSumOfCrossSize();
    double crossOffset = _calculateCrossStartOffset(
      computedSize,
      totalCrossSize,
    );
    final crossSpacing = _calculateCrossSpacing(computedSize, totalCrossSize);

    for (int lineIndex = 0; lineIndex < _flexLines.length; lineIndex++) {
      final flexLine = _flexWrap == FlexWrap.wrapReverse
          ? _flexLines[_flexLines.length - 1 - lineIndex]
          : _flexLines[lineIndex];

      double mainOffset = _calculateMainStartOffset(computedSize, flexLine);
      final mainSpacing = _calculateMainSpacing(computedSize, flexLine);

      for (int j = 0; j < flexLine.itemCount; j++) {
        final index =
            isReverse ? flexLine.lastIndex - j : flexLine.firstIndex + j;

        final child = _getReorderedChildAt(index);
        if (child == null) continue;

        final parentData = child.parentData! as FlexboxParentData;
        final flexItemData = parentData.flexItemData;

        final alignItems = flexItemData.alignSelf.toAlignItems() ?? _alignItems;
        final childCrossOffset = _calculateChildCrossOffset(
          alignItems,
          flexLine,
          child,
        );

        double x;
        double y;

        if (isRtl) {
          x = computedSize.width - mainOffset - child.size.width;
        } else {
          x = mainOffset;
        }

        if (_flexWrap == FlexWrap.wrapReverse) {
          y = computedSize.height -
              crossOffset -
              flexLine.crossSize +
              childCrossOffset;
        } else {
          y = crossOffset + childCrossOffset;
        }

        parentData.offset = Offset(x, y);

        mainOffset += child.size.width + mainSpacing;
        if (j < flexLine.itemCount - 1) {
          mainOffset += _mainAxisSpacing;
        }
      }

      crossOffset += flexLine.crossSize + crossSpacing + _crossAxisSpacing;
    }
  }

  void _layoutVertical(
    Size computedSize, {
    required bool isRtl,
    required bool isReverse,
  }) {
    final totalCrossSize = _getSumOfCrossSize();
    double crossOffset = _calculateCrossStartOffset(
      computedSize,
      totalCrossSize,
    );
    final crossSpacing = _calculateCrossSpacing(computedSize, totalCrossSize);

    for (int lineIndex = 0; lineIndex < _flexLines.length; lineIndex++) {
      final flexLine = _flexWrap == FlexWrap.wrapReverse
          ? _flexLines[_flexLines.length - 1 - lineIndex]
          : _flexLines[lineIndex];

      double mainOffset = _calculateMainStartOffset(computedSize, flexLine);
      final mainSpacing = _calculateMainSpacing(computedSize, flexLine);

      for (int j = 0; j < flexLine.itemCount; j++) {
        final index =
            isReverse ? flexLine.lastIndex - j : flexLine.firstIndex + j;

        final child = _getReorderedChildAt(index);
        if (child == null) continue;

        final parentData = child.parentData! as FlexboxParentData;
        final flexItemData = parentData.flexItemData;

        final alignItems = flexItemData.alignSelf.toAlignItems() ?? _alignItems;
        final childCrossOffset = _calculateChildCrossOffset(
          alignItems,
          flexLine,
          child,
        );

        double x;
        double y;

        if (_flexWrap == FlexWrap.wrapReverse) {
          x = isRtl
              ? crossOffset + childCrossOffset
              : computedSize.width -
                  crossOffset -
                  flexLine.crossSize +
                  childCrossOffset;
        } else {
          x = isRtl
              ? computedSize.width -
                  crossOffset -
                  flexLine.crossSize +
                  childCrossOffset
              : crossOffset + childCrossOffset;
        }

        y = mainOffset;

        parentData.offset = Offset(x, y);

        mainOffset += child.size.height + mainSpacing;
        if (j < flexLine.itemCount - 1) {
          mainOffset += _mainAxisSpacing;
        }
      }

      crossOffset += flexLine.crossSize + crossSpacing + _crossAxisSpacing;
    }
  }

  double _calculateMainStartOffset(Size computedSize, FlexLine flexLine) {
    final mainSize =
        _isMainAxisHorizontal ? computedSize.width : computedSize.height;
    final freeSpace = mainSize - flexLine.mainSize;

    switch (_justifyContent) {
      case JustifyContent.flexStart:
        return 0;
      case JustifyContent.flexEnd:
        return freeSpace;
      case JustifyContent.center:
        return freeSpace / 2;
      case JustifyContent.spaceBetween:
        return 0;
      case JustifyContent.spaceAround:
        if (flexLine.itemCountNotGone == 0) return 0;
        return freeSpace / (flexLine.itemCountNotGone * 2);
      case JustifyContent.spaceEvenly:
        if (flexLine.itemCountNotGone == 0) return 0;
        return freeSpace / (flexLine.itemCountNotGone + 1);
    }
  }

  double _calculateMainSpacing(Size computedSize, FlexLine flexLine) {
    final mainSize =
        _isMainAxisHorizontal ? computedSize.width : computedSize.height;
    final freeSpace = mainSize - flexLine.mainSize;

    switch (_justifyContent) {
      case JustifyContent.flexStart:
      case JustifyContent.flexEnd:
      case JustifyContent.center:
        return 0;
      case JustifyContent.spaceBetween:
        if (flexLine.itemCountNotGone <= 1) return 0;
        return freeSpace / (flexLine.itemCountNotGone - 1);
      case JustifyContent.spaceAround:
        if (flexLine.itemCountNotGone == 0) return 0;
        return freeSpace / flexLine.itemCountNotGone;
      case JustifyContent.spaceEvenly:
        if (flexLine.itemCountNotGone == 0) return 0;
        return freeSpace / (flexLine.itemCountNotGone + 1);
    }
  }

  double _calculateCrossStartOffset(Size computedSize, double totalCrossSize) {
    final crossSize =
        _isMainAxisHorizontal ? computedSize.height : computedSize.width;
    final freeSpace = crossSize - totalCrossSize;

    switch (_alignContent) {
      case AlignContent.flexStart:
      case AlignContent.stretch:
        return 0;
      case AlignContent.flexEnd:
        return freeSpace;
      case AlignContent.center:
        return freeSpace / 2;
      case AlignContent.spaceBetween:
        return 0;
      case AlignContent.spaceAround:
        if (_flexLines.isEmpty) return 0;
        return freeSpace / (_flexLines.length * 2);
    }
  }

  double _calculateCrossSpacing(Size computedSize, double totalCrossSize) {
    final crossSize =
        _isMainAxisHorizontal ? computedSize.height : computedSize.width;
    final freeSpace = crossSize - totalCrossSize;

    switch (_alignContent) {
      case AlignContent.flexStart:
      case AlignContent.flexEnd:
      case AlignContent.center:
      case AlignContent.stretch:
        return 0;
      case AlignContent.spaceBetween:
        if (_flexLines.length <= 1) return 0;
        return freeSpace / (_flexLines.length - 1);
      case AlignContent.spaceAround:
        if (_flexLines.isEmpty) return 0;
        return freeSpace / _flexLines.length;
    }
  }

  double _calculateChildCrossOffset(
    AlignItems alignItems,
    FlexLine flexLine,
    RenderBox child,
  ) {
    final childCrossSize = _getChildCrossSize(child);

    switch (alignItems) {
      case AlignItems.flexStart:
        return 0;
      case AlignItems.flexEnd:
        return flexLine.crossSize - childCrossSize;
      case AlignItems.center:
        return (flexLine.crossSize - childCrossSize) / 2;
      case AlignItems.baseline:
        if (_isMainAxisHorizontal) {
          final baseline = child.getDistanceToBaseline(TextBaseline.alphabetic);
          if (baseline != null) {
            if (_flexWrap != FlexWrap.wrapReverse) {
              return flexLine.maxBaseline - baseline;
            } else {
              return flexLine.crossSize -
                  flexLine.maxBaseline -
                  (child.size.height - baseline);
            }
          }
        }
        return 0;
      case AlignItems.stretch:
        return 0;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

class _OrderedChild {
  _OrderedChild({
    required this.child,
    required this.order,
    required this.originalIndex,
  });
  final RenderBox child;
  final int order;
  final int originalIndex;
}
