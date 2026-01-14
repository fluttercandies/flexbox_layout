import 'package:easy_refresh/easy_refresh.dart';
import 'package:example/config/image_config.dart';
import 'package:example/models/image_post.dart';
import 'package:example/sources/image_source_factory.dart';
import 'package:flexbox_layout/flexbox_layout.dart';
import 'package:flutter/material.dart';

import '../shared/cache_image.dart';
import '../shared/safe_state_mixin.dart';
import '../theme/neo_brutalism.dart';
import '../widgets/neo_easy_refresh.dart';
import '../widgets/neo_widgets.dart';

/// Network image gallery with dynamic aspect ratio resolution using
/// [DimensionResolverMixin].
///
/// This page demonstrates how to use [SliverFlexbox] with runtime-resolved
/// aspect ratios. Unlike [DynamicFlexboxPage] where children report their
/// intrinsic sizes, this page uses [DimensionResolverMixin] to pre-resolve
/// image dimensions and provides them to [SliverFlexboxDelegateWithAspectRatios].
///
/// This approach is useful when:
/// - You want to pre-fetch image dimensions before they appear in viewport
/// - You need more control over how aspect ratios are resolved
/// - You want to show loading states per-image based on resolution status
class NetworkImageGalleryPage extends StatefulWidget {
  const NetworkImageGalleryPage({super.key});

  @override
  State<NetworkImageGalleryPage> createState() =>
      _NetworkImageGalleryPageState();
}

class _NetworkImageGalleryPageState extends State<NetworkImageGalleryPage>
    with DimensionResolverMixin, SafeStateMixin {
  final List<ImagePost> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  late final EasyRefreshController _refreshController;

  double _targetRowHeight = 200.0;
  final int _postsPerPage = 20;

  @override
  double get defaultAspectRatio => 1.0;

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

    setSafeState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = isRefresh ? 1 : _currentPage;
      final source = ImageSourceFactory.create(ImageConfig.currentSource);
      final newPosts = await source.fetchPosts(
        page: page,
        limit: _postsPerPage,
      );

      if (newPosts.isEmpty) {
        setSafeState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final startIndex = isRefresh ? 0 : _posts.length;

      setSafeState(() {
        if (isRefresh) {
          _posts.clear();
          _currentPage = 1;
          _hasMore = true;
        }
        _posts.addAll(newPosts);
        _currentPage++;
        _isLoading = false;
      });

      _resolveNewPostDimensions(startIndex, newPosts);
    } catch (e) {
      setSafeState(() {
        _error = 'Load error: $e';
        _isLoading = false;
      });
    }
  }

  void _resolveNewPostDimensions(int startIndex, List<ImagePost> posts) {
    for (int i = 0; i < posts.length; i++) {
      final post = posts[i];
      resolveImageDimension(CacheImage(post.imageUrl), key: startIndex + i);
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
  void onDimensionError(Object key, Object error) {
    debugPrint('Failed to resolve dimension for image $key: $error');
  }

  int get _resolvedCount {
    int count = 0;
    for (int i = 0; i < _posts.length; i++) {
      if (isAspectRatioResolved(i)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NeoAppBar(
        title: 'Network Gallery',
        color: NeoBrutalism.blue,
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
                    color: NeoBrutalism.blue,
                    radius: 6,
                    hasShadow: false,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.autorenew_rounded,
                        size: 14,
                        color: NeoBrutalism.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'RUNTIME',
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
                  '$_resolvedCount/${_posts.length} resolved',
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
                color: NeoBrutalism.blue,
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

    // Build aspect ratios list using runtime-resolved dimensions
    final aspectRatios = <double>[];
    for (int i = 0; i < _posts.length; i++) {
      aspectRatios.add(getAspectRatio(i));
    }

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
            sliver: SliverFlexbox(
              delegate: SliverChildBuilderDelegate((context, index) {
                final post = _posts[index];
                final isResolved = isAspectRatioResolved(index);
                return _NetworkImageItem(
                  post: post,
                  index: index,
                  isAspectRatioKnown: isResolved,
                );
              }, childCount: _posts.length),
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
                  decoration: const BoxDecoration(
                    color: NeoBrutalism.blue,
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: NeoBrutalism.shapeDecoration(
                          color: NeoBrutalism.grey,
                          radius: 8,
                          hasShadow: false,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: NeoBrutalism.black,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This page resolves image dimensions at runtime '
                                'using DimensionResolverMixin. Watch the layout '
                                'update as images load.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: NeoBrutalism.black.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeoSlider(
                        label: 'Row Height',
                        value: _targetRowHeight,
                        min: 100,
                        max: 400,
                        valueLabel: '${_targetRowHeight.round()}px',
                        onChanged: (v) {
                          setSheetState(() {});
                          setSafeState(() => _targetRowHeight = v);
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

class _NetworkImageItem extends StatelessWidget {
  const _NetworkImageItem({
    required this.post,
    required this.index,
    required this.isAspectRatioKnown,
  });

  final ImagePost post;
  final int index;
  final bool isAspectRatioKnown;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: NeoBrutalism.white),
      child: Image(
        image: CacheImage(post.imageUrl),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: NeoBrutalism.grey,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: NeoBrutalism.black,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: NeoBrutalism.grey,
            child: const Icon(Icons.broken_image_rounded, size: 32),
          );
        },
      ),
    );
  }
}
