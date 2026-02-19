import 'package:flutter/widgets.dart';

import 'scalable_flexbox_controller.dart';
import 'sliver_flexbox_delegate.dart';
import 'sliver_flexbox_list.dart';

/// A sliver that displays scalable flexbox content with pinch-to-zoom support.
///
/// This widget is designed for use inside a [CustomScrollView] and provides
/// a Google Photos-like experience where users can pinch to zoom the grid.
///
/// The widget automatically rebuilds when the controller's extent changes,
/// adjusting the grid layout accordingly.
///
/// Example:
/// ```dart
/// final controller = FlexboxScaleController(
///   initialExtent: 150.0,
///   minExtent: 80.0,
///   maxExtent: 300.0,
/// );
///
/// // Wrap your scroll view with GestureDetector to handle scale gestures
/// GestureDetector(
///   onScaleStart: controller.onScaleStart,
///   onScaleUpdate: controller.onScaleUpdate,
///   onScaleEnd: controller.onScaleEnd,
///   onDoubleTap: controller.onDoubleTap,
///   child: CustomScrollView(
///     slivers: [
///       SliverScalableFlexbox(
///         controller: controller,
///         mainAxisSpacing: 2.0,
///         crossAxisSpacing: 2.0,
///         delegate: SliverChildBuilderDelegate(
///           (context, index) => Image.network('...'),
///           childCount: 100,
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// See also:
/// * [FlexboxScaleController], which manages the scale state with spring physics.
/// * [SliverFlexbox], the non-scalable sliver version.
class SliverScalableFlexbox extends StatelessWidget {
  /// Creates a sliver scalable flexbox.
  const SliverScalableFlexbox({
    super.key,
    required this.controller,
    required this.delegate,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
  });

  /// The controller that manages the scale state.
  final FlexboxScaleController controller;

  /// The delegate that supplies children.
  final SliverChildDelegate delegate;

  /// The spacing between children along the main axis.
  final double mainAxisSpacing;

  /// The spacing between children along the cross axis.
  final double crossAxisSpacing;

  /// The aspect ratio of each child.
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.extentListenable,
      builder: (context, extent, child) {
        return SliverFlexbox(
          delegate: delegate,
          flexboxDelegate: SliverFlexboxDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: extent,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
        );
      },
    );
  }
}
