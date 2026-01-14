import 'dart:math' as math;

import 'enums.dart';

/// Represents a single item in a flex line with calculated layout.
///
/// This class stores the final calculated position and size of a child
/// after flexbox layout computation. The flex calculation considers
/// flexGrow and flexShrink properties to determine the final extents.
///
/// See also:
/// * [SliverFlexboxLine], which contains a list of these items
/// * [SliverFlexboxDelegate], which performs the layout calculation
class FlexLineItem {
  /// Creates a flex line item.
  const FlexLineItem({
    required this.index,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
    required this.crossAxisOffset,
    required this.flexGrow,
    required this.flexShrink,
    required this.originalMainAxisExtent,
  });

  /// The index of this item.
  final int index;

  /// The final main axis extent after flex calculation.
  final double mainAxisExtent;

  /// The final cross axis extent after flex calculation.
  final double crossAxisExtent;

  /// The offset in the cross axis.
  final double crossAxisOffset;

  /// The flex grow factor.
  final double flexGrow;

  /// The flex shrink factor.
  final double flexShrink;

  /// The original main axis extent before flex calculation.
  final double originalMainAxisExtent;

  /// Creates a copy with modified values.
  FlexLineItem copyWith({
    int? index,
    double? mainAxisExtent,
    double? crossAxisExtent,
    double? crossAxisOffset,
    double? flexGrow,
    double? flexShrink,
    double? originalMainAxisExtent,
  }) {
    return FlexLineItem(
      index: index ?? this.index,
      mainAxisExtent: mainAxisExtent ?? this.mainAxisExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      crossAxisOffset: crossAxisOffset ?? this.crossAxisOffset,
      flexGrow: flexGrow ?? this.flexGrow,
      flexShrink: flexShrink ?? this.flexShrink,
      originalMainAxisExtent:
          originalMainAxisExtent ?? this.originalMainAxisExtent,
    );
  }
}

/// Represents a single line (row or column) in a sliver flexbox layout.
///
/// A flex line contains one or more children arranged along the cross axis.
/// Each line tracks the children's positions, sizes, and flex properties
/// for proper rendering within a [SliverFlexbox].
///
/// ## Example
///
/// In a horizontal flexbox with wrap enabled, each row is a flex line:
/// ```dart
/// SliverFlexboxLine(
///   firstIndex: 0,
///   lastIndex: 2,
///   mainAxisExtent: 100.0,  // Height of this row
///   crossAxisExtent: 300.0, // Width of this row
///   itemCount: 3,
///   items: [/* ... */],
/// )
/// ```
///
/// See also:
/// * [FlexLineItem], which represents individual children in the line
/// * [SliverFlexboxLayout], which contains a list of flex lines
class SliverFlexboxLine {
  /// Creates a sliver flexbox line.
  const SliverFlexboxLine({
    required this.firstIndex,
    required this.lastIndex,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
    required this.itemCount,
    required this.items,
    this.totalFlexGrow = 0.0,
    this.totalFlexShrink = 0.0,
  });

  /// The first child index in this line.
  final int firstIndex;

  /// The last child index in this line.
  final int lastIndex;

  /// The extent of this line in the main axis (the scroll direction).
  final double mainAxisExtent;

  /// The extent of this line in the cross axis.
  final double crossAxisExtent;

  /// The number of items in this line.
  final int itemCount;

  /// The items in this line with their calculated positions.
  final List<FlexLineItem> items;

  /// The total flex grow of all items in this line.
  final double totalFlexGrow;

  /// The total flex shrink of all items in this line.
  final double totalFlexShrink;
}

/// The geometry (position and size) for a child in a sliver flexbox layout.
///
/// This class represents the calculated layout information for a single child
/// within a [SliverFlexbox], including its scroll offset, cross-axis offset,
/// and dimensions along both axes.
///
/// This is typically used internally by [RenderSliverFlexbox] during layout.
///
/// See also:
/// * [SliverFlexboxLayout.getChildGeometry], which returns this for each child
/// * [SliverFlexboxParentData], which stores this during layout
class SliverFlexboxChildGeometry {
  /// Creates a child geometry.
  const SliverFlexboxChildGeometry({
    required this.scrollOffset,
    required this.crossAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisExtent,
  });

  /// The scroll offset of the child.
  final double scrollOffset;

  /// The cross axis offset of the child.
  final double crossAxisOffset;

  /// The main axis extent of the child.
  final double mainAxisExtent;

  /// The cross axis extent of the child.
  final double crossAxisExtent;

  /// The scroll offset of the trailing edge of the child.
  double get trailingScrollOffset => scrollOffset + mainAxisExtent;
}

/// The complete layout result for a sliver flexbox.
///
/// This class contains all the information needed to render a flexbox layout,
/// including the calculated flex lines, total scroll extent, and spacing values.
///
/// It provides methods to query the layout:
/// * [scrollExtent] - Total height/width of the content
/// * [getLineIndexForScrollOffset] - Find which line is at a given offset
/// * [getChildGeometry] - Get the position/size of a specific child
///
/// ## Example
///
/// ```dart
/// final layout = delegate.getLayout(constraints, childCount: 10);
/// print('Total scroll extent: ${layout.scrollExtent}');
///
/// final geometry = layout.getChildGeometry(5);
/// print('Child 5 offset: ${geometry.scrollOffset}');
/// ```
///
/// See also:
/// * [SliverFlexboxDelegate.getLayout], which returns this
/// * [SliverFlexboxLine], which represents individual lines in the layout
class SliverFlexboxLayout {
  /// Creates a sliver flexbox layout.
  const SliverFlexboxLayout({
    required this.lines,
    required this.crossAxisExtent,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
  });

  /// The flex lines.
  final List<SliverFlexboxLine> lines;

  /// The cross axis extent.
  final double crossAxisExtent;

  /// The spacing between items in the main axis.
  final double mainAxisSpacing;

  /// The spacing between lines in the cross axis.
  final double crossAxisSpacing;

  /// Returns the total scroll extent.
  double get scrollExtent {
    if (lines.isEmpty) return 0;
    double extent = 0;
    for (int i = 0; i < lines.length; i++) {
      extent += lines[i].mainAxisExtent;
      if (i < lines.length - 1) {
        extent += mainAxisSpacing;
      }
    }
    return extent;
  }

  /// Returns the line index for the given scroll offset.
  int getLineIndexForScrollOffset(double scrollOffset) {
    double offset = 0;
    for (int i = 0; i < lines.length; i++) {
      final lineExtent = lines[i].mainAxisExtent + mainAxisSpacing;
      if (offset + lineExtent > scrollOffset) {
        return i;
      }
      offset += lineExtent;
    }
    return lines.isEmpty ? 0 : lines.length - 1;
  }

  /// Returns the scroll offset for the given line index.
  double getScrollOffsetForLineIndex(int lineIndex) {
    double offset = 0;
    for (int i = 0; i < lineIndex && i < lines.length; i++) {
      offset += lines[i].mainAxisExtent + mainAxisSpacing;
    }
    return offset;
  }

  /// Returns the first child index visible at the given scroll offset.
  int getFirstChildIndexForScrollOffset(double scrollOffset) {
    final lineIndex = getLineIndexForScrollOffset(scrollOffset);
    if (lineIndex < 0 || lineIndex >= lines.length) {
      return 0;
    }
    return lines[lineIndex].firstIndex;
  }

  /// Returns the last child index visible at the given scroll offset.
  int getLastChildIndexForScrollOffset(double scrollOffset) {
    double offset = 0;
    for (int i = 0; i < lines.length; i++) {
      final lineEnd = offset + lines[i].mainAxisExtent;
      if (lineEnd >= scrollOffset) {
        return lines[i].lastIndex;
      }
      offset = lineEnd + mainAxisSpacing;
    }
    if (lines.isNotEmpty) {
      return lines.last.lastIndex;
    }
    return 0;
  }

  /// Returns the geometry for a child at the given index.
  SliverFlexboxChildGeometry getChildGeometry(int index) {
    for (final line in lines) {
      if (index >= line.firstIndex && index <= line.lastIndex) {
        final lineOffset = getScrollOffsetForLineIndex(lines.indexOf(line));
        for (final item in line.items) {
          if (item.index == index) {
            return SliverFlexboxChildGeometry(
              scrollOffset: lineOffset,
              crossAxisOffset: item.crossAxisOffset,
              mainAxisExtent: line.mainAxisExtent,
              crossAxisExtent: item.mainAxisExtent,
            );
          }
        }
      }
    }

    // Return a default geometry if not found
    return const SliverFlexboxChildGeometry(
      scrollOffset: 0,
      crossAxisOffset: 0,
      mainAxisExtent: 0,
      crossAxisExtent: 0,
    );
  }
}

/// Information about a child element for flexbox layout calculation.
///
/// This class encapsulates the properties needed to calculate a child's
/// layout in a dynamic flexbox where items may have different aspect ratios.
///
/// ## Example
///
/// ```dart
/// FlexChildInfo(
///   index: 0,
///   aspectRatio: 16 / 9,  // Width / height
///   flexGrow: 1.0,
///   flexShrink: 1.0,
/// )
/// ```
///
/// See also:
/// * [FlexboxLayoutCalculator], which uses this for layout calculation
/// * [SliverFlexboxDelegateWithAspectRatios], which creates these from aspect ratios
class FlexChildInfo {
  /// Creates a flex child info.
  const FlexChildInfo({
    required this.index,
    required this.aspectRatio,
    this.flexGrow = 1.0,
    this.flexShrink = 1.0,
    this.minMainAxisExtent,
    this.maxMainAxisExtent,
  });

  /// The index of this child.
  final int index;

  /// The aspect ratio (width / height) of this child.
  final double aspectRatio;

  /// The flex grow factor.
  final double flexGrow;

  /// The flex shrink factor.
  final double flexShrink;

  /// The minimum main axis extent.
  final double? minMainAxisExtent;

  /// The maximum main axis extent.
  final double? maxMainAxisExtent;
}

/// Calculator for flexbox layout with items that have intrinsic aspect ratios.
///
/// This calculator implements a flexbox layout algorithm adapted for items
/// with different aspect ratios (like photos in a gallery). It arranges
/// items into rows, scaling them to efficiently fill the available space
/// while maintaining their aspect ratios.
///
/// ## How It Works
///
/// 1. Items are grouped into rows based on their aspect ratios
/// 2. Each row is scaled to fill the available width
/// 3. Items are distributed using their flex grow/shrink values
///
/// ## Example
///
/// ```dart
/// final calculator = FlexboxLayoutCalculator(
///   targetRowHeight: 200,
///   mainAxisSpacing: 4,
///   crossAxisSpacing: 4,
/// );
///
/// final childInfos = [
///   FlexChildInfo(index: 0, aspectRatio: 16/9),
///   FlexChildInfo(index: 1, aspectRatio: 4/3),
/// ];
///
/// final layout = calculator.calculateLayout(
///   crossAxisExtent: 400,
///   childInfos: childInfos,
/// );
/// ```
///
/// See also:
/// * [SliverFlexboxDelegateWithAspectRatios], which uses this calculator
/// * [SliverFlexboxDelegateWithDynamicAspectRatios], for dynamic aspect ratios
class FlexboxLayoutCalculator {
  /// Creates a flexbox layout calculator.
  const FlexboxLayoutCalculator({
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.targetRowHeight = 200.0,
  });

  /// The direction in which flex items are placed.
  final FlexDirection flexDirection;

  /// How flex items wrap.
  final FlexWrap flexWrap;

  /// How flex items are aligned along the main axis.
  final JustifyContent justifyContent;

  /// How flex items are aligned along the cross axis.
  final AlignItems alignItems;

  /// How flex lines are aligned in the cross axis.
  final AlignContent alignContent;

  /// The spacing between flex items along the main axis.
  final double mainAxisSpacing;

  /// The spacing between flex lines along the cross axis.
  final double crossAxisSpacing;

  /// The target row height for layout calculation.
  final double targetRowHeight;

  /// Whether the main axis is horizontal.
  bool get isMainAxisHorizontal => flexDirection.isHorizontal;

  /// Calculates the flexbox layout for the given parameters.
  ///
  /// The [crossAxisExtent] is the available space in the cross axis
  /// (the width for vertical scrolling, height for horizontal).
  ///
  /// The [childInfos] contains information about each child including
  /// its aspect ratio and flex properties.
  SliverFlexboxLayout calculateLayout({
    required double crossAxisExtent,
    required List<FlexChildInfo> childInfos,
  }) {
    if (childInfos.isEmpty) {
      return SliverFlexboxLayout(
        lines: const [],
        crossAxisExtent: crossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      );
    }

    final lines = <SliverFlexboxLine>[];
    final availableCrossExtent = crossAxisExtent;

    int currentLineStart = 0;
    double currentLineMainExtent = 0.0;
    List<_PendingItem> pendingItems = [];

    for (int i = 0; i < childInfos.length; i++) {
      final info = childInfos[i];
      // Calculate the width this item would take at the target row height
      final itemWidth = targetRowHeight * info.aspectRatio;

      // Check if adding this item would exceed the available width
      final spacingNeeded = pendingItems.isEmpty ? 0.0 : crossAxisSpacing;
      final projectedWidth = currentLineMainExtent + spacingNeeded + itemWidth;

      if (pendingItems.isNotEmpty && projectedWidth > availableCrossExtent) {
        // Create a line with the current pending items
        final line = _createFlexLine(
          pendingItems: pendingItems,
          lineStart: currentLineStart,
          availableCrossExtent: availableCrossExtent,
        );
        lines.add(line);

        // Start a new line
        currentLineStart = i;
        currentLineMainExtent = itemWidth;
        pendingItems = [_PendingItem(info: info, baseWidth: itemWidth)];
      } else {
        // Add to current line
        currentLineMainExtent = projectedWidth;
        pendingItems.add(_PendingItem(info: info, baseWidth: itemWidth));
      }
    }

    // Handle the last line
    if (pendingItems.isNotEmpty) {
      final line = _createFlexLine(
        pendingItems: pendingItems,
        lineStart: currentLineStart,
        availableCrossExtent: availableCrossExtent,
        isLastLine: true,
      );
      lines.add(line);
    }

    return SliverFlexboxLayout(
      lines: lines,
      crossAxisExtent: crossAxisExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  SliverFlexboxLine _createFlexLine({
    required List<_PendingItem> pendingItems,
    required int lineStart,
    required double availableCrossExtent,
    bool isLastLine = false,
  }) {
    final itemCount = pendingItems.length;
    final totalSpacing = crossAxisSpacing * (itemCount - 1);
    final availableForItems = availableCrossExtent - totalSpacing;

    // Calculate total base width and total flex grow
    double totalBaseWidth = 0.0;
    double totalFlexGrow = 0.0;
    double totalFlexShrink = 0.0;

    for (final item in pendingItems) {
      totalBaseWidth += item.baseWidth;
      totalFlexGrow += item.info.flexGrow;
      totalFlexShrink += item.info.flexShrink;
    }

    // Calculate the scale factor to fit the row
    // For the last line, we might not want to stretch the items to fill the row
    double scaleFactor;
    if (isLastLine && justifyContent == JustifyContent.flexStart) {
      // Don't scale up the last line if using flex-start
      scaleFactor = math.min(1.0, availableForItems / totalBaseWidth);
    } else {
      // Scale to fit the available space
      scaleFactor = availableForItems / totalBaseWidth;
    }

    // Calculate the actual row height
    final rowHeight = targetRowHeight * scaleFactor;

    // Calculate each item's position
    final items = <FlexLineItem>[];
    double crossAxisOffset = 0.0;

    for (int i = 0; i < pendingItems.length; i++) {
      final pending = pendingItems[i];
      final itemWidth = pending.baseWidth * scaleFactor;

      items.add(
        FlexLineItem(
          index: lineStart + i,
          mainAxisExtent: itemWidth,
          crossAxisExtent: rowHeight,
          crossAxisOffset: crossAxisOffset,
          flexGrow: pending.info.flexGrow,
          flexShrink: pending.info.flexShrink,
          originalMainAxisExtent: pending.baseWidth,
        ),
      );

      crossAxisOffset += itemWidth;
      if (i < pendingItems.length - 1) {
        crossAxisOffset += crossAxisSpacing;
      }
    }

    return SliverFlexboxLine(
      firstIndex: lineStart,
      lastIndex: lineStart + itemCount - 1,
      mainAxisExtent: rowHeight,
      crossAxisExtent: crossAxisOffset,
      itemCount: itemCount,
      items: items,
      totalFlexGrow: totalFlexGrow,
      totalFlexShrink: totalFlexShrink,
    );
  }
}

class _PendingItem {
  const _PendingItem({required this.info, required this.baseWidth});

  final FlexChildInfo info;
  final double baseWidth;
}
