import 'package:easy_refresh/easy_refresh.dart';
import 'package:flexbox/flexbox.dart';
import 'package:flutter/material.dart';

import '../theme/neo_brutalism.dart';
import '../widgets/neo_easy_refresh.dart';
import '../widgets/neo_widgets.dart';

/// Cat image data with aspect ratio information.
class CatImageInfo {
  const CatImageInfo({required this.path, required this.aspectRatio});

  final String path;
  final double aspectRatio;
}

/// List of cat images with their aspect ratios.
const List<CatImageInfo> catImages = [
  CatImageInfo(path: 'assets/cats/cat_1.jpg', aspectRatio: 1.50336),
  CatImageInfo(path: 'assets/cats/cat_2.jpg', aspectRatio: 1.32673),
  CatImageInfo(path: 'assets/cats/cat_3.jpg', aspectRatio: 0.674107),
  CatImageInfo(path: 'assets/cats/cat_4.jpg', aspectRatio: 1.50336),
  CatImageInfo(path: 'assets/cats/cat_5.jpg', aspectRatio: 1.33333),
  CatImageInfo(path: 'assets/cats/cat_6.jpg', aspectRatio: 1.33333),
  CatImageInfo(path: 'assets/cats/cat_7.jpg', aspectRatio: 1.39844),
  CatImageInfo(path: 'assets/cats/cat_8.jpg', aspectRatio: 1.77778),
  CatImageInfo(path: 'assets/cats/cat_9.jpg', aspectRatio: 1.19149),
  CatImageInfo(path: 'assets/cats/cat_10.jpg', aspectRatio: 1.50336),
  CatImageInfo(path: 'assets/cats/cat_11.jpg', aspectRatio: 1.50336),
  CatImageInfo(path: 'assets/cats/cat_12.jpg', aspectRatio: 1.5042),
  CatImageInfo(path: 'assets/cats/cat_13.jpg', aspectRatio: 1.07831),
  CatImageInfo(path: 'assets/cats/cat_14.jpg', aspectRatio: 1.50562),
  CatImageInfo(path: 'assets/cats/cat_15.jpg', aspectRatio: 1.33333),
  CatImageInfo(path: 'assets/cats/cat_16.jpg', aspectRatio: 1.80645),
  CatImageInfo(path: 'assets/cats/cat_17.jpg', aspectRatio: 0.959821),
  CatImageInfo(path: 'assets/cats/cat_18.jpg', aspectRatio: 1.50235),
  CatImageInfo(path: 'assets/cats/cat_19.jpg', aspectRatio: 1.49533),
];

class CatGalleryPage extends StatefulWidget {
  const CatGalleryPage({super.key});

  @override
  State<CatGalleryPage> createState() => _CatGalleryPageState();
}

class _CatGalleryPageState extends State<CatGalleryPage> {
  /// Current total items (increases with load more)
  int _totalItems = catImages.length;

  /// Number of items to add per load
  static const int _itemsPerLoad = 20;

  double _targetRowHeight = 200.0;

  late final EasyRefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() {
      _totalItems = catImages.length;
    });
    _refreshController.finishRefresh();
    _refreshController.resetFooter();
  }

  Future<void> _onLoad() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    setState(() {
      _totalItems += _itemsPerLoad;
    });
    // Infinite loading - never ends
    _refreshController.finishLoad(IndicatorResult.success);
  }

  @override
  Widget build(BuildContext context) {
    // Generate aspect ratios using modulo to cycle through catImages
    final aspectRatios = List.generate(
      _totalItems,
      (index) => catImages[index % catImages.length].aspectRatio,
    );

    return Scaffold(
      appBar: NeoAppBar(
        title: 'Cat Gallery',
        color: NeoBrutalism.pink,
        actions: [
          NeoIconButton(
            icon: Icons.refresh_rounded,
            onPressed: _onRefresh,
            size: 40,
          ),
          const SizedBox(width: 4),
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
          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: NeoBrutalism.white,
              border: Border(
                bottom: BorderSide(
                  color: NeoBrutalism.black,
                  width: NeoBrutalism.borderWidth,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: NeoBrutalism.shapeDecoration(
                    color: NeoBrutalism.green,
                    radius: 6,
                    hasShadow: false,
                  ),
                  child: const Text(
                    'FLEXBOX',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.all_inclusive_rounded, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'INFINITE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_totalItems images',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: NeoBrutalism.black.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Text(
                  'Row: ${_targetRowHeight.round()}px',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: NeoBrutalism.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Gallery with infinite loading
          Expanded(
            child: EasyRefresh(
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoad: _onLoad,
              header: const NeoBrutalismHeader(),
              footer: const NeoBrutalismFooter(),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(4),
                    sliver: SliverFlexbox(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final imageIndex = index % catImages.length;
                        return _CatItem(
                          imageInfo: catImages[imageIndex],
                          index: index,
                        );
                      }, childCount: _totalItems),
                      flexboxDelegate: SliverFlexboxDelegateWithAspectRatios(
                        aspectRatios: aspectRatios,
                        targetRowHeight: _targetRowHeight,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NeoBrutalism.pink,
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
                  child: NeoSlider(
                    label: 'Row Height',
                    value: _targetRowHeight,
                    min: 100,
                    max: 400,
                    valueLabel: '${_targetRowHeight.round()}px',
                    onChanged: (v) {
                      setSheetState(() {});
                      setState(() => _targetRowHeight = v);
                    },
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
}

class _CatItem extends StatelessWidget {
  const _CatItem({required this.imageInfo, required this.index});

  final CatImageInfo imageInfo;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: NeoBrutalism.shapeDecoration(
        color: NeoBrutalism.white,
        radius: 8,
        hasShadow: false,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              imageInfo.path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: NeoBrutalism.grey,
                  child: const Icon(Icons.pets_rounded, size: 40),
                );
              },
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: NeoBrutalism.shapeDecoration(
                color: NeoBrutalism.yellow,
                radius: 6,
                hasShadow: false,
              ),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
