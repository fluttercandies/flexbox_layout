import 'dart:convert';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/neo_brutalism.dart';
import '../widgets/neo_easy_refresh.dart';
import '../widgets/neo_widgets.dart';

/// Dynamic flexbox gallery using [SliverDynamicFlexbox].
///
/// This page demonstrates true dynamic size measurement where:
/// - Child widgets do NOT pre-specify their aspect ratio
/// - The layout system measures children to determine their intrinsic sizes
/// - When images load and their real dimensions become known, layout updates
///
/// This is different from providing pre-calculated aspect ratios from API.
class DynamicFlexboxPage extends StatefulWidget {
  const DynamicFlexboxPage({super.key});

  @override
  State<DynamicFlexboxPage> createState() => _DynamicFlexboxPageState();
}

class _DynamicFlexboxPageState extends State<DynamicFlexboxPage> {
  final List<_PostItem> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  late final EasyRefreshController _refreshController;

  double _targetRowHeight = 200.0;
  double _mainAxisSpacing = 4.0;
  double _crossAxisSpacing = 4.0;
  final int _postsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _refreshController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    _loadPosts();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = isRefresh ? 1 : _currentPage;
      final url = Uri.parse(
        'https://yande.re/post.json?tags=rating:safe&limit=$_postsPerPage&page=$page',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          setState(() {
            _hasMore = false;
            _isLoading = false;
          });
          return;
        }

        final newPosts = data.map((json) => _PostItem.fromJson(json)).toList();

        setState(() {
          if (isRefresh) {
            _posts.clear();
            _currentPage = 1;
            _hasMore = true;
          }
          _posts.addAll(newPosts);
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadPosts(isRefresh: true);
    _refreshController.finishRefresh();
    _refreshController.resetFooter();
  }

  Future<void> _onLoad() async {
    await _loadPosts();
    _refreshController.finishLoad(
      _hasMore ? IndicatorResult.success : IndicatorResult.noMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NeoAppBar(
        title: 'Dynamic Flexbox',
        color: NeoBrutalism.purple,
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
            width: double.infinity,
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
                    color: NeoBrutalism.purple,
                    radius: 6,
                    hasShadow: false,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        size: 14,
                        color: NeoBrutalism.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'DYNAMIC',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: NeoBrutalism.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_posts.length} images',
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
          // Gallery
          Expanded(child: _buildGallery()),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: NeoBrutalism.circleDecoration(
                  color: NeoBrutalism.red,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: NeoBrutalism.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              NeoButton.text(
                onPressed: _onRefresh,
                text: 'Try Again',
                color: NeoBrutalism.yellow,
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty && _isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: NeoBrutalism.circleDecoration(
                color: NeoBrutalism.purple,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: NeoBrutalism.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    // Simply use SliverDynamicFlexbox with Image.network
    // The layout automatically measures intrinsic sizes!
    return EasyRefresh(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      header: const NeoBrutalismHeader(),
      footer: const NeoBrutalismFooter(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(4),
            sliver: SliverDynamicFlexbox(
              flexboxDelegate: SliverDynamicFlexboxDelegate(
                targetRowHeight: _targetRowHeight,
                mainAxisSpacing: _mainAxisSpacing,
                crossAxisSpacing: _crossAxisSpacing,
                // Debounce duration for batched updates when images load
                debounceDuration: const Duration(milliseconds: 300),
                aspectRatioChangeThreshold: 0.05,
                crossAxisExtentChangeThreshold: 4,
              ),
              childDelegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _posts.length) return null;
                final post = _posts[index];
                // Just use Image.network directly - no wrapper needed!
                return _ImageItem(key: ValueKey(post.id), post: post);
              }, childCount: _posts.length),
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
                    color: NeoBrutalism.purple,
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
                          color: NeoBrutalism.white,
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
                      const SizedBox(height: 16),
                      NeoSlider(
                        label: 'Main Axis Spacing',
                        value: _mainAxisSpacing,
                        min: 0,
                        max: 20,
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
                        max: 20,
                        valueLabel: '${_crossAxisSpacing.round()}px',
                        onChanged: (v) {
                          setSheetState(() {});
                          setState(() => _crossAxisSpacing = v);
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
}

class _PostItem {
  const _PostItem({
    required this.id,
    required this.previewUrl,
    required this.sampleUrl,
    required this.tags,
    required this.score,
  });

  factory _PostItem.fromJson(Map<String, dynamic> json) {
    return _PostItem(
      id: json['id'] as int,
      previewUrl: json['preview_url'] as String,
      sampleUrl: json['sample_url'] as String,
      tags: json['tags'] as String,
      score: json['score'] as int,
    );
  }

  final int id;
  final String previewUrl;
  final String sampleUrl;
  final String tags;
  final int score;
}

/// A simple image item - just uses Image.network directly.
/// The layout measures its intrinsic size automatically!
class _ImageItem extends StatelessWidget {
  const _ImageItem({super.key, required this.post});

  final _PostItem post;

  @override
  Widget build(BuildContext context) {
    // Use DynamicFlexItem to handle unbounded constraints during measurement
    return DynamicFlexItem(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: NeoBrutalism.white),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              post.previewUrl,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                final progress = loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null;
                return Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      value: progress,
                      color: NeoBrutalism.purple,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: NeoBrutalism.red,
                    size: 32,
                  ),
                );
              },
            ),
            // Score badge
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: NeoBrutalism.shapeDecoration(
                  color: NeoBrutalism.yellow,
                  radius: 6,
                  hasShadow: false,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${post.score}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
