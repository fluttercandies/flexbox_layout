import 'dart:math';

import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/material.dart';

import '../theme/neo_brutalism.dart';
import '../widgets/neo_widgets.dart';

/// Showcases all available SliverFlexboxDelegate types.
class DelegatesShowcasePage extends StatefulWidget {
  const DelegatesShowcasePage({super.key});

  @override
  State<DelegatesShowcasePage> createState() => _DelegatesShowcasePageState();
}

class _DelegatesShowcasePageState extends State<DelegatesShowcasePage> {
  _DelegateType _selectedType = _DelegateType.fixedCrossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoBrutalism.grey,
      appBar: NeoAppBar(title: 'Delegates', color: NeoBrutalism.cyan),
      body: Column(
        children: [
          // Delegate type selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NeoBrutalism.white,
              border: Border(
                bottom: BorderSide(
                  color: NeoBrutalism.black,
                  width: NeoBrutalism.borderWidth,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _DelegateType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: NeoBrutalism.shapeDecoration(
                          color: isSelected
                              ? NeoBrutalism.cyan
                              : NeoBrutalism.white,
                          radius: 8,
                          hasShadow: isSelected,
                        ),
                        child: Text(
                          type.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isSelected
                                ? NeoBrutalism.white
                                : NeoBrutalism.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: NeoBrutalism.shapeDecoration(color: NeoBrutalism.white),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: NeoBrutalism.circleDecoration(
                    color: NeoBrutalism.cyan,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: NeoBrutalism.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedType.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedType.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: NeoBrutalism.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedType) {
      case _DelegateType.fixedCrossAxisCount:
        return _FixedCrossAxisCountDemo();
      case _DelegateType.maxCrossAxisExtent:
        return _MaxCrossAxisExtentDemo();
      case _DelegateType.aspectRatios:
        return _AspectRatiosDemo();
      case _DelegateType.dynamicAspectRatios:
        return _DynamicAspectRatiosDemo();
      case _DelegateType.flexValues:
        return _FlexValuesDemo();
      case _DelegateType.builder:
        return _BuilderDemo();
    }
  }
}

enum _DelegateType {
  fixedCrossAxisCount(
    label: 'FixedCount',
    title: 'FixedCrossAxisCount',
    description: 'Grid-like layout with fixed number of columns.',
  ),
  maxCrossAxisExtent(
    label: 'MaxExtent',
    title: 'MaxCrossAxisExtent',
    description: 'Grid layout with maximum item width.',
  ),
  aspectRatios(
    label: 'AspectRatios',
    title: 'AspectRatios',
    description: 'True flexbox layout with different aspect ratios.',
  ),
  dynamicAspectRatios(
    label: 'Dynamic',
    title: 'DynamicAspectRatios',
    description: 'Flexbox with dynamic aspect ratios resolved at runtime.',
  ),
  flexValues(
    label: 'FlexValues',
    title: 'FlexValues',
    description: 'Single row with items sized by flex-grow values.',
  ),
  builder(
    label: 'Builder',
    title: 'Builder',
    description: 'Fully customizable using a builder callback.',
  );

  const _DelegateType({
    required this.label,
    required this.title,
    required this.description,
  });

  final String label;
  final String title;
  final String description;
}

// ============================================================================
// Fixed Cross Axis Count Demo
// ============================================================================

class _FixedCrossAxisCountDemo extends StatefulWidget {
  @override
  State<_FixedCrossAxisCountDemo> createState() =>
      _FixedCrossAxisCountDemoState();
}

class _FixedCrossAxisCountDemoState extends State<_FixedCrossAxisCountDemo> {
  final FlexboxItemAnimationController _itemAnimationController =
      FlexboxItemAnimationController.auto();
  int _crossAxisCount = 3;
  double _childAspectRatio = 1.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NeoControlBar(
          children: [
            _NeoControlItem(
              label: 'Cols',
              value: '$_crossAxisCount',
              child: Slider(
                value: _crossAxisCount.toDouble(),
                min: 1,
                max: 6,
                divisions: 5,
                onChanged: (v) => setState(() => _crossAxisCount = v.round()),
              ),
            ),
            SizedBox(width: 12),
            _NeoControlItem(
              label: 'Ratio',
              value: _childAspectRatio.toStringAsFixed(1),
              child: Slider(
                value: _childAspectRatio,
                min: 0.5,
                max: 2.0,
                onChanged: (v) => setState(() => _childAspectRatio = v),
              ),
            ),
          ],
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverFlexbox(
                  delegate: SliverChildBuilderDelegate(
                    withFlexboxItemAnimation(
                      itemBuilder: (context, index) => _NeoTile(index: index),
                      controller: _itemAnimationController,
                    ),
                    childCount: 50,
                  ),
                  flexboxDelegate: SliverFlexboxDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: _childAspectRatio,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Max Cross Axis Extent Demo
// ============================================================================

class _MaxCrossAxisExtentDemo extends StatefulWidget {
  @override
  State<_MaxCrossAxisExtentDemo> createState() =>
      _MaxCrossAxisExtentDemoState();
}

class _MaxCrossAxisExtentDemoState extends State<_MaxCrossAxisExtentDemo> {
  final FlexboxItemAnimationController _itemAnimationController =
      FlexboxItemAnimationController.auto();
  double _maxCrossAxisExtent = 150.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NeoControlBar(
          children: [
            _NeoControlItem(
              label: 'Max Width',
              value: '${_maxCrossAxisExtent.round()}px',
              child: Slider(
                value: _maxCrossAxisExtent,
                min: 50,
                max: 300,
                onChanged: (v) => setState(() => _maxCrossAxisExtent = v),
              ),
            ),
          ],
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverFlexbox(
                  delegate: SliverChildBuilderDelegate(
                    withFlexboxItemAnimation(
                      itemBuilder: (context, index) => _NeoTile(index: index),
                      controller: _itemAnimationController,
                    ),
                    childCount: 50,
                  ),
                  flexboxDelegate: SliverFlexboxDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _maxCrossAxisExtent,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Aspect Ratios Demo
// ============================================================================

class _AspectRatiosDemo extends StatefulWidget {
  @override
  State<_AspectRatiosDemo> createState() => _AspectRatiosDemoState();
}

class _AspectRatiosDemoState extends State<_AspectRatiosDemo> {
  final FlexboxItemAnimationController _itemAnimationController =
      FlexboxItemAnimationController.auto();
  double _targetRowHeight = 150.0;
  final List<double> _aspectRatios = List.generate(
    100,
    (i) => 0.5 + Random(i).nextDouble() * 1.5,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NeoControlBar(
          children: [
            _NeoControlItem(
              label: 'Row Height',
              value: '${_targetRowHeight.round()}px',
              child: Slider(
                value: _targetRowHeight,
                min: 80,
                max: 300,
                onChanged: (v) => setState(() => _targetRowHeight = v),
              ),
            ),
          ],
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverFlexbox(
                  delegate: SliverChildBuilderDelegate(
                    withFlexboxItemAnimation(
                      itemBuilder: (context, index) => _NeoAspectTile(
                        index: index,
                        aspectRatio: _aspectRatios[index],
                      ),
                      controller: _itemAnimationController,
                    ),
                    childCount: _aspectRatios.length,
                  ),
                  flexboxDelegate: SliverFlexboxDelegateWithAspectRatios(
                    aspectRatios: _aspectRatios,
                    targetRowHeight: _targetRowHeight,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Dynamic Aspect Ratios Demo
// ============================================================================

class _DynamicAspectRatiosDemo extends StatefulWidget {
  @override
  State<_DynamicAspectRatiosDemo> createState() =>
      _DynamicAspectRatiosDemoState();
}

class _DynamicAspectRatiosDemoState extends State<_DynamicAspectRatiosDemo> {
  final FlexboxItemAnimationController _itemAnimationController =
      FlexboxItemAnimationController.auto();
  final int _itemCount = 50;
  final Map<int, double> _loadedAspectRatios = {};

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() {
    for (int i = 0; i < _itemCount; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          setState(
            () => _loadedAspectRatios[i] = 0.5 + Random(i).nextDouble() * 1.5,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: NeoBrutalism.shapeDecoration(
            color: NeoBrutalism.white,
            hasShadow: false,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: NeoBrutalism.shapeDecoration(
                  color: NeoBrutalism.cyan,
                  radius: 6,
                  hasShadow: false,
                ),
                child: Text(
                  '${_loadedAspectRatios.length}/$_itemCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: NeoBrutalism.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading...',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: NeoBrutalism.black.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              NeoIconButton(
                icon: Icons.refresh_rounded,
                onPressed: () {
                  setState(() => _loadedAspectRatios.clear());
                  _simulateLoading();
                },
                size: 36,
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverFlexbox(
                  delegate: SliverChildBuilderDelegate(
                    withFlexboxItemAnimation(
                      itemBuilder: (context, index) => _NeoDynamicTile(
                        index: index,
                        isLoaded: _loadedAspectRatios.containsKey(index),
                      ),
                      controller: _itemAnimationController,
                    ),
                    childCount: _itemCount,
                  ),
                  flexboxDelegate: SliverFlexboxDelegateWithDynamicAspectRatios(
                    childCount: _itemCount,
                    aspectRatioProvider: (i) => _loadedAspectRatios[i],
                    defaultAspectRatio: 1.0,
                    targetRowHeight: 150,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Flex Values Demo
// ============================================================================

class _FlexValuesDemo extends StatefulWidget {
  @override
  State<_FlexValuesDemo> createState() => _FlexValuesDemoState();
}

class _FlexValuesDemoState extends State<_FlexValuesDemo> {
  final FlexboxItemAnimationController _itemAnimationController =
      FlexboxItemAnimationController.auto();
  final List<double> _flexValues = [1, 2, 1, 3, 1];
  double _rowHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NeoControlBar(
          children: [
            _NeoControlItem(
              label: 'Height',
              value: '${_rowHeight.round()}px',
              child: Slider(
                value: _rowHeight,
                min: 50,
                max: 200,
                onChanged: (v) => setState(() => _rowHeight = v),
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: NeoBrutalism.shapeDecoration(
            color: NeoBrutalism.white,
            hasShadow: false,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Flex Values',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  NeoIconButton(
                    icon: Icons.add,
                    onPressed: _flexValues.length < 8
                        ? () => setState(() => _flexValues.add(1))
                        : null,
                    size: 32,
                  ),
                  const SizedBox(width: 4),
                  NeoIconButton(
                    icon: Icons.remove,
                    onPressed: _flexValues.length > 1
                        ? () => setState(() => _flexValues.removeLast())
                        : null,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: _flexValues.asMap().entries.map((e) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          Text(
                            '#${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: e.value,
                            min: 0.5,
                            max: 5,
                            divisions: 9,
                            onChanged: (v) =>
                                setState(() => _flexValues[e.key] = v),
                          ),
                          Text(
                            e.value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverFlexbox(
                  delegate: SliverChildBuilderDelegate(
                    withFlexboxItemAnimation(
                      itemBuilder: (context, index) => _NeoFlexTile(
                        index: index,
                        flexValue: _flexValues[index],
                      ),
                      controller: _itemAnimationController,
                    ),
                    childCount: _flexValues.length,
                  ),
                  flexboxDelegate: SliverFlexboxDelegateWithFlexValues(
                    flexValues: _flexValues,
                    rowHeight: _rowHeight,
                    crossAxisSpacing: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Builder Demo
// ============================================================================

class _BuilderDemo extends StatefulWidget {
  @override
  State<_BuilderDemo> createState() => _BuilderDemoState();
}

class _BuilderDemoState extends State<_BuilderDemo> {
  final FlexboxItemAnimationController _itemAnimationController =
      FlexboxItemAnimationController.auto();
  bool _varyFlexGrow = true;
  bool _varyAspectRatio = true;

  FlexChildInfo _buildChildInfo(int index) {
    final baseAspectRatio = 1.0;
    final aspectRatio = _varyAspectRatio
        ? baseAspectRatio * (0.7 + (index % 5) * 0.15)
        : baseAspectRatio;
    final flexGrow = _varyFlexGrow ? 1.0 + (index % 3) * 0.5 : 1.0;
    return FlexChildInfo(
      index: index,
      aspectRatio: aspectRatio,
      flexGrow: flexGrow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: NeoBrutalism.shapeDecoration(
            color: NeoBrutalism.white,
            hasShadow: false,
          ),
          child: Row(
            children: [
              Expanded(
                child: _NeoCheckbox(
                  label: 'Vary flexGrow',
                  value: _varyFlexGrow,
                  onChanged: (v) => setState(() => _varyFlexGrow = v),
                ),
              ),
              Expanded(
                child: _NeoCheckbox(
                  label: 'Vary aspectRatio',
                  value: _varyAspectRatio,
                  onChanged: (v) => setState(() => _varyAspectRatio = v),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverFlexbox(
                  delegate: SliverChildBuilderDelegate(
                    withFlexboxItemAnimation(
                      itemBuilder: (context, index) {
                        final info = _buildChildInfo(index);
                        return _NeoBuilderTile(
                          index: index,
                          flexGrow: info.flexGrow,
                          aspectRatio: info.aspectRatio,
                        );
                      },
                      controller: _itemAnimationController,
                    ),
                    childCount: 80,
                  ),
                  flexboxDelegate: SliverFlexboxDelegateWithBuilder(
                    childCount: 80,
                    childInfoBuilder: _buildChildInfo,
                    targetRowHeight: 120,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _NeoControlBar extends StatelessWidget {
  const _NeoControlBar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: NeoBrutalism.shapeDecoration(
        color: NeoBrutalism.white,
        hasShadow: false,
      ),
      child: Row(children: children),
    );
  }
}

class _NeoControlItem extends StatelessWidget {
  const _NeoControlItem({
    required this.label,
    required this.value,
    required this.child,
  });
  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Expanded(child: child),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: NeoBrutalism.shapeDecoration(
              color: NeoBrutalism.cyan,
              radius: 6,
              hasShadow: false,
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: NeoBrutalism.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeoCheckbox extends StatelessWidget {
  const _NeoCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: NeoBrutalism.shapeDecoration(
              color: value ? NeoBrutalism.cyan : NeoBrutalism.white,
              radius: 6,
              hasShadow: false,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: NeoBrutalism.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tile Widgets
// ============================================================================

final _tileColors = [
  NeoBrutalism.yellow,
  NeoBrutalism.pink,
  NeoBrutalism.blue,
  NeoBrutalism.purple,
  NeoBrutalism.orange,
  NeoBrutalism.green,
  NeoBrutalism.red,
  NeoBrutalism.cyan,
];

class _NeoTile extends StatelessWidget {
  const _NeoTile({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = _tileColors[index % _tileColors.length];
    return Container(
      decoration: NeoBrutalism.shapeDecoration(
        color: color,
        radius: 8,
        hasShadow: false,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}

class _NeoAspectTile extends StatelessWidget {
  const _NeoAspectTile({required this.index, required this.aspectRatio});
  final int index;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final color = _tileColors[index % _tileColors.length];
    return Container(
      decoration: NeoBrutalism.shapeDecoration(
        color: color,
        radius: 8,
        hasShadow: false,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'ar:${aspectRatio.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeoDynamicTile extends StatelessWidget {
  const _NeoDynamicTile({required this.index, required this.isLoaded});
  final int index;
  final bool isLoaded;

  @override
  Widget build(BuildContext context) {
    final color = isLoaded
        ? _tileColors[index % _tileColors.length]
        : NeoBrutalism.grey;
    return Container(
      decoration: NeoBrutalism.shapeDecoration(
        color: color,
        radius: 8,
        hasShadow: false,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLoaded)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: NeoBrutalism.black,
                ),
              )
            else
              Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            if (isLoaded) const Icon(Icons.check, size: 14),
          ],
        ),
      ),
    );
  }
}

class _NeoFlexTile extends StatelessWidget {
  const _NeoFlexTile({required this.index, required this.flexValue});
  final int index;
  final double flexValue;

  @override
  Widget build(BuildContext context) {
    final color = _tileColors[index % _tileColors.length];
    return Container(
      decoration: NeoBrutalism.shapeDecoration(
        color: color,
        radius: 8,
        hasShadow: false,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'flex:${flexValue.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeoBuilderTile extends StatelessWidget {
  const _NeoBuilderTile({
    required this.index,
    required this.flexGrow,
    required this.aspectRatio,
  });
  final int index;
  final double flexGrow;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final color = _tileColors[index % _tileColors.length];
    return Container(
      decoration: NeoBrutalism.shapeDecoration(
        color: color,
        radius: 8,
        hasShadow: false,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'flex:${flexGrow.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            Text(
              'ar:${aspectRatio.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
