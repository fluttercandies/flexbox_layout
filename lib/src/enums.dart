/// The direction children items are placed inside the flex container.
/// It determines the direction of the main axis (and the cross axis,
/// perpendicular to the main axis).
enum FlexDirection {
  /// Main axis direction -> horizontal.
  /// Main start to main end -> Left to right (in LTR languages).
  /// Cross start to cross end -> Top to bottom.
  row,

  /// Main axis direction -> horizontal.
  /// Main start to main end -> Right to left (in LTR languages).
  /// Cross start to cross end -> Top to bottom.
  rowReverse,

  /// Main axis direction -> vertical.
  /// Main start to main end -> Top to bottom.
  /// Cross start to cross end -> Left to right (in LTR languages).
  column,

  /// Main axis direction -> vertical.
  /// Main start to main end -> Bottom to top.
  /// Cross start to cross end -> Left to right (in LTR languages).
  columnReverse,
}

/// This attribute controls whether the flex container is single-line or
/// multi-line, and the direction of the cross axis.
enum FlexWrap {
  /// The flex container is single-line.
  noWrap,

  /// The flex container is multi-line.
  wrap,

  /// The flex container is multi-line. The direction of the cross axis is
  /// opposed to the direction as the [wrap].
  wrapReverse,
}

/// This attribute controls the alignment along the main axis.
enum JustifyContent {
  /// Flex items are packed toward the start line.
  flexStart,

  /// Flex items are packed toward the end line.
  flexEnd,

  /// Flex items are centered along the flex line where the flex items belong.
  center,

  /// Flex items are evenly distributed along the flex line, first flex item
  /// is on the start line, the last flex item is on the end line.
  spaceBetween,

  /// Flex items are evenly distributed along the flex line with the same
  /// amount of spaces between the flex lines.
  spaceAround,

  /// Flex items are evenly distributed along the flex line. The difference
  /// between [spaceAround] is that all the spaces between items should be
  /// the same as the space before the first item and after the last item.
  spaceEvenly,
}

/// This attribute controls the alignment along the cross axis.
enum AlignItems {
  /// Flex item's edge is placed on the cross start line.
  flexStart,

  /// Flex item's edge is placed on the cross end line.
  flexEnd,

  /// Flex item's edge is centered along the cross axis.
  center,

  /// Flex items are aligned based on their text's baselines.
  baseline,

  /// Flex items are stretched to fill the flex line's cross size.
  stretch,
}

/// This attribute controls the alignment along the cross axis.
/// The alignment in the same direction can be determined by the [AlignItems]
/// attribute in the parent, but if this is set to other than [AlignSelf.auto],
/// the cross axis alignment is overridden for this child.
enum AlignSelf {
  /// The default value for the AlignSelf attribute, which means to inherit
  /// the [AlignItems] attribute from its parent.
  auto,

  /// This item's edge is placed on the cross start line.
  flexStart,

  /// This item's edge is placed on the cross end line.
  flexEnd,

  /// This item's edge is centered along the cross axis.
  center,

  /// This items is aligned based on their text's baselines.
  baseline,

  /// This item is stretched to fill the flex line's cross size.
  stretch,
}

/// This attribute controls the alignment of the flex lines in the flex container.
enum AlignContent {
  /// Flex lines are packed to the start of the flex container.
  flexStart,

  /// Flex lines are packed to the end of the flex container.
  flexEnd,

  /// Flex lines are centered in the flex container.
  center,

  /// Flex lines are evenly distributed in the flex container. The first flex
  /// line is placed at the start of the flex container, the last flex line
  /// is placed at the end of the flex container.
  spaceBetween,

  /// Flex lines are evenly distributed in the flex container with the same
  /// amount of spaces between the flex lines.
  spaceAround,

  /// Flex lines are stretched to fill the remaining space along the cross axis.
  stretch,
}

/// Extension methods for [FlexDirection].
extension FlexDirectionExtension on FlexDirection {
  /// Returns true if the main axis is horizontal.
  bool get isHorizontal =>
      this == FlexDirection.row || this == FlexDirection.rowReverse;

  /// Returns true if the main axis is vertical.
  bool get isVertical =>
      this == FlexDirection.column || this == FlexDirection.columnReverse;

  /// Returns true if the direction is reversed.
  bool get isReversed =>
      this == FlexDirection.rowReverse || this == FlexDirection.columnReverse;
}

/// Extension methods for [AlignSelf].
extension AlignSelfExtension on AlignSelf {
  /// Converts [AlignSelf] to [AlignItems].
  /// Returns null if [AlignSelf.auto].
  AlignItems? toAlignItems() {
    switch (this) {
      case AlignSelf.auto:
        return null;
      case AlignSelf.flexStart:
        return AlignItems.flexStart;
      case AlignSelf.flexEnd:
        return AlignItems.flexEnd;
      case AlignSelf.center:
        return AlignItems.center;
      case AlignSelf.baseline:
        return AlignItems.baseline;
      case AlignSelf.stretch:
        return AlignItems.stretch;
    }
  }
}
