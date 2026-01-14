# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-14

### Added
- Initial release of the Flutter Flexbox library
- `Flexbox` widget - full CSS Flexbox layout implementation
- `FlexItem` widget - wrapper for flex item properties
- `FlexboxList` - scrollable list with flexbox layout capabilities
- `SliverFlexbox` - sliver version for CustomScrollView
- `DynamicFlexboxList` - auto-sizing flexbox list for variable content
- `SliverDynamicFlexbox` - dynamic sliver for CustomScrollView
- `DimensionResolver` - utility for measuring child dimensions
- Multiple delegate types for different layout scenarios:
  - `SliverFlexboxDelegateWithFixedCrossAxisCount`
  - `SliverFlexboxDelegateWithMaxCrossAxisExtent`
  - `SliverFlexboxDelegateWithAspectRatios`
  - `SliverFlexboxDelegateWithDynamicAspectRatios`
  - `SliverFlexboxDelegateWithFlexValues`
  - `SliverFlexboxDelegateWithBuilder`

### Features
- Full CSS Flexbox layout algorithm implementation
- Support for `flexDirection`, `flexWrap`, `justifyContent`, `alignItems`, `alignContent`
- Flex item properties: `order`, `flexGrow`, `flexShrink`, `alignSelf`, `flexBasisPercent`
- Size constraints: `minWidth`, `minHeight`, `maxWidth`, `maxHeight`
- `wrapBefore` property for explicit line breaks
- Main axis and cross axis spacing
- Item recycling for efficient scrolling
- Dynamic sizing based on aspect ratios
- Text direction support (LTR/RTL)
- Max lines limitation for wrapped layouts
- Configurable thresholds for layout updates:
  - `aspectRatioChangeThreshold` - minimum aspect ratio change to trigger update
  - `crossAxisExtentChangeThreshold` - viewport width change to clear cache
- `FlexboxList` extends `BoxScrollView` for better framework integration
- Comprehensive Dart documentation with examples for all public APIs

### Example
- Complete example app with interactive playground
- Demonstrations of all major features
- Network image gallery example
