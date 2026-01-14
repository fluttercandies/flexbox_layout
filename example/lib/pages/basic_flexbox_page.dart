import 'package:flexbox/flexbox.dart';
import 'package:flutter/material.dart';

import '../theme/neo_brutalism.dart';
import '../widgets/neo_widgets.dart';

class BasicFlexboxPage extends StatefulWidget {
  const BasicFlexboxPage({super.key});

  @override
  State<BasicFlexboxPage> createState() => _BasicFlexboxPageState();
}

class _BasicFlexboxPageState extends State<BasicFlexboxPage> {
  FlexDirection _flexDirection = FlexDirection.row;
  FlexWrap _flexWrap = FlexWrap.wrap;
  JustifyContent _justifyContent = JustifyContent.flexStart;
  AlignItems _alignItems = AlignItems.flexStart;
  AlignContent _alignContent = AlignContent.flexStart;
  double _mainAxisSpacing = 8;
  double _crossAxisSpacing = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NeoAppBar(
        title: 'Basic Flexbox',
        color: NeoBrutalism.yellow,
        actions: [
          NeoIconButton(
            icon: Icons.tune_rounded,
            onPressed: _showSettingsSheet,
            size: 40,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Quick controls
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _NeoChip(
                    label: _flexDirection.name,
                    icon: Icons.swap_horiz_rounded,
                    color: NeoBrutalism.pink,
                    onTap: () => _cycleEnum<FlexDirection>(
                      FlexDirection.values,
                      _flexDirection,
                      (v) => setState(() => _flexDirection = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NeoChip(
                    label: _flexWrap.name,
                    icon: Icons.wrap_text_rounded,
                    color: NeoBrutalism.blue,
                    onTap: () => _cycleEnum<FlexWrap>(
                      FlexWrap.values,
                      _flexWrap,
                      (v) => setState(() => _flexWrap = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NeoChip(
                    label: _justifyContent.name,
                    icon: Icons.format_align_center_rounded,
                    color: NeoBrutalism.purple,
                    onTap: () => _cycleEnum<JustifyContent>(
                      JustifyContent.values,
                      _justifyContent,
                      (v) => setState(() => _justifyContent = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NeoChip(
                    label: _alignItems.name,
                    icon: Icons.align_vertical_center_rounded,
                    color: NeoBrutalism.orange,
                    onTap: () => _cycleEnum<AlignItems>(
                      AlignItems.values,
                      _alignItems,
                      (v) => setState(() => _alignItems = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Flexbox container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: NeoBrutalism.shapeDecoration(
                  color: NeoBrutalism.cream,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    NeoBrutalism.borderRadius - 2,
                  ),
                  child: Flexbox(
                    flexDirection: _flexDirection,
                    flexWrap: _flexWrap,
                    justifyContent: _justifyContent,
                    alignItems: _alignItems,
                    alignContent: _alignContent,
                    mainAxisSpacing: _mainAxisSpacing,
                    crossAxisSpacing: _crossAxisSpacing,
                    children: List.generate(
                      8,
                      (index) => _FlexboxItem(
                        index: index,
                        color: NeoBrutalism.getAccentColor(index),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cycleEnum<T extends Enum>(
    List<T> values,
    T current,
    ValueChanged<T> onChanged,
  ) {
    final nextIndex = (values.indexOf(current) + 1) % values.length;
    onChanged(values[nextIndex]);
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            margin: const EdgeInsets.all(16),
            decoration: NeoBrutalism.shapeDecoration(color: NeoBrutalism.white),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.yellow,
                    borderRadius: const BorderRadius.vertical(
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
                        ),
                      ),
                      const Spacer(),
                      NeoIconButton(
                        icon: Icons.close_rounded,
                        onPressed: () => Navigator.pop(context),
                        size: 36,
                        color: NeoBrutalism.white,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      NeoSlider(
                        label: 'Main Axis Spacing',
                        value: _mainAxisSpacing,
                        min: 0,
                        max: 32,
                        valueLabel: '${_mainAxisSpacing.round()}px',
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => _mainAxisSpacing = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      NeoSlider(
                        label: 'Cross Axis Spacing',
                        value: _crossAxisSpacing,
                        min: 0,
                        max: 32,
                        valueLabel: '${_crossAxisSpacing.round()}px',
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => _crossAxisSpacing = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildEnumSelector<AlignContent>(
                        label: 'Align Content',
                        value: _alignContent,
                        values: AlignContent.values,
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => _alignContent = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnumSelector<T extends Enum>({
    required String label,
    required T value,
    required List<T> values,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final isSelected = v == value;
            return GestureDetector(
              onTap: () => onChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: NeoBrutalism.shapeDecoration(
                  color: isSelected ? NeoBrutalism.pink : NeoBrutalism.white,
                  radius: 8,
                  hasShadow: false,
                ),
                child: Text(
                  v.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NeoChip extends StatelessWidget {
  const _NeoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: NeoBrutalism.shapeDecoration(
          color: color,
          radius: 8,
          hasShadow: false,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlexboxItem extends StatelessWidget {
  const _FlexboxItem({required this.index, required this.color});

  final int index;
  final Color color;

  static const List<Size> _sizes = [
    Size(100, 60),
    Size(80, 80),
    Size(120, 50),
    Size(90, 70),
    Size(110, 45),
    Size(70, 90),
    Size(100, 100),
    Size(60, 65),
  ];

  @override
  Widget build(BuildContext context) {
    final size = _sizes[index % _sizes.length];
    return Container(
      width: size.width,
      height: size.height,
      decoration: NeoBrutalism.shapeDecoration(
        color: color,
        radius: 8,
        hasShadow: false,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: NeoBrutalism.black,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
