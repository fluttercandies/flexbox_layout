import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';

import 'enums.dart';
import 'flex_item_data.dart';
import 'sliver_flexbox_layout.dart';

export 'sliver_flexbox_layout.dart';

/// Signature for a callback that provides the aspect ratio for a child at
/// the given index.
///
/// Return null if the aspect ratio is not known yet (e.g., image not loaded).
typedef FlexChildAspectRatioProvider = double? Function(int index);

/// Signature for a callback that provides flex item data for a child at
/// the given index.
typedef FlexChildDataProvider = FlexItemData Function(int index);

int _limitChildCountByMaxLines({
  required int childCount,
  required int itemsPerLine,
  required int? maxLines,
}) {
  if (maxLines == null) return childCount;
  if (maxLines <= 0) return 0;
  return math.min(childCount, itemsPerLine * maxLines);
}

/// A delegate that controls the layout of children in a sliver flexbox.
abstract class SliverFlexboxDelegate {
  /// Creates a sliver flexbox delegate.
  const SliverFlexboxDelegate();

  /// The direction in which flex items are placed.
  FlexDirection get flexDirection;

  /// How flex items wrap.
  FlexWrap get flexWrap;

  /// How flex items are aligned along the main axis.
  JustifyContent get justifyContent;

  /// How flex items are aligned along the cross axis.
  AlignItems get alignItems;

  /// How flex lines are aligned in the cross axis.
  AlignContent get alignContent;

  /// The spacing between flex items along the main axis.
  double get mainAxisSpacing;

  /// The spacing between flex lines along the cross axis.
  double get crossAxisSpacing;

  /// The maximum number of flex lines.
  int? get maxLines;

  /// Whether the main axis is horizontal.
  bool get isMainAxisHorizontal => flexDirection.isHorizontal;

  /// Returns the flex item data for a child at the given index.
  FlexItemData getFlexItemData(int index);

  /// Whether layout results can be cached across scroll-only relayouts.
  ///
  /// Delegates that depend on callbacks with volatile external state should
  /// override this and return `false`.
  bool get shouldCacheLayout => true;

  /// Whether a new delegate instance should trigger relayout.
  ///
  /// This is used to skip unnecessary full relayout when a parent rebuilds
  /// with an equivalent delegate configuration.
  bool shouldRelayout(covariant SliverFlexboxDelegate oldDelegate) => true;

  /// Calculates the layout for the given constraints.
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  });
}

/// A delegate with a fixed cross axis count (grid-like layout).
class SliverFlexboxDelegateWithFixedCrossAxisCount
    extends SliverFlexboxDelegate {
  /// Creates a delegate with a fixed cross axis count.
  const SliverFlexboxDelegateWithFixedCrossAxisCount({
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.childAspectRatio = 1.0,
    required this.crossAxisCount,
  }) : assert(crossAxisCount > 0);

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  /// The number of children in the cross axis.
  final int crossAxisCount;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  @override
  bool shouldRelayout(
    covariant SliverFlexboxDelegateWithFixedCrossAxisCount oldDelegate,
  ) {
    return oldDelegate.flexDirection != flexDirection ||
        oldDelegate.flexWrap != flexWrap ||
        oldDelegate.justifyContent != justifyContent ||
        oldDelegate.alignItems != alignItems ||
        oldDelegate.alignContent != alignContent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.childAspectRatio != childAspectRatio ||
        oldDelegate.crossAxisCount != crossAxisCount;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    return const FlexItemData(flexGrow: 1.0, flexShrink: 1.0);
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final crossAxisExtent = constraints.crossAxisExtent;
    final effectiveChildCount = _limitChildCountByMaxLines(
      childCount: childCount,
      itemsPerLine: crossAxisCount,
      maxLines: maxLines,
    );
    if (effectiveChildCount == 0) {
      return SliverFlexboxLayout(
        lines: const [],
        crossAxisExtent: crossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      );
    }

    final usableCrossAxisExtent = math.max(
      0.0,
      crossAxisExtent - (crossAxisSpacing * (crossAxisCount - 1)),
    );
    final childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final childMainAxisExtent = childCrossAxisExtent / childAspectRatio;

    final lines = <SliverFlexboxLine>[];
    final stride = childCrossAxisExtent + crossAxisSpacing;
    for (int lineStart = 0;
        lineStart < effectiveChildCount;
        lineStart += crossAxisCount) {
      final itemCount =
          math.min(crossAxisCount, effectiveChildCount - lineStart);
      final items = List<FlexLineItem>.generate(
        itemCount,
        (j) => FlexLineItem(
          index: lineStart + j,
          mainAxisExtent: childCrossAxisExtent,
          crossAxisExtent: childMainAxisExtent,
          crossAxisOffset: j * stride,
          flexGrow: 1.0,
          flexShrink: 1.0,
          originalMainAxisExtent: childCrossAxisExtent,
        ),
        growable: false,
      );
      lines.add(
        SliverFlexboxLine(
          firstIndex: lineStart,
          lastIndex: lineStart + itemCount - 1,
          mainAxisExtent: childMainAxisExtent,
          crossAxisExtent: childCrossAxisExtent * itemCount +
              crossAxisSpacing * (itemCount - 1),
          itemCount: itemCount,
          items: items,
        ),
      );
    }

    return SliverFlexboxLayout(
      lines: lines,
      crossAxisExtent: crossAxisExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }
}

/// A delegate that allows for maximum cross axis extent.
class SliverFlexboxDelegateWithMaxCrossAxisExtent
    extends SliverFlexboxDelegate {
  /// Creates a delegate with a maximum cross axis extent.
  const SliverFlexboxDelegateWithMaxCrossAxisExtent({
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.childAspectRatio = 1.0,
    required this.maxCrossAxisExtent,
  }) : assert(maxCrossAxisExtent > 0);

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  /// The maximum extent of children in the cross axis.
  final double maxCrossAxisExtent;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  @override
  bool shouldRelayout(
    covariant SliverFlexboxDelegateWithMaxCrossAxisExtent oldDelegate,
  ) {
    return oldDelegate.flexDirection != flexDirection ||
        oldDelegate.flexWrap != flexWrap ||
        oldDelegate.justifyContent != justifyContent ||
        oldDelegate.alignItems != alignItems ||
        oldDelegate.alignContent != alignContent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.childAspectRatio != childAspectRatio ||
        oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    return const FlexItemData(flexGrow: 1.0, flexShrink: 1.0);
  }

  int _getCrossAxisCount(double crossAxisExtent) {
    if (!crossAxisExtent.isFinite || crossAxisExtent <= 0) {
      return 1;
    }
    final denominator = maxCrossAxisExtent + crossAxisSpacing;
    if (denominator <= 0) {
      return 1;
    }
    return math.max(1, (crossAxisExtent / denominator).ceil());
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final crossAxisExtent = constraints.crossAxisExtent;
    final crossAxisCount = _getCrossAxisCount(crossAxisExtent);
    final effectiveChildCount = _limitChildCountByMaxLines(
      childCount: childCount,
      itemsPerLine: crossAxisCount,
      maxLines: maxLines,
    );
    if (effectiveChildCount == 0) {
      return SliverFlexboxLayout(
        lines: const [],
        crossAxisExtent: crossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      );
    }

    final usableCrossAxisExtent = math.max(
      0.0,
      crossAxisExtent - (crossAxisSpacing * (crossAxisCount - 1)),
    );
    final childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final childMainAxisExtent = childCrossAxisExtent / childAspectRatio;

    final lines = <SliverFlexboxLine>[];
    final stride = childCrossAxisExtent + crossAxisSpacing;
    for (int lineStart = 0;
        lineStart < effectiveChildCount;
        lineStart += crossAxisCount) {
      final itemCount =
          math.min(crossAxisCount, effectiveChildCount - lineStart);
      final items = List<FlexLineItem>.generate(
        itemCount,
        (j) => FlexLineItem(
          index: lineStart + j,
          mainAxisExtent: childCrossAxisExtent,
          crossAxisExtent: childMainAxisExtent,
          crossAxisOffset: j * stride,
          flexGrow: 1.0,
          flexShrink: 1.0,
          originalMainAxisExtent: childCrossAxisExtent,
        ),
        growable: false,
      );
      lines.add(
        SliverFlexboxLine(
          firstIndex: lineStart,
          lastIndex: lineStart + itemCount - 1,
          mainAxisExtent: childMainAxisExtent,
          crossAxisExtent: childCrossAxisExtent * itemCount +
              crossAxisSpacing * (itemCount - 1),
          itemCount: itemCount,
          items: items,
        ),
      );
    }

    return SliverFlexboxLayout(
      lines: lines,
      crossAxisExtent: crossAxisExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }
}

/// A delegate that supports items with different aspect ratios.
///
/// This delegate creates a true flexbox layout where items can have different
/// sizes based on their intrinsic aspect ratios, and flexGrow is used to
/// distribute remaining space in each row.
///
/// This is ideal for photo galleries like Google Photos where images have
/// varying dimensions and are laid out to fill each row efficiently.
///
/// Example:
/// ```dart
/// SliverFlexboxDelegateWithAspectRatios(
///   aspectRatios: images.map((img) => img.width / img.height).toList(),
///   targetRowHeight: 200,
///   crossAxisSpacing: 4,
///   mainAxisSpacing: 4,
/// )
/// ```
class SliverFlexboxDelegateWithAspectRatios extends SliverFlexboxDelegate {
  /// Creates a delegate with aspect ratios for each item.
  SliverFlexboxDelegateWithAspectRatios({
    required this.aspectRatios,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.targetRowHeight = 200.0,
    this.flexGrowValues,
    this.flexShrinkValues,
  });

  /// The aspect ratio (width / height) for each child.
  final List<double> aspectRatios;

  /// The target row height for layout calculation.
  /// Items will be scaled to approximately this height while filling rows.
  final double targetRowHeight;

  /// Optional flex grow values for each child.
  /// If null, all children have flexGrow of 1.0.
  final List<double>? flexGrowValues;

  /// Optional flex shrink values for each child.
  /// If null, all children have flexShrink of 1.0.
  final List<double>? flexShrinkValues;

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  @override
  bool shouldRelayout(
    covariant SliverFlexboxDelegateWithAspectRatios oldDelegate,
  ) {
    final aspectRatiosChanged =
        !listEquals(oldDelegate.aspectRatios, aspectRatios);
    final flexGrowValuesChanged =
        !listEquals(oldDelegate.flexGrowValues, flexGrowValues);
    final flexShrinkValuesChanged =
        !listEquals(oldDelegate.flexShrinkValues, flexShrinkValues);

    return oldDelegate.flexDirection != flexDirection ||
        oldDelegate.flexWrap != flexWrap ||
        oldDelegate.justifyContent != justifyContent ||
        oldDelegate.alignItems != alignItems ||
        oldDelegate.alignContent != alignContent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.targetRowHeight != targetRowHeight ||
        aspectRatiosChanged ||
        flexGrowValuesChanged ||
        flexShrinkValuesChanged;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    return FlexItemData(
      flexGrow: flexGrowValues != null && index < flexGrowValues!.length
          ? flexGrowValues![index]
          : 1.0,
      flexShrink: flexShrinkValues != null && index < flexShrinkValues!.length
          ? flexShrinkValues![index]
          : 1.0,
    );
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final calculator = FlexboxLayoutCalculator(
      flexDirection: flexDirection,
      flexWrap: flexWrap,
      justifyContent: justifyContent,
      alignItems: alignItems,
      alignContent: alignContent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      targetRowHeight: targetRowHeight,
      maxLines: maxLines,
    );

    final actualChildCount = math.min(childCount, aspectRatios.length);
    final childInfos = <FlexChildInfo>[];
    for (int i = 0; i < actualChildCount; i++) {
      childInfos.add(
        FlexChildInfo(
          index: i,
          aspectRatio: aspectRatios[i],
          flexGrow: flexGrowValues != null && i < flexGrowValues!.length
              ? flexGrowValues![i]
              : 1.0,
          flexShrink: flexShrinkValues != null && i < flexShrinkValues!.length
              ? flexShrinkValues![i]
              : 1.0,
        ),
      );
    }

    return calculator.calculateLayout(
      crossAxisExtent: constraints.crossAxisExtent,
      childInfos: childInfos,
    );
  }
}

/// A delegate that supports dynamic aspect ratios through a callback.
///
/// This delegate is useful when aspect ratios may change dynamically,
/// such as when loading images from the network where the dimensions
/// are not known until the image is loaded.
///
/// When an aspect ratio is not yet known (callback returns null),
/// a [defaultAspectRatio] is used as a placeholder.
///
/// Example:
/// ```dart
/// SliverFlexboxDelegateWithDynamicAspectRatios(
///   childCount: images.length,
///   aspectRatioProvider: (index) => loadedImages[index]?.aspectRatio,
///   defaultAspectRatio: 1.0,
///   targetRowHeight: 200,
/// )
/// ```
class SliverFlexboxDelegateWithDynamicAspectRatios
    extends SliverFlexboxDelegate {
  /// Creates a delegate with dynamic aspect ratios.
  SliverFlexboxDelegateWithDynamicAspectRatios({
    required this.childCount,
    required this.aspectRatioProvider,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.targetRowHeight = 200.0,
    this.defaultAspectRatio = 1.0,
    this.flexDataProvider,
  });

  /// The total number of children.
  final int childCount;

  /// Callback to get the aspect ratio for a child at the given index.
  /// Returns null if the aspect ratio is not known yet.
  final FlexChildAspectRatioProvider aspectRatioProvider;

  /// The default aspect ratio to use when the actual ratio is not known.
  final double defaultAspectRatio;

  /// The target row height for layout calculation.
  final double targetRowHeight;

  /// Optional callback to get flex item data for each child.
  final FlexChildDataProvider? flexDataProvider;

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  @override
  bool shouldRelayout(
    covariant SliverFlexboxDelegateWithDynamicAspectRatios oldDelegate,
  ) {
    // Callback results are data-dependent and can change without reference changes.
    return true;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    if (flexDataProvider != null) {
      return flexDataProvider!(index);
    }
    return const FlexItemData(flexGrow: 1.0, flexShrink: 1.0);
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final calculator = FlexboxLayoutCalculator(
      flexDirection: flexDirection,
      flexWrap: flexWrap,
      justifyContent: justifyContent,
      alignItems: alignItems,
      alignContent: alignContent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      targetRowHeight: targetRowHeight,
      maxLines: maxLines,
    );

    final actualChildCount = math.min(childCount, this.childCount);
    final childInfos = <FlexChildInfo>[];
    for (int i = 0; i < actualChildCount; i++) {
      final aspectRatio = aspectRatioProvider(i) ?? defaultAspectRatio;
      final flexData = getFlexItemData(i);
      childInfos.add(
        FlexChildInfo(
          index: i,
          aspectRatio: aspectRatio,
          flexGrow: flexData.flexGrow,
          flexShrink: flexData.flexShrink,
        ),
      );
    }

    return calculator.calculateLayout(
      crossAxisExtent: constraints.crossAxisExtent,
      childInfos: childInfos,
    );
  }
}

/// A delegate that creates a simple flex row layout.
///
/// This is useful for creating a single row of flex items that are
/// distributed according to their flex grow/shrink values.
class SliverFlexboxDelegateWithFlexValues extends SliverFlexboxDelegate {
  /// Creates a delegate with flex values.
  SliverFlexboxDelegateWithFlexValues({
    required this.flexValues,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.noWrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.rowHeight = 200.0,
  });

  /// The flex grow values for each child.
  /// The flex shrink is set to 0 by default.
  final List<double> flexValues;

  /// The fixed height for each row.
  final double rowHeight;

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  @override
  bool shouldRelayout(
    covariant SliverFlexboxDelegateWithFlexValues oldDelegate,
  ) {
    final flexValuesChanged = !listEquals(oldDelegate.flexValues, flexValues);

    return oldDelegate.flexDirection != flexDirection ||
        oldDelegate.flexWrap != flexWrap ||
        oldDelegate.justifyContent != justifyContent ||
        oldDelegate.alignItems != alignItems ||
        oldDelegate.alignContent != alignContent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.rowHeight != rowHeight ||
        flexValuesChanged;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    final flexGrow = index < flexValues.length ? flexValues[index] : 1.0;
    return FlexItemData(flexGrow: flexGrow, flexShrink: 0.0);
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final crossAxisExtent = constraints.crossAxisExtent;
    final actualChildCount = math.min(childCount, flexValues.length);

    if (actualChildCount == 0 || (maxLines != null && maxLines! <= 0)) {
      return SliverFlexboxLayout(
        lines: const [],
        crossAxisExtent: crossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      );
    }

    // Calculate total flex and spacing
    double totalFlex = 0;
    for (int i = 0; i < actualChildCount; i++) {
      totalFlex += flexValues[i];
    }

    final totalSpacing = crossAxisSpacing * (actualChildCount - 1);
    final availableWidth = crossAxisExtent - totalSpacing;
    final widthPerFlex = totalFlex > 0 ? availableWidth / totalFlex : 0.0;

    // Create items
    final items = <FlexLineItem>[];
    double crossAxisOffset = 0;
    for (int i = 0; i < actualChildCount; i++) {
      final flex = flexValues[i];
      final itemWidth = widthPerFlex * flex;
      items.add(
        FlexLineItem(
          index: i,
          mainAxisExtent: itemWidth,
          crossAxisExtent: rowHeight,
          crossAxisOffset: crossAxisOffset,
          flexGrow: flex,
          flexShrink: 0.0,
          originalMainAxisExtent: itemWidth,
        ),
      );
      crossAxisOffset += itemWidth + crossAxisSpacing;
    }

    return SliverFlexboxLayout(
      lines: [
        SliverFlexboxLine(
          firstIndex: 0,
          lastIndex: actualChildCount - 1,
          mainAxisExtent: rowHeight,
          crossAxisExtent: crossAxisExtent,
          itemCount: actualChildCount,
          items: items,
          totalFlexGrow: totalFlex,
        ),
      ],
      crossAxisExtent: crossAxisExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }
}

/// Signature for a callback that provides child info for layout calculation.
typedef FlexChildInfoProvider = FlexChildInfo Function(int index);

/// A highly customizable delegate that uses a builder callback to determine
/// child properties.
///
/// This is useful when you need full control over how each child's flex
/// properties are determined, without having to create a custom delegate class.
///
/// Example:
/// ```dart
/// SliverFlexboxDelegateWithBuilder(
///   childCount: items.length,
///   childInfoBuilder: (index) => FlexChildInfo(
///     index: index,
///     aspectRatio: items[index].aspectRatio,
///     flexGrow: items[index].priority.toDouble(),
///   ),
///   targetRowHeight: 200,
/// )
/// ```
class SliverFlexboxDelegateWithBuilder extends SliverFlexboxDelegate {
  /// Creates a delegate with a builder callback.
  SliverFlexboxDelegateWithBuilder({
    required this.childCount,
    required this.childInfoBuilder,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.targetRowHeight = 200.0,
  });

  /// The total number of children.
  final int childCount;

  /// Builder callback to create child info for each index.
  final FlexChildInfoProvider childInfoBuilder;

  /// The target row height for layout calculation.
  final double targetRowHeight;

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  @override
  bool shouldRelayout(covariant SliverFlexboxDelegateWithBuilder oldDelegate) {
    // Builder output can change based on external state even with same callback.
    return true;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    final info = childInfoBuilder(index);
    return FlexItemData(flexGrow: info.flexGrow, flexShrink: info.flexShrink);
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final calculator = FlexboxLayoutCalculator(
      flexDirection: flexDirection,
      flexWrap: flexWrap,
      justifyContent: justifyContent,
      alignItems: alignItems,
      alignContent: alignContent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      targetRowHeight: targetRowHeight,
      maxLines: maxLines,
    );

    final actualChildCount = math.min(childCount, this.childCount);
    final childInfos = <FlexChildInfo>[];
    for (int i = 0; i < actualChildCount; i++) {
      childInfos.add(childInfoBuilder(i));
    }

    return calculator.calculateLayout(
      crossAxisExtent: constraints.crossAxisExtent,
      childInfos: childInfos,
    );
  }
}

/// A delegate that provides continuous scaling with smooth visual transitions.
///
/// Unlike other delegates that may have discrete "jumps" when the number of
/// columns changes, this delegate ensures smooth continuous scaling by:
/// 1. Using a target extent as the basis for item sizing
/// 2. Supporting smooth transition from unfilled to filled rows via [fillFactor]
///
/// This creates a Google Photos-like pinch-to-zoom experience where the
/// visual feedback is immediate and follows the gesture precisely.
///
/// Example:
/// ```dart
/// SliverFlexboxDelegateWithDirectExtent(
///   aspectRatios: images.map((img) => img.width / img.height).toList(),
///   targetExtent: controller.currentExtent,
///   fillFactor: controller.fillFactor, // 0.0 during scaling, animates to 1.0 after
///   mainAxisSpacing: 2,
///   crossAxisSpacing: 2,
/// )
/// ```
class SliverFlexboxDelegateWithDirectExtent extends SliverFlexboxDelegate {
  /// Creates a delegate with direct extent control.
  const SliverFlexboxDelegateWithDirectExtent({
    required this.aspectRatios,
    required this.targetExtent,
    this.fillFactor = 1.0,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.stretch,
    this.alignContent = AlignContent.flexStart,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
  })  : assert(targetExtent > 0),
        assert(fillFactor >= 0.0 && fillFactor <= 1.0);

  /// The aspect ratio (width / height) for each child.
  final List<double> aspectRatios;

  /// The target extent (height for vertical scroll, width for horizontal).
  /// Items will be sized exactly at this height (multiplied by their aspect ratio).
  /// This value should change smoothly during pinch gestures.
  final double targetExtent;

  /// Controls how much rows are filled to the available width.
  ///
  /// - 0.0: Items are sized exactly at targetExtent, rows may have empty space
  /// - 1.0: Items are scaled to fill the row completely
  /// - Values between provide smooth interpolation for transitions
  ///
  /// Use this to animate from "scaling mode" (0.0) to "filled mode" (1.0)
  /// when a pinch gesture ends.
  final double fillFactor;

  @override
  final FlexDirection flexDirection;

  @override
  final FlexWrap flexWrap;

  @override
  final JustifyContent justifyContent;

  @override
  final AlignItems alignItems;

  @override
  final AlignContent alignContent;

  @override
  final double mainAxisSpacing;

  @override
  final double crossAxisSpacing;

  @override
  final int? maxLines;

  @override
  bool shouldRelayout(
    covariant SliverFlexboxDelegateWithDirectExtent oldDelegate,
  ) {
    final aspectRatiosChanged =
        !listEquals(oldDelegate.aspectRatios, aspectRatios);

    return oldDelegate.flexDirection != flexDirection ||
        oldDelegate.flexWrap != flexWrap ||
        oldDelegate.justifyContent != justifyContent ||
        oldDelegate.alignItems != alignItems ||
        oldDelegate.alignContent != alignContent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.maxLines != maxLines ||
        oldDelegate.targetExtent != targetExtent ||
        oldDelegate.fillFactor != fillFactor ||
        aspectRatiosChanged;
  }

  @override
  FlexItemData getFlexItemData(int index) {
    return const FlexItemData(flexGrow: 0.0, flexShrink: 0.0);
  }

  @override
  SliverFlexboxLayout getLayout(
    SliverConstraints constraints, {
    required int childCount,
  }) {
    final crossAxisExtent = constraints.crossAxisExtent;
    final actualChildCount = math.min(childCount, aspectRatios.length);

    if (actualChildCount == 0 || (maxLines != null && maxLines! <= 0)) {
      return SliverFlexboxLayout(
        lines: const [],
        crossAxisExtent: crossAxisExtent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      );
    }

    final lines = <SliverFlexboxLine>[];
    int currentLineStart = 0;
    double currentLineWidth = 0.0;
    final pendingItems = <_DirectExtentItem>[];

    for (int i = 0; i < actualChildCount; i++) {
      // Item width is directly proportional to targetExtent
      final itemWidth = targetExtent * aspectRatios[i];

      final spacingNeeded = pendingItems.isEmpty ? 0.0 : crossAxisSpacing;
      final projectedWidth = currentLineWidth + spacingNeeded + itemWidth;
      final canWrapMore = maxLines == null || (lines.length + 1) < maxLines!;

      // Start a new line when items exceed available width
      if (pendingItems.isNotEmpty &&
          projectedWidth > crossAxisExtent &&
          canWrapMore) {
        // Create the line with items at their exact target size
        lines.add(_createDirectLine(
          pendingItems: pendingItems,
          lineStart: currentLineStart,
          rowHeight: targetExtent,
          availableWidth: crossAxisExtent,
          fillFactor: fillFactor,
        ));

        // Start new line
        currentLineStart = i;
        currentLineWidth = itemWidth;
        pendingItems
          ..clear()
          ..add(_DirectExtentItem(
            index: i,
            width: itemWidth,
          ));
      } else {
        currentLineWidth = projectedWidth;
        pendingItems.add(
          _DirectExtentItem(
            index: i,
            width: itemWidth,
          ),
        );
      }
    }

    // Add the last line (don't fill the last line to avoid stretching)
    if (pendingItems.isNotEmpty) {
      lines.add(_createDirectLine(
        pendingItems: pendingItems,
        lineStart: currentLineStart,
        rowHeight: targetExtent,
        availableWidth: crossAxisExtent,
        fillFactor: 0.0, // Last line never fills
      ));
    }

    return SliverFlexboxLayout(
      lines: lines,
      crossAxisExtent: crossAxisExtent,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  SliverFlexboxLine _createDirectLine({
    required List<_DirectExtentItem> pendingItems,
    required int lineStart,
    required double rowHeight,
    required double availableWidth,
    required double fillFactor,
  }) {
    final itemCount = pendingItems.length;
    final totalSpacing = crossAxisSpacing * (itemCount - 1);

    // Calculate total base width of all items
    double totalBaseWidth = 0.0;
    for (final item in pendingItems) {
      totalBaseWidth += item.width;
    }

    // Calculate scale factor to fill the row
    final availableForItems = availableWidth - totalSpacing;
    final safeBaseWidth = totalBaseWidth > 0.0 ? totalBaseWidth : 1.0;
    final fillScale =
        availableForItems > 0.0 ? availableForItems / safeBaseWidth : 1.0;

    // Interpolate between 1.0 (no fill) and fillScale (full fill)
    var actualScale = 1.0 + (fillScale - 1.0) * fillFactor;
    if (!actualScale.isFinite || actualScale <= 0.0) {
      actualScale = 1.0;
    }
    final actualRowHeight = rowHeight * actualScale;

    final items = <FlexLineItem>[];
    double crossAxisOffset = 0.0;
    double totalWidth = 0.0;

    for (int i = 0; i < pendingItems.length; i++) {
      final item = pendingItems[i];
      final actualItemWidth = item.width * actualScale;

      items.add(FlexLineItem(
        index: item.index,
        mainAxisExtent: actualItemWidth,
        crossAxisExtent: actualRowHeight,
        crossAxisOffset: crossAxisOffset,
        flexGrow: 0.0,
        flexShrink: 0.0,
        originalMainAxisExtent: item.width,
      ));

      crossAxisOffset += actualItemWidth;
      if (i < pendingItems.length - 1) {
        crossAxisOffset += crossAxisSpacing;
      }
      totalWidth = crossAxisOffset;
    }

    return SliverFlexboxLine(
      firstIndex: lineStart,
      lastIndex: lineStart + pendingItems.length - 1,
      mainAxisExtent: actualRowHeight,
      crossAxisExtent: totalWidth,
      itemCount: pendingItems.length,
      items: items,
    );
  }
}

class _DirectExtentItem {
  const _DirectExtentItem({
    required this.index,
    required this.width,
  });

  final int index;
  final double width;
}
