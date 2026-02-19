import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Represents the dimensions of a component.
///
/// This class is used to represent the width and height of any component
/// whose dimensions may change or need to be resolved asynchronously,
/// such as images, video thumbnails, or dynamically sized content.
@immutable
class ItemDimension {
  /// Creates an item dimension.
  const ItemDimension({required this.width, required this.height});

  /// Creates an item dimension with the given aspect ratio and a reference dimension.
  ///
  /// If [baseWidth] is provided, the height will be calculated based on the aspect ratio.
  /// If [baseHeight] is provided, the width will be calculated based on the aspect ratio.
  factory ItemDimension.fromAspectRatio(
    double aspectRatio, {
    double? baseWidth,
    double? baseHeight,
  }) {
    assert(
      baseWidth != null || baseHeight != null,
      'Either baseWidth or baseHeight must be provided',
    );
    assert(aspectRatio > 0, 'Aspect ratio must be positive');

    if (baseWidth != null) {
      return ItemDimension(width: baseWidth, height: baseWidth / aspectRatio);
    } else {
      return ItemDimension(
        width: baseHeight! * aspectRatio,
        height: baseHeight,
      );
    }
  }

  /// Creates a square dimension.
  const ItemDimension.square(double size)
      : width = size,
        height = size;

  /// The width of the item.
  final double width;

  /// The height of the item.
  final double height;

  /// The aspect ratio (width / height) of the item.
  double get aspectRatio => height == 0 ? 1.0 : width / height;

  /// Returns a new dimension with swapped width and height.
  ItemDimension get transposed => ItemDimension(width: height, height: width);

  /// Returns a new dimension scaled by the given factor.
  ItemDimension scale(double factor) =>
      ItemDimension(width: width * factor, height: height * factor);

  /// Returns a new dimension fitted within the given constraints while
  /// maintaining the aspect ratio.
  ItemDimension fittedTo({double? maxWidth, double? maxHeight}) {
    double scale = 1.0;

    if (maxWidth != null && width > maxWidth) {
      scale = maxWidth / width;
    }

    if (maxHeight != null && height * scale > maxHeight) {
      scale = maxHeight / height;
    }

    return this.scale(scale);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemDimension &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'ItemDimension($width × $height)';
}

/// Callback signature for dimension resolution.
typedef DimensionCallback = void Function(ItemDimension dimension);

/// Error callback signature for dimension resolution.
typedef DimensionErrorCallback = void Function(Object error);

/// A function that resolves the dimension of an item asynchronously.
///
/// This allows for custom dimension resolution strategies beyond just images.
typedef DimensionProvider = Future<ItemDimension> Function();

/// A utility class to resolve item dimensions asynchronously.
///
/// This class provides a generic way to resolve dimensions from various sources
/// including images, videos, or any content with dynamic dimensions.
///
/// Example usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> {
///   final Map<int, double> _aspectRatios = {};
///   late final DimensionResolver _resolver;
///
///   @override
///   void initState() {
///     super.initState();
///     _resolver = DimensionResolver(
///       onDimensionResolved: (index, dimension) {
///         setState(() {
///           _aspectRatios[index] = dimension.aspectRatio;
///         });
///       },
///     );
///
///     // Start resolving dimensions
///     for (int i = 0; i < items.length; i++) {
///       _resolver.resolveImage(NetworkImage(items[i].imageUrl), key: i);
///     }
///   }
///
///   @override
///   void dispose() {
///     _resolver.dispose();
///     super.dispose();
///   }
/// }
/// ```
class DimensionResolver {
  /// Creates a dimension resolver.
  ///
  /// The [onDimensionResolved] callback is called with the key and resolved
  /// dimension when an item's dimensions are successfully resolved.
  ///
  /// The optional [onError] callback is called when dimension resolution fails.
  DimensionResolver({
    required this.onDimensionResolved,
    this.onError,
    this.cacheResolvedDimensions = true,
  });

  /// Called when an item's dimensions are resolved.
  final void Function(Object key, ItemDimension dimension) onDimensionResolved;

  /// Called when dimension resolution fails.
  final void Function(Object key, Object error)? onError;

  /// Whether to cache resolved dimensions.
  final bool cacheResolvedDimensions;

  /// Cache of resolved dimensions.
  final Map<Object, ItemDimension> _cache = {};

  /// Active image stream listeners.
  final Map<Object, ImageStreamListener> _imageListeners = {};

  /// Active image streams.
  final Map<Object, ImageStream> _imageStreams = {};

  /// Active custom resolution futures.
  final Map<Object, bool> _pendingResolutions = {};

  /// Whether this resolver has been disposed.
  bool _disposed = false;

  /// Returns the cached dimension for the given key, if available.
  ItemDimension? getCached(Object key) => _cache[key];

  /// Returns true if the dimension for the given key is cached.
  bool isCached(Object key) => _cache.containsKey(key);

  /// Returns all cached dimensions.
  Map<Object, ItemDimension> get cachedDimensions =>
      UnmodifiableMapView(_cache);

  /// Resolves the dimensions of the given image provider.
  ///
  /// The [key] is used to identify this resolution and will be passed to
  /// the [onDimensionResolved] callback.
  ///
  /// If [cacheResolvedDimensions] is true and the dimension is already cached,
  /// the callback will be called immediately with the cached value.
  void resolveImage(
    ImageProvider provider, {
    required Object key,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) {
    if (_disposed) return;

    // Check cache first
    if (cacheResolvedDimensions && _cache.containsKey(key)) {
      onDimensionResolved(key, _cache[key]!);
      return;
    }

    // Cancel any existing resolution for this key
    cancel(key);

    // Create new listener
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (_disposed) return;

        final dimension = ItemDimension(
          width: info.image.width.toDouble(),
          height: info.image.height.toDouble(),
        );

        if (cacheResolvedDimensions) {
          _cache[key] = dimension;
        }

        _cleanupImage(key);
        onDimensionResolved(key, dimension);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (_disposed) return;
        _cleanupImage(key);
        onError?.call(key, error);
      },
    );

    // Start resolution
    final stream = provider.resolve(configuration);
    _imageStreams[key] = stream;
    _imageListeners[key] = listener;
    stream.addListener(listener);
  }

  /// Resolves dimensions using a custom provider function.
  ///
  /// This is useful for resolving dimensions from non-image sources
  /// like video metadata, API responses, or calculated dimensions.
  ///
  /// Example:
  /// ```dart
  /// resolver.resolveCustom(
  ///   key: 'video_1',
  ///   provider: () async {
  ///     final metadata = await videoService.getMetadata(videoId);
  ///     return ItemDimension(
  ///       width: metadata.width.toDouble(),
  ///       height: metadata.height.toDouble(),
  ///     );
  ///   },
  /// );
  /// ```
  void resolveCustom({
    required Object key,
    required DimensionProvider provider,
  }) {
    if (_disposed) return;

    // Check cache first
    if (cacheResolvedDimensions && _cache.containsKey(key)) {
      onDimensionResolved(key, _cache[key]!);
      return;
    }

    // Cancel any existing resolution for this key
    cancel(key);

    _pendingResolutions[key] = true;

    provider().then(
      (dimension) {
        if (_disposed || _pendingResolutions[key] != true) return;

        if (cacheResolvedDimensions) {
          _cache[key] = dimension;
        }

        _pendingResolutions.remove(key);
        onDimensionResolved(key, dimension);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed || _pendingResolutions[key] != true) return;

        _pendingResolutions.remove(key);
        onError?.call(key, error);
      },
    );
  }

  /// Sets a dimension directly without async resolution.
  ///
  /// This is useful when you already know the dimension
  /// (e.g., from cached data or server response).
  void setDimension(Object key, ItemDimension dimension) {
    if (_disposed) return;

    cancel(key);

    if (cacheResolvedDimensions) {
      _cache[key] = dimension;
    }

    onDimensionResolved(key, dimension);
  }

  /// Cancels the dimension resolution for the given key.
  void cancel(Object key) {
    _cleanupImage(key);
    _pendingResolutions.remove(key);
  }

  /// Cancels all pending dimension resolutions.
  void cancelAll() {
    final imageKeys = List.of(_imageStreams.keys);
    for (final key in imageKeys) {
      _cleanupImage(key);
    }
    _pendingResolutions.clear();
  }

  /// Clears the dimension cache.
  void clearCache() {
    _cache.clear();
  }

  /// Removes a specific key from the cache.
  void removeFromCache(Object key) {
    _cache.remove(key);
  }

  void _cleanupImage(Object key) {
    final stream = _imageStreams.remove(key);
    final listener = _imageListeners.remove(key);
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
  }

  /// Disposes this resolver, canceling all pending resolutions.
  void dispose() {
    _disposed = true;
    cancelAll();
    clearCache();
  }
}

/// A mixin that provides dimension resolution capabilities for any content.
///
/// Use this mixin in your State class to easily manage dimension
/// resolution for flexbox layouts.
///
/// Example:
/// ```dart
/// class _MyGalleryState extends State<MyGallery>
///     with DimensionResolverMixin {
///   final List<String> imageUrls = [...];
///
///   @override
///   void initState() {
///     super.initState();
///     // Resolve dimensions for all images
///     for (int i = 0; i < imageUrls.length; i++) {
///       resolveImageDimension(
///         NetworkImage(imageUrls[i]),
///         key: i,
///       );
///     }
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return SliverFlexbox(
///       delegate: SliverChildBuilderDelegate(
///         (context, index) => Image.network(imageUrls[index]),
///         childCount: imageUrls.length,
///       ),
///       flexboxDelegate: SliverFlexboxDelegateWithDynamicAspectRatios(
///         childCount: imageUrls.length,
///         aspectRatioProvider: getAspectRatio,
///         defaultAspectRatio: 1.0,
///       ),
///     );
///   }
/// }
/// ```
mixin DimensionResolverMixin<T extends StatefulWidget> on State<T> {
  DimensionResolver? _dimensionResolver;

  /// Map of resolved aspect ratios by key.
  final Map<Object, double> _aspectRatios = {};

  /// Map of resolved dimensions by key.
  final Map<Object, ItemDimension> _dimensions = {};

  /// Default aspect ratio to use when dimension is not yet resolved.
  double get defaultAspectRatio => 1.0;

  /// Returns the aspect ratio for the given key.
  ///
  /// Returns [defaultAspectRatio] if the dimension is not yet resolved.
  double getAspectRatio(Object key) {
    return _aspectRatios[key] ?? defaultAspectRatio;
  }

  /// Returns the dimension for the given key.
  ///
  /// Returns null if the dimension is not yet resolved.
  ItemDimension? getDimension(Object key) {
    return _dimensions[key];
  }

  /// Returns true if the aspect ratio for the given key is resolved.
  bool isAspectRatioResolved(Object key) {
    return _aspectRatios.containsKey(key);
  }

  /// Returns true if the dimension for the given key is resolved.
  bool isDimensionResolved(Object key) {
    return _dimensions.containsKey(key);
  }

  /// Resolves the dimension for the given image provider.
  void resolveImageDimension(
    ImageProvider provider, {
    required Object key,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) {
    _ensureResolver();
    _dimensionResolver!.resolveImage(
      provider,
      key: key,
      configuration: configuration,
    );
  }

  /// Resolves the dimension using a custom provider.
  void resolveCustomDimension({
    required Object key,
    required DimensionProvider provider,
  }) {
    _ensureResolver();
    _dimensionResolver!.resolveCustom(key: key, provider: provider);
  }

  /// Sets a dimension directly without async resolution.
  void setItemDimension(Object key, ItemDimension dimension) {
    _ensureResolver();
    _dimensionResolver!.setDimension(key, dimension);
  }

  void _ensureResolver() {
    _dimensionResolver ??= DimensionResolver(
      onDimensionResolved: _onDimensionResolved,
      onError: _onDimensionError,
    );
  }

  void _onDimensionResolved(Object key, ItemDimension dimension) {
    if (mounted) {
      setState(() {
        _aspectRatios[key] = dimension.aspectRatio;
        _dimensions[key] = dimension;
      });
    }
  }

  void _onDimensionError(Object key, Object error) {
    onDimensionError(key, error);
  }

  /// Called when dimension resolution fails.
  ///
  /// Override this method to customize error handling.
  @protected
  void onDimensionError(Object key, Object error) {
    debugPrint('Failed to resolve dimension for key $key: $error');
  }

  @override
  void dispose() {
    _dimensionResolver?.dispose();
    super.dispose();
  }
}

/// Extension methods for ImageProvider to resolve dimensions.
extension ImageProviderDimensionExtension on ImageProvider {
  /// Resolves the dimensions of this image provider.
  ///
  /// Returns a Future that completes with the image dimensions.
  Future<ItemDimension> resolveDimension({
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) {
    final completer = Completer<ItemDimension>();

    final stream = resolve(configuration);
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        stream.removeListener(listener);
        completer.complete(
          ItemDimension(
            width: info.image.width.toDouble(),
            height: info.image.height.toDouble(),
          ),
        );
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}

/// A utility class to batch resolve dimensions.
///
/// This is useful when you need to resolve dimensions for many items
/// and want to track progress.
class BatchDimensionResolver {
  /// Creates a batch resolver.
  BatchDimensionResolver({
    this.maxConcurrent = 5,
    this.onProgress,
    this.onComplete,
    this.onError,
  });

  /// Maximum number of concurrent dimension resolutions.
  final int maxConcurrent;

  /// Called when progress is made.
  final void Function(int resolved, int total)? onProgress;

  /// Called when all dimensions are resolved.
  final void Function(Map<Object, ItemDimension> results)? onComplete;

  /// Called when a resolution fails.
  final void Function(Object key, Object error)? onError;

  final Map<Object, ItemDimension> _results = {};
  final Queue<_BatchItem> _pending = Queue<_BatchItem>();
  int _active = 0;
  int _total = 0;
  bool _disposed = false;

  /// Adds an image to resolve.
  void addImage(
    ImageProvider provider, {
    required Object key,
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) {
    if (_disposed) return;

    _pending.add(
      _BatchItem.image(
        provider: provider,
        key: key,
        configuration: configuration,
      ),
    );
    _total++;
  }

  /// Adds a custom dimension provider to resolve.
  void addCustom({required Object key, required DimensionProvider provider}) {
    if (_disposed) return;

    _pending.add(_BatchItem.custom(key: key, provider: provider));
    _total++;
  }

  /// Starts resolving all added items.
  void start() {
    if (_disposed) return;
    _processNext();
  }

  void _processNext() {
    if (_disposed) return;

    while (_active < maxConcurrent && _pending.isNotEmpty) {
      final item = _pending.removeFirst();
      _active++;

      item.resolve().then(
        (dimension) {
          if (_disposed) return;

          _results[item.key] = dimension;
          _active--;
          _notifyProgress();
          _processNext();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_disposed) return;

          _active--;
          onError?.call(item.key, error);
          _notifyProgress();
          _processNext();
        },
      );
    }
  }

  void _notifyProgress() {
    final resolved = _results.length;
    onProgress?.call(resolved, _total);

    if (_active == 0 && _pending.isEmpty) {
      onComplete?.call(Map.unmodifiable(_results));
    }
  }

  /// Cancels all pending resolutions.
  void cancel() {
    _pending.clear();
  }

  /// Disposes this resolver.
  void dispose() {
    _disposed = true;
    cancel();
    _results.clear();
  }
}

class _BatchItem {
  _BatchItem({required this.key, required DimensionProvider resolver})
      : _resolver = resolver;

  factory _BatchItem.image({
    required ImageProvider provider,
    required Object key,
    required ImageConfiguration configuration,
  }) {
    return _BatchItem(
      key: key,
      resolver: () => provider.resolveDimension(configuration: configuration),
    );
  }

  factory _BatchItem.custom({
    required Object key,
    required DimensionProvider provider,
  }) {
    return _BatchItem(key: key, resolver: provider);
  }

  final Object key;
  final DimensionProvider _resolver;

  Future<ItemDimension> resolve() => _resolver();
}
