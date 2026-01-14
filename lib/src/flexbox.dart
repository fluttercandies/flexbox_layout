import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'flex_item_data.dart';
import 'render_flexbox.dart';

/// A widget that implements the flexbox layout algorithm.
///
/// This widget displays its children in a flex container, laying them out
/// according to the flexbox layout model (similar to CSS Flexbox).
///
/// The [Flexbox] widget supports:
/// * Multiple layout directions ([FlexDirection])
/// * Wrapping behavior ([FlexWrap])
/// * Main axis alignment ([JustifyContent])
/// * Cross axis alignment ([AlignItems])
/// * Multi-line alignment ([AlignContent])
///
/// Use [FlexItem] to wrap children when you need to specify flex properties
/// like [FlexItemData.flexGrow], [FlexItemData.flexShrink], or
/// [FlexItemData.alignSelf].
///
/// Example:
/// ```dart
/// Flexbox(
///   flexDirection: FlexDirection.row,
///   flexWrap: FlexWrap.wrap,
///   justifyContent: JustifyContent.spaceBetween,
///   children: [
///     FlexItem(
///       flexGrow: 1,
///       child: Container(width: 100, height: 100, color: Colors.red),
///     ),
///     FlexItem(
///       flexGrow: 2,
///       child: Container(width: 100, height: 100, color: Colors.blue),
///     ),
///   ],
/// )
/// ```
class Flexbox extends MultiChildRenderObjectWidget {
  /// Creates a flexbox layout.
  const Flexbox({
    super.key,
    this.flexDirection = FlexDirection.row,
    this.flexWrap = FlexWrap.wrap,
    this.justifyContent = JustifyContent.flexStart,
    this.alignItems = AlignItems.flexStart,
    this.alignContent = AlignContent.flexStart,
    this.textDirection,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.maxLines,
    this.clipBehavior = Clip.none,
    super.children,
  });

  /// The direction in which flex items are placed.
  ///
  /// Defaults to [FlexDirection.row].
  final FlexDirection flexDirection;

  /// How flex items wrap when there is not enough space on the main axis.
  ///
  /// Defaults to [FlexWrap.wrap].
  final FlexWrap flexWrap;

  /// How flex items are aligned along the main axis.
  ///
  /// Defaults to [JustifyContent.flexStart].
  final JustifyContent justifyContent;

  /// How flex items are aligned along the cross axis.
  ///
  /// Defaults to [AlignItems.flexStart].
  final AlignItems alignItems;

  /// How flex lines are aligned in the cross axis when there is extra space.
  ///
  /// This property has no effect when [flexWrap] is [FlexWrap.noWrap].
  ///
  /// Defaults to [AlignContent.flexStart].
  final AlignContent alignContent;

  /// The text direction to use for resolving [flexDirection].
  ///
  /// If null, the ambient [Directionality] is used.
  final TextDirection? textDirection;

  /// The spacing between flex items along the main axis.
  ///
  /// Defaults to 0.0.
  final double mainAxisSpacing;

  /// The spacing between flex lines along the cross axis.
  ///
  /// Defaults to 0.0.
  final double crossAxisSpacing;

  /// The maximum number of flex lines.
  ///
  /// If null, there is no limit.
  final int? maxLines;

  /// The clipping behavior.
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  @override
  RenderFlexbox createRenderObject(BuildContext context) {
    return RenderFlexbox(
      flexDirection: flexDirection,
      flexWrap: flexWrap,
      justifyContent: justifyContent,
      alignItems: alignItems,
      alignContent: alignContent,
      textDirection: textDirection ?? Directionality.of(context),
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      maxLines: maxLines,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFlexbox renderObject) {
    renderObject
      ..flexDirection = flexDirection
      ..flexWrap = flexWrap
      ..justifyContent = justifyContent
      ..alignItems = alignItems
      ..alignContent = alignContent
      ..textDirection = textDirection ?? Directionality.of(context)
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing
      ..maxLines = maxLines;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<FlexDirection>('flexDirection', flexDirection));
    properties.add(EnumProperty<FlexWrap>('flexWrap', flexWrap));
    properties.add(
      EnumProperty<JustifyContent>('justifyContent', justifyContent),
    );
    properties.add(EnumProperty<AlignItems>('alignItems', alignItems));
    properties.add(EnumProperty<AlignContent>('alignContent', alignContent));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(DoubleProperty('mainAxisSpacing', mainAxisSpacing));
    properties.add(DoubleProperty('crossAxisSpacing', crossAxisSpacing));
    properties.add(IntProperty('maxLines', maxLines));
  }
}

/// A widget that wraps a child with flex item properties.
///
/// Use this widget to specify how a child should behave within a [Flexbox]
/// layout. You can control properties like:
/// * [flexGrow] - How much the item should grow relative to others
/// * [flexShrink] - How much the item should shrink relative to others
/// * [alignSelf] - Override the parent's [AlignItems] for this item
/// * [order] - The order in which items appear
/// * [flexBasisPercent] - The initial size as a percentage of the parent
///
/// Example:
/// ```dart
/// FlexItem(
///   flexGrow: 1,
///   flexShrink: 0,
///   alignSelf: AlignSelf.center,
///   child: Text('Hello'),
/// )
/// ```
class FlexItem extends ParentDataWidget<FlexboxParentData> {
  /// Creates a flex item.
  const FlexItem({
    super.key,
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
    required super.child,
  })  : assert(order >= 0, 'order must be non-negative'),
        assert(flexGrow >= 0, 'flexGrow must be non-negative'),
        assert(flexShrink >= 0, 'flexShrink must be non-negative');

  /// The order attribute can change the ordering of the children views are
  /// laid out.
  ///
  /// By default, children are displayed and laid out in the same order as they
  /// appear in the children list. If not specified, [kFlexItemOrderDefault] is
  /// set as a default value.
  final int order;

  /// The flex grow attribute determines how much this child will grow if
  /// positive free space is distributed.
  ///
  /// If not specified, [kFlexGrowDefault] (0.0) is set as a default value,
  /// meaning the item will not grow.
  final double flexGrow;

  /// The flex shrink attribute determines how much this child will shrink if
  /// negative free space is distributed.
  ///
  /// If not specified, [kFlexShrinkDefault] (1.0) is set as a default value,
  /// meaning the item will shrink proportionally.
  final double flexShrink;

  /// The alignment for this specific item along the cross axis.
  ///
  /// If set to [AlignSelf.auto], the item inherits the [Flexbox.alignItems]
  /// value from its parent.
  final AlignSelf alignSelf;

  /// The initial main size as a fraction (0.0 to 1.0) of the parent's main size.
  ///
  /// If this value is set, it overrides the width/height specified on the child.
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

  /// Whether this item should start on a new flex line.
  ///
  /// This attribute is ignored if [Flexbox.flexWrap] is [FlexWrap.noWrap].
  final bool wrapBefore;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexboxParentData);
    final parentData = renderObject.parentData! as FlexboxParentData;
    bool needsLayout = false;

    final newData = FlexItemData(
      order: order,
      flexGrow: flexGrow,
      flexShrink: flexShrink,
      alignSelf: alignSelf,
      flexBasisPercent: flexBasisPercent,
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      wrapBefore: wrapBefore,
    );

    if (parentData.flexItemData != newData) {
      parentData.flexItemData = newData;
      needsLayout = true;
    }

    if (needsLayout) {
      final targetParent = renderObject.parent;
      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Flexbox;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      IntProperty('order', order, defaultValue: kFlexItemOrderDefault),
    );
    properties.add(
      DoubleProperty('flexGrow', flexGrow, defaultValue: kFlexGrowDefault),
    );
    properties.add(
      DoubleProperty(
        'flexShrink',
        flexShrink,
        defaultValue: kFlexShrinkDefault,
      ),
    );
    properties.add(
      EnumProperty<AlignSelf>(
        'alignSelf',
        alignSelf,
        defaultValue: AlignSelf.auto,
      ),
    );
    properties.add(
      DoubleProperty(
        'flexBasisPercent',
        flexBasisPercent,
        defaultValue: kFlexBasisPercentDefault,
      ),
    );
    properties.add(DoubleProperty('minWidth', minWidth, defaultValue: null));
    properties.add(DoubleProperty('minHeight', minHeight, defaultValue: null));
    properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: null));
    properties.add(DoubleProperty('maxHeight', maxHeight, defaultValue: null));
    properties.add(
      FlagProperty('wrapBefore', value: wrapBefore, ifTrue: 'wrap before'),
    );
  }
}
