import 'package:flutter/widgets.dart';

import 'sliver_flexbox_delegate.dart';
import 'sliver_flexbox_list.dart';

/// A scrollable flexbox list widget that follows the same pattern as [GridView].
///
/// This widget provides a scrollable flexbox list similar to [ListView] or
/// [GridView] but with flexbox layout capabilities. It extends [BoxScrollView]
/// which handles the scrolling mechanics and padding.
///
/// Example:
/// ```dart
/// FlexboxList.count(
///   crossAxisCount: 3,
///   childAspectRatio: 1.0,
///   mainAxisSpacing: 8,
///   crossAxisSpacing: 8,
///   children: List.generate(100, (index) => ColoredBox(color: Colors.blue)),
/// )
/// ```
///
/// See also:
/// * [SliverFlexbox], which is the sliver version for use in [CustomScrollView].
/// * [GridView], which is the Flutter framework equivalent for grid layouts.
/// * [BoxScrollView], the base class that handles scrolling.
class FlexboxList extends BoxScrollView {
  /// Creates a flexbox list with a fixed number of children.
  FlexboxList({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.flexboxDelegate,
    required List<Widget> children,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : childrenDelegate = SliverChildListDelegate(children);

  /// Creates a flexbox list with a builder.
  FlexboxList.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.flexboxDelegate,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Creates a flexbox list with a fixed cross axis count.
  FlexboxList.count({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    required List<Widget> children,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  })  : flexboxDelegate = SliverFlexboxDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        childrenDelegate = SliverChildListDelegate(children);

  /// Creates a flexbox list with a maximum cross axis extent.
  FlexboxList.extent({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required double maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    required List<Widget> children,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  })  : flexboxDelegate = SliverFlexboxDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        childrenDelegate = SliverChildListDelegate(children);

  /// The flexbox delegate that controls the layout of children.
  ///
  /// Similar to [GridView.gridDelegate], this delegate determines how children
  /// are positioned in the flexbox layout.
  final SliverFlexboxDelegate flexboxDelegate;

  /// The delegate that supplies children for this widget.
  ///
  /// Similar to [GridView.childrenDelegate], this delegate provides the
  /// children to be laid out by [flexboxDelegate].
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverFlexbox(
      delegate: childrenDelegate,
      flexboxDelegate: flexboxDelegate,
    );
  }
}
