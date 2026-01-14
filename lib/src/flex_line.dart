import 'package:flutter/painting.dart';

/// Holds properties related to a single flex line in a flexbox layout.
///
/// A [FlexLine] represents one row (or column, depending on [FlexDirection])
/// in the flexbox layout. It tracks the position, size, and flex properties
/// of all items within that line.
///
/// This class is used internally by [RenderFlexbox] during the layout
/// calculation process. It accumulates information about children as
/// they are measured and arranged into flex lines.
///
/// ## Properties
///
/// * [left], [top], [right], [bottom] - The boundaries of the flex line
/// * [mainSize] - The size along the main axis
/// * [crossSize] - The size along the cross axis
/// * [itemCount] - The total number of items in this line
/// * [goneItemCount] - The number of items with visibility set to gone
/// * [totalFlexGrow] - Sum of all flexGrow values in this line
/// * [totalFlexShrink] - Sum of all flexShrink values in this line
///
/// ## Example
///
/// This class is typically used internally by [RenderFlexbox] during
/// layout calculation:
/// ```dart
/// var line = FlexLine();
/// line.mainSize = 100.0;
/// line.crossSize = 50.0;
/// line.itemCount = 3;
/// ```
///
/// See also:
/// * [RenderFlexbox], which uses [FlexLine] for layout calculations
/// * [FlexLinesResult], which holds a list of [FlexLine] objects
class FlexLine {
  /// Creates a new [FlexLine].
  FlexLine();

  /// The left boundary of the flex line.
  double left = double.infinity;

  /// The top boundary of the flex line.
  double top = double.infinity;

  /// The right boundary of the flex line.
  double right = double.negativeInfinity;

  /// The bottom boundary of the flex line.
  double bottom = double.negativeInfinity;

  /// The size of the flex line in pixels along the main axis.
  double mainSize = 0;

  /// The sum of the lengths of dividers along the main axis.
  double dividerLengthInMainSize = 0;

  /// The size of the flex line in pixels along the cross axis.
  double crossSize = 0;

  /// The count of the views contained in this flex line.
  int itemCount = 0;

  /// Holds the count of the views whose visibilities are gone.
  int goneItemCount = 0;

  /// The sum of the flexGrow properties of the children included in this flex line.
  double totalFlexGrow = 0;

  /// The sum of the flexShrink properties of the children included in this flex line.
  double totalFlexShrink = 0;

  /// The largest value of the individual child's baseline if the alignItems
  /// value is baseline.
  double maxBaseline = 0;

  /// The sum of the cross size used before this flex line.
  double sumCrossSizeBefore = 0;

  /// Store the indices of the children views whose alignSelf property is stretch.
  final List<int> indicesAlignSelfStretch = [];

  /// The first index of the view in this flex line.
  int firstIndex = 0;

  /// The last index of the view in this flex line.
  int lastIndex = 0;

  /// Set to true if any flex items in this line have flexGrow attributes set.
  bool anyItemsHaveFlexGrow = false;

  /// Set to true if any flex items in this line have flexShrink attributes set.
  bool anyItemsHaveFlexShrink = false;

  /// Returns the count of the views whose visibilities are not gone in this flex line.
  int get itemCountNotGone => itemCount - goneItemCount;

  /// Updates the position and size of the flex line based on a child's layout.
  ///
  /// This method expands the flex line's boundaries to include the specified
  /// child, accounting for margins and decorations.
  ///
  /// The [position] is the child's offset from the origin.
  /// The [size] is the child's rendered size.
  /// The [margin] is the child's margin in the cross axis.
  /// Optional decoration parameters ([leftDecoration], [topDecoration], etc.)
  /// add extra space around the child (e.g., for padding or borders).
  void updatePositionFromView({
    required Offset position,
    required Size size,
    required EdgeInsets margin,
    double leftDecoration = 0,
    double topDecoration = 0,
    double rightDecoration = 0,
    double bottomDecoration = 0,
  }) {
    left = (position.dx - margin.left - leftDecoration).clamp(
      double.negativeInfinity,
      left,
    );
    top = (position.dy - margin.top - topDecoration).clamp(
      double.negativeInfinity,
      top,
    );
    right = (position.dx + size.width + margin.right + rightDecoration).clamp(
      right,
      double.infinity,
    );
    bottom = (position.dy + size.height + margin.bottom + bottomDecoration)
        .clamp(bottom, double.infinity);
  }

  /// Resets the flex line to its initial state.
  ///
  /// All properties are reset to their default values, clearing any
  /// previous layout data.
  void reset() {
    left = double.infinity;
    top = double.infinity;
    right = double.negativeInfinity;
    bottom = double.negativeInfinity;
    mainSize = 0;
    dividerLengthInMainSize = 0;
    crossSize = 0;
    itemCount = 0;
    goneItemCount = 0;
    totalFlexGrow = 0;
    totalFlexShrink = 0;
    maxBaseline = 0;
    sumCrossSizeBefore = 0;
    indicesAlignSelfStretch.clear();
    firstIndex = 0;
    lastIndex = 0;
    anyItemsHaveFlexGrow = false;
    anyItemsHaveFlexShrink = false;
  }

  @override
  String toString() {
    return 'FlexLine('
        'mainSize: $mainSize, '
        'crossSize: $crossSize, '
        'itemCount: $itemCount, '
        'firstIndex: $firstIndex, '
        'lastIndex: $lastIndex'
        ')';
  }
}

/// Result class to hold calculated flex lines and child state.
///
/// This class is used internally by the flexbox layout algorithm to store
/// the calculated layout results, including all flex lines and their
/// associated child widgets.
///
/// The [flexLines] list contains all the lines calculated during layout,
/// where each line represents a row or column depending on the flex direction.
///
/// ## Example
///
/// ```dart
/// final result = FlexLinesResult();
/// result.flexLines.addAll(calculatedLines);
///
/// for (final line in result.flexLines) {
///   print('Line: ${line.mainSize} x ${line.crossSize}');
///   print('Items: ${line.itemCount}');
/// }
/// ```
///
/// See also:
/// * [FlexLine], which represents individual lines in the result
/// * [RenderFlexbox], which creates and uses this result
class FlexLinesResult {
  /// Creates a new [FlexLinesResult].
  ///
  /// The [flexLines] list will be initialized as empty.
  FlexLinesResult();

  /// The list of flex lines calculated during layout.
  ///
  /// Each [FlexLine] in this list represents one row or column in the
  /// flexbox layout, depending on the [FlexDirection].
  List<FlexLine> flexLines = [];

  /// Resets the result, clearing all flex lines.
  ///
  /// This method is typically called before starting a new layout calculation
  /// to ensure a clean state.
  void reset() {
    flexLines = [];
  }
}
