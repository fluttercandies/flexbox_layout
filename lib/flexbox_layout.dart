// ignore_for_file: dangling_library_doc_comments

/// A Flutter library for flexbox layout.
///
/// This library provides widgets for creating layouts using the CSS Flexbox
/// layout model. It includes:
///
/// * [Flexbox] - A widget similar to Flutter's [Wrap] but with full flexbox
///   layout support including flex-grow, flex-shrink, and more.
/// * [FlexItem] - A widget to wrap children with flex item properties.
/// * [SliverFlexbox] - A sliver version for use in [CustomScrollView].
/// * [FlexboxList] - A convenience widget similar to [GridView] but with
///   flexbox layout capabilities.
///
/// ## Usage
///
/// Basic usage with [Flexbox]:
///
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
///
/// Usage with [FlexboxList]:
///
/// ```dart
/// FlexboxList.count(
///   crossAxisCount: 3,
///   mainAxisSpacing: 8,
///   crossAxisSpacing: 8,
///   children: List.generate(100, (index) => ColoredBox(color: Colors.blue)),
/// )
/// ```

export 'src/dimension_resolver.dart';
export 'src/dynamic_flexbox_list.dart';
export 'src/enums.dart';
export 'src/flex_item_data.dart';
export 'src/flex_line.dart';
export 'src/flexbox.dart';
export 'src/flexbox_list.dart';
export 'src/item_animation.dart';
export 'src/render_flexbox.dart' show FlexboxParentData;
export 'src/scalable_flexbox_controller.dart';
export 'src/sliver_dynamic_flexbox.dart';
export 'src/sliver_flexbox_delegate.dart';
export 'src/sliver_flexbox_layout.dart';
export 'src/sliver_flexbox_list.dart';
export 'src/sliver_scalable_flexbox.dart';
