import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/material.dart';

import '../theme/neo_brutalism.dart';
import '../widgets/neo_widgets.dart';

final _playgroundColors = [
  NeoBrutalism.yellow,
  NeoBrutalism.pink,
  NeoBrutalism.blue,
  NeoBrutalism.purple,
  NeoBrutalism.orange,
  NeoBrutalism.green,
  NeoBrutalism.red,
  NeoBrutalism.cyan,
];

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  FlexDirection _flexDirection = FlexDirection.row;
  FlexWrap _flexWrap = FlexWrap.wrap;
  JustifyContent _justifyContent = JustifyContent.flexStart;
  AlignItems _alignItems = AlignItems.flexStart;
  AlignContent _alignContent = AlignContent.flexStart;
  double _mainAxisSpacing = 8;
  double _crossAxisSpacing = 8;

  List<_FlexItemConfig> _items = [
    _FlexItemConfig(width: 80, height: 80, color: NeoBrutalism.red),
    _FlexItemConfig(width: 100, height: 60, color: NeoBrutalism.green),
    _FlexItemConfig(width: 60, height: 100, color: NeoBrutalism.blue),
    _FlexItemConfig(width: 90, height: 90, color: NeoBrutalism.orange),
    _FlexItemConfig(width: 70, height: 70, color: NeoBrutalism.purple),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    return Scaffold(
      backgroundColor: NeoBrutalism.grey,
      appBar: NeoAppBar(
        title: 'Playground',
        color: NeoBrutalism.red,
        actions: [
          NeoIconButton(icon: Icons.add, onPressed: _addItem, size: 40),
          const SizedBox(width: 4),
          NeoIconButton(icon: Icons.refresh, onPressed: _resetItems, size: 40),
          const SizedBox(width: 4),
          if (!isWideScreen)
            NeoIconButton(
              icon: Icons.tune_rounded,
              onPressed: _showSettingsSheet,
              size: 40,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWideScreen ? _buildWideLayout() : _buildFlexboxPreview(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: NeoBrutalism.white,
            border: Border(
              right: BorderSide(
                color: NeoBrutalism.black,
                width: NeoBrutalism.borderWidth,
              ),
            ),
          ),
          child: _buildSettingsPanel(),
        ),
        Expanded(child: _buildFlexboxPreview()),
      ],
    );
  }

  Widget _buildFlexboxPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.shapeDecoration(color: NeoBrutalism.white),
      child: Flexbox(
        flexDirection: _flexDirection,
        flexWrap: _flexWrap,
        justifyContent: _justifyContent,
        alignItems: _alignItems,
        alignContent: _alignContent,
        mainAxisSpacing: _mainAxisSpacing,
        crossAxisSpacing: _crossAxisSpacing,
        children: _items.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;
          return FlexItem(
            order: config.order,
            flexGrow: config.flexGrow,
            flexShrink: config.flexShrink,
            alignSelf: config.alignSelf,
            flexBasisPercent: config.flexBasisPercent,
            wrapBefore: config.wrapBefore,
            child: GestureDetector(
              onTap: () => _editItem(index),
              onLongPress: () => _removeItem(index),
              child: Container(
                width: config.flexBasisPercent > 0 ? null : config.width,
                height: config.height,
                decoration: NeoBrutalism.shapeDecoration(
                  color: config.color,
                  radius: 8,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      if (config.flexBasisPercent > 0)
                        Text(
                          '${(config.flexBasisPercent * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          '${config.width.toInt()}×${config.height.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (config.order != 1)
                        Text(
                          'order: ${config.order}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: NeoBrutalism.shapeDecoration(
            color: NeoBrutalism.red,
            hasShadow: false,
          ),
          child: const Text(
            'FLEXBOX PROPERTIES',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: NeoBrutalism.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NeoDropdown<FlexDirection>(
          label: 'flex-direction',
          value: _flexDirection,
          items: FlexDirection.values,
          onChanged: (v) => setState(() => _flexDirection = v!),
        ),
        _NeoDropdown<FlexWrap>(
          label: 'flex-wrap',
          value: _flexWrap,
          items: FlexWrap.values,
          onChanged: (v) => setState(() => _flexWrap = v!),
        ),
        _NeoDropdown<JustifyContent>(
          label: 'justify-content',
          value: _justifyContent,
          items: JustifyContent.values,
          onChanged: (v) => setState(() => _justifyContent = v!),
        ),
        _NeoDropdown<AlignItems>(
          label: 'align-items',
          value: _alignItems,
          items: AlignItems.values,
          onChanged: (v) => setState(() => _alignItems = v!),
        ),
        _NeoDropdown<AlignContent>(
          label: 'align-content',
          value: _alignContent,
          items: AlignContent.values,
          onChanged: (v) => setState(() => _alignContent = v!),
        ),
        const SizedBox(height: 16),
        NeoSlider(
          label: 'main-axis-spacing',
          value: _mainAxisSpacing,
          min: 0,
          max: 32,
          valueLabel: '${_mainAxisSpacing.round()}',
          onChanged: (v) => setState(() => _mainAxisSpacing = v),
        ),
        const SizedBox(height: 8),
        NeoSlider(
          label: 'cross-axis-spacing',
          value: _crossAxisSpacing,
          min: 0,
          max: 32,
          valueLabel: '${_crossAxisSpacing.round()}',
          onChanged: (v) => setState(() => _crossAxisSpacing = v),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: NeoBrutalism.shapeDecoration(
            color: NeoBrutalism.purple,
            hasShadow: false,
          ),
          child: Row(
            children: [
              const Text(
                'ITEMS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: NeoBrutalism.white,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to edit',
                style: TextStyle(
                  fontSize: 10,
                  color: NeoBrutalism.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final config = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: NeoBrutalism.shapeDecoration(
              color: NeoBrutalism.white,
              hasShadow: false,
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Container(
                width: 28,
                height: 28,
                decoration: NeoBrutalism.shapeDecoration(
                  color: config.color,
                  radius: 6,
                  hasShadow: false,
                ),
              ),
              title: Text(
                'Item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'grow:${config.flexGrow.toInt()} shrink:${config.flexShrink.toInt()}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: NeoIconButton(
                icon: Icons.delete_outline,
                onPressed: () => _removeItem(index),
                size: 32,
              ),
              onTap: () => _editItem(index),
            ),
          );
        }),
      ],
    );
  }

  void _addItem() {
    setState(() {
      _items.add(
        _FlexItemConfig(
          width: 80,
          height: 80,
          color: _playgroundColors[_items.length % _playgroundColors.length],
        ),
      );
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) setState(() => _items.removeAt(index));
  }

  void _resetItems() {
    setState(() {
      _items = [
        _FlexItemConfig(width: 80, height: 80, color: NeoBrutalism.red),
        _FlexItemConfig(width: 100, height: 60, color: NeoBrutalism.green),
        _FlexItemConfig(width: 60, height: 100, color: NeoBrutalism.blue),
        _FlexItemConfig(width: 90, height: 90, color: NeoBrutalism.orange),
        _FlexItemConfig(width: 70, height: 70, color: NeoBrutalism.purple),
      ];
    });
  }

  void _editItem(int index) {
    final config = _items[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ItemEditSheet(
        config: config,
        onSave: (newConfig) => setState(() => _items[index] = newConfig),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: NeoBrutalism.shapeDecoration(color: NeoBrutalism.white),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: NeoBrutalism.red,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(NeoBrutalism.borderRadius - 2),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: NeoBrutalism.white,
                      ),
                    ),
                    const Spacer(),
                    NeoIconButton(
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                      size: 36,
                      color: NeoBrutalism.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [_buildSettingsContent()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: NeoBrutalism.shapeDecoration(
                color: NeoBrutalism.red,
                hasShadow: false,
              ),
              child: const Text(
                'FLEXBOX PROPERTIES',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: NeoBrutalism.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _NeoDropdown<FlexDirection>(
              label: 'flex-direction',
              value: _flexDirection,
              items: FlexDirection.values,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _flexDirection = v!);
              },
            ),
            _NeoDropdown<FlexWrap>(
              label: 'flex-wrap',
              value: _flexWrap,
              items: FlexWrap.values,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _flexWrap = v!);
              },
            ),
            _NeoDropdown<JustifyContent>(
              label: 'justify-content',
              value: _justifyContent,
              items: JustifyContent.values,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _justifyContent = v!);
              },
            ),
            _NeoDropdown<AlignItems>(
              label: 'align-items',
              value: _alignItems,
              items: AlignItems.values,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _alignItems = v!);
              },
            ),
            _NeoDropdown<AlignContent>(
              label: 'align-content',
              value: _alignContent,
              items: AlignContent.values,
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _alignContent = v!);
              },
            ),
            const SizedBox(height: 16),
            NeoSlider(
              label: 'main-axis-spacing',
              value: _mainAxisSpacing,
              min: 0,
              max: 32,
              valueLabel: '${_mainAxisSpacing.round()}',
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _mainAxisSpacing = v);
              },
            ),
            const SizedBox(height: 8),
            NeoSlider(
              label: 'cross-axis-spacing',
              value: _crossAxisSpacing,
              min: 0,
              max: 32,
              valueLabel: '${_crossAxisSpacing.round()}',
              onChanged: (v) {
                setSheetState(() {});
                setState(() => _crossAxisSpacing = v);
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _NeoDropdown<T extends Enum> extends StatelessWidget {
  const _NeoDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: NeoBrutalism.shapeDecoration(
                color: NeoBrutalism.white,
                radius: 6,
                hasShadow: false,
              ),
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                underline: const SizedBox(),
                items: items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.name,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlexItemConfig {
  _FlexItemConfig({
    required this.width,
    required this.height,
    required this.color,
    this.flexGrow = 0,
    this.flexShrink = 1,
    this.alignSelf = AlignSelf.auto,
    this.order = 1,
    this.flexBasisPercent = -1,
    this.wrapBefore = false,
  });

  final double width;
  final double height;
  final Color color;
  final double flexGrow;
  final double flexShrink;
  final AlignSelf alignSelf;
  final int order;
  final double flexBasisPercent;
  final bool wrapBefore;

  _FlexItemConfig copyWith({
    double? width,
    double? height,
    Color? color,
    double? flexGrow,
    double? flexShrink,
    AlignSelf? alignSelf,
    int? order,
    double? flexBasisPercent,
    bool? wrapBefore,
  }) {
    return _FlexItemConfig(
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      flexGrow: flexGrow ?? this.flexGrow,
      flexShrink: flexShrink ?? this.flexShrink,
      alignSelf: alignSelf ?? this.alignSelf,
      order: order ?? this.order,
      flexBasisPercent: flexBasisPercent ?? this.flexBasisPercent,
      wrapBefore: wrapBefore ?? this.wrapBefore,
    );
  }
}

class _ItemEditSheet extends StatefulWidget {
  const _ItemEditSheet({required this.config, required this.onSave});
  final _FlexItemConfig config;
  final ValueChanged<_FlexItemConfig> onSave;

  @override
  State<_ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<_ItemEditSheet> {
  late double _width;
  late double _height;
  late double _flexGrow;
  late double _flexShrink;
  late AlignSelf _alignSelf;
  late int _order;
  late double _flexBasisPercent;
  late bool _wrapBefore;

  @override
  void initState() {
    super.initState();
    _width = widget.config.width;
    _height = widget.config.height;
    _flexGrow = widget.config.flexGrow;
    _flexShrink = widget.config.flexShrink;
    _alignSelf = widget.config.alignSelf;
    _order = widget.config.order;
    _flexBasisPercent = widget.config.flexBasisPercent;
    _wrapBefore = widget.config.wrapBefore;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: NeoBrutalism.shapeDecoration(color: NeoBrutalism.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: NeoBrutalism.red,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(NeoBrutalism.borderRadius - 2),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Edit Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: NeoBrutalism.white,
                  ),
                ),
                const Spacer(),
                NeoIconButton(
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                  size: 36,
                  color: NeoBrutalism.white,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  NeoSlider(
                    label: 'Width',
                    value: _width,
                    min: 20,
                    max: 200,
                    valueLabel: '${_width.round()}',
                    onChanged: (v) => setState(() => _width = v),
                  ),
                  const SizedBox(height: 12),
                  NeoSlider(
                    label: 'Height',
                    value: _height,
                    min: 20,
                    max: 200,
                    valueLabel: '${_height.round()}',
                    onChanged: (v) => setState(() => _height = v),
                  ),
                  const SizedBox(height: 12),
                  NeoSlider(
                    label: 'order',
                    value: _order.toDouble(),
                    min: 0,
                    max: 10,
                    valueLabel: '$_order',
                    onChanged: (v) => setState(() => _order = v.toInt()),
                  ),
                  const SizedBox(height: 12),
                  NeoSlider(
                    label: 'flex-grow',
                    value: _flexGrow,
                    min: 0,
                    max: 5,
                    valueLabel: '${_flexGrow.toInt()}',
                    onChanged: (v) => setState(() => _flexGrow = v),
                  ),
                  const SizedBox(height: 12),
                  NeoSlider(
                    label: 'flex-shrink',
                    value: _flexShrink,
                    min: 0,
                    max: 5,
                    valueLabel: '${_flexShrink.toInt()}',
                    onChanged: (v) => setState(() => _flexShrink = v),
                  ),
                  const SizedBox(height: 12),
                  NeoSlider(
                    label: 'flex-basis %',
                    value: _flexBasisPercent < 0 ? 0 : _flexBasisPercent * 100,
                    min: 0,
                    max: 100,
                    valueLabel: _flexBasisPercent < 0
                        ? 'auto'
                        : '${(_flexBasisPercent * 100).toInt()}%',
                    onChanged: (v) => setState(
                      () => _flexBasisPercent = v == 0 ? -1 : v / 100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'align-self:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: NeoBrutalism.shapeDecoration(
                            color: NeoBrutalism.white,
                            radius: 8,
                            hasShadow: false,
                          ),
                          child: DropdownButton<AlignSelf>(
                            value: _alignSelf,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: AlignSelf.values
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _alignSelf = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'wrap-before:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: _wrapBefore,
                          onChanged: (v) =>
                              setState(() => _wrapBefore = v ?? false),
                          activeColor: NeoBrutalism.blue,
                          side: const BorderSide(
                            width: 2,
                            color: NeoBrutalism.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: NeoButton.text(
                    onPressed: () => Navigator.pop(context),
                    text: 'Cancel',
                    color: NeoBrutalism.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeoButton.text(
                    onPressed: () {
                      widget.onSave(
                        widget.config.copyWith(
                          width: _width,
                          height: _height,
                          order: _order,
                          flexGrow: _flexGrow,
                          flexShrink: _flexShrink,
                          alignSelf: _alignSelf,
                          flexBasisPercent: _flexBasisPercent,
                          wrapBefore: _wrapBefore,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    text: 'Save',
                    color: NeoBrutalism.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
