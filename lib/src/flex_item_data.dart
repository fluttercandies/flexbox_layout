import 'package:flutter/foundation.dart';

import 'enums.dart';

/// Default value for [FlexItemData.order].
///
/// The default order is 1, which means items will appear in their
/// natural DOM order when no explicit order is specified.
const int kFlexItemOrderDefault = 1;

/// Default value for [FlexItemData.flexGrow].
///
/// A value of 0.0 means the item will not grow to fill available space.
const double kFlexGrowDefault = 0.0;

/// Default value for [FlexItemData.flexShrink].
///
/// A value of 1.0 means the item will shrink proportionally to other items
/// when space is limited.
const double kFlexShrinkDefault = 1.0;

/// Value representing flex shrink is not set.
///
/// This is used internally to distinguish between explicit and default values.
const double kFlexShrinkNotSet = 0.0;

/// Default value for [FlexItemData.flexBasisPercent].
///
/// A value of -1.0 indicates that no flex basis percentage is set,
/// and the item's natural size should be used instead.
const double kFlexBasisPercentDefault = -1.0;

/// Data class that holds flex item properties for flexbox layout.
///
/// This class encapsulates all the properties that control how a single child
/// behaves within a [Flexbox] or [SliverFlexbox] layout. It corresponds to
/// the CSS flex item properties.
///
/// ## Properties
///
/// * [order] - Changes the order in which items appear
/// * [flexGrow] - How much the item should grow relative to others
/// * [flexShrink] - How much the item should shrink relative to others
/// * [alignSelf] - Override the parent's [AlignItems] for this item
/// * [flexBasisPercent] - Initial size as a percentage of the parent
/// * [minWidth] / [minHeight] - Minimum dimensions
/// * [maxWidth] / [maxHeight] - Maximum dimensions
/// * [wrapBefore] - Force this item to start on a new line
///
/// ## Example
///
/// ```dart
/// const itemData = FlexItemData(
///   order: 1,
///   flexGrow: 2.0,
///   flexShrink: 1.0,
///   alignSelf: AlignSelf.center,
///   minWidth: 100,
///   maxWidth: 500,
/// );
/// ```
///
/// See also:
/// * [FlexItem], the widget that applies this data to a child
/// * [Flexbox], the widget that uses this data for layout
@immutable
class FlexItemData {
  /// Creates a [FlexItemData] with the given properties.
  const FlexItemData({
    this.order = kFlexItemOrderDefault,
    this.flexGrow = kFlexGrowDefault,
    this.flexShrink = kFlexShrinkDefault,
    this.alignSelf = AlignSelf.auto,
    this.flexBasisPercent = kFlexBasisPercentDefault,
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.wrapBefore = false,
  })  : assert(order >= 0, 'order must be non-negative'),
        assert(flexGrow >= 0, 'flexGrow must be non-negative'),
        assert(flexShrink >= 0, 'flexShrink must be non-negative');

  /// The order attribute can change the ordering of the children views are
  /// laid out. By default, children are displayed and laid out in the same
  /// order as they appear in the layout. If not specified, [kFlexItemOrderDefault]
  /// is set as a default value.
  final int order;

  /// The attribute determines how much this child will grow if positive free
  /// space is distributed relative to the rest of other flex items included
  /// in the same flex line. If not specified, [kFlexGrowDefault] is set as
  /// a default value.
  final double flexGrow;

  /// The attribute determines how much this child will shrink if negative free
  /// space is distributed relative to the rest of other flex items included
  /// in the same flex line. If not specified, [kFlexShrinkDefault] is set as
  /// a default value.
  final double flexShrink;

  /// The attribute determines the alignment along the cross axis (perpendicular
  /// to the main axis). The alignment in the same direction can be determined
  /// by the align items attribute in the parent, but if this is set to other
  /// than [AlignSelf.auto], the cross axis alignment is overridden for this child.
  final AlignSelf alignSelf;

  /// The attribute determines the initial flex item length in a fraction format
  /// relative to its parent. The initial main size of this child View is trying
  /// to be expanded as the specified fraction against the parent main size.
  /// If this value is set, the length specified from width (or height) is
  /// overridden by the calculated value from this attribute.
  /// The default value is -1, which means not set.
  final double flexBasisPercent;

  /// The minimum width the child can shrink to.
  final double? minWidth;

  /// The minimum height the child can shrink to.
  final double? minHeight;

  /// The maximum width the child can expand to.
  final double? maxWidth;

  /// The maximum height the child can expand to.
  final double? maxHeight;

  /// The attribute forces a flex line wrapping. i.e. if this is set to true
  /// for a flex item, the item will become the first item of the new flex line.
  /// (A wrapping happens regardless of the flex items being processed in the
  /// previous flex line)
  /// This attribute is ignored if the flex_wrap attribute is set as noWrap.
  final bool wrapBefore;

  /// Creates a copy of this [FlexItemData] with the given fields replaced
  /// with new values.
  ///
  /// This method is useful for creating a modified version of an existing
  /// [FlexItemData] without mutating the original.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final original = FlexItemData(flexGrow: 1.0);
  /// final modified = original.copyWith(flexGrow: 2.0, minWidth: 100);
  /// print(original.flexGrow); // 1.0 (unchanged)
  /// print(modified.flexGrow);  // 2.0
  /// ```
  FlexItemData copyWith({
    int? order,
    double? flexGrow,
    double? flexShrink,
    AlignSelf? alignSelf,
    double? flexBasisPercent,
    double? minWidth,
    double? minHeight,
    double? maxWidth,
    double? maxHeight,
    bool? wrapBefore,
  }) {
    return FlexItemData(
      order: order ?? this.order,
      flexGrow: flexGrow ?? this.flexGrow,
      flexShrink: flexShrink ?? this.flexShrink,
      alignSelf: alignSelf ?? this.alignSelf,
      flexBasisPercent: flexBasisPercent ?? this.flexBasisPercent,
      minWidth: minWidth ?? this.minWidth,
      minHeight: minHeight ?? this.minHeight,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      wrapBefore: wrapBefore ?? this.wrapBefore,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlexItemData &&
        other.order == order &&
        other.flexGrow == flexGrow &&
        other.flexShrink == flexShrink &&
        other.alignSelf == alignSelf &&
        other.flexBasisPercent == flexBasisPercent &&
        other.minWidth == minWidth &&
        other.minHeight == minHeight &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight &&
        other.wrapBefore == wrapBefore;
  }

  @override
  int get hashCode {
    return Object.hash(
      order,
      flexGrow,
      flexShrink,
      alignSelf,
      flexBasisPercent,
      minWidth,
      minHeight,
      maxWidth,
      maxHeight,
      wrapBefore,
    );
  }

  @override
  String toString() {
    return 'FlexItemData('
        'order: $order, '
        'flexGrow: $flexGrow, '
        'flexShrink: $flexShrink, '
        'alignSelf: $alignSelf, '
        'flexBasisPercent: $flexBasisPercent, '
        'minWidth: $minWidth, '
        'minHeight: $minHeight, '
        'maxWidth: $maxWidth, '
        'maxHeight: $maxHeight, '
        'wrapBefore: $wrapBefore'
        ')';
  }
}
