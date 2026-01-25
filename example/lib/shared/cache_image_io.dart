// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:f_limit/f_limit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

final _loadLimiter = FLimit(40, queueStrategy: QueueStrategy.alternating);

/// Tracks which cache keys are currently being written to prevent concurrent writes
final _pendingCacheWrites = <String>{};

@immutable
class CacheImage extends painting.ImageProvider<painting.NetworkImage>
    implements painting.NetworkImage {
  /// Creates an object that fetches the image at the given URL.
  ///
  /// The arguments [url] and [scale] must not be null.
  const CacheImage(this.url, {this.scale = 1.0, this.headers});

  @override
  final String url;

  @override
  final double scale;

  @override
  final Map<String, String>? headers;

  @override
  Future<CacheImage> obtainKey(painting.ImageConfiguration configuration) {
    return SynchronousFuture<CacheImage>(this);
  }

  ImageStreamCompleter load(
    painting.NetworkImage key,
    painting.DecoderBufferCallback decode,
  ) {
    return _createCompleter(key, decodeBufferDeprecated: decode);
  }

  @override
  ImageStreamCompleter loadBuffer(
    painting.NetworkImage key,
    painting.DecoderBufferCallback decode,
  ) {
    return _createCompleter(key, decodeBufferDeprecated: decode);
  }

  @override
  ImageStreamCompleter loadImage(
    painting.NetworkImage key,
    painting.ImageDecoderCallback decode,
  ) {
    return _createCompleter(key, decode: decode);
  }

  ImageStreamCompleter _createCompleter(
    painting.NetworkImage key, {
    painting.ImageDecoderCallback? decode,
    painting.DecoderBufferCallback? decodeBufferDeprecated,
  }) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
        StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(
        key as CacheImage,
        chunkEvents,
        decode: decode,
        decodeBufferDeprecated: decodeBufferDeprecated,
      ),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<painting.ImageProvider>('Image provider', this),
        DiagnosticsProperty<painting.NetworkImage>('Image key', key),
      ],
    );
  }

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  Future<ui.Codec> _loadAsync(
    CacheImage key,
    StreamController<ImageChunkEvent> chunkEvents, {
    painting.ImageDecoderCallback? decode,
    painting.DecoderBufferCallback? decodeBufferDeprecated,
    painting.DecoderBufferCallback? decodeDeprecated,
  }) {
    return _loadLimiter(() async {
      try {
        assert(key == this);
        final cacheKey = base64Url.encode(utf8.encode(key.url));
        final cacheFile = await _getCacheFile(cacheKey);

        // Try to load from cache
        if (cacheFile.existsSync()) {
          try {
            final bytes = await cacheFile.readAsBytes();
            // Validate that bytes are not empty
            if (bytes.isNotEmpty) {
              return _decode(
                bytes,
                decode,
                decodeBufferDeprecated,
                decodeDeprecated,
              );
            }
          } catch (_) {
            // Cache file is corrupted, delete it and continue with network request
          }
          // Delete corrupted or empty cache file
          try {
            await cacheFile.delete();
          } catch (_) {}
        }

        // Clean up any stale .tmp files for this cache key
        final tmpFile = await _getCacheFile('$cacheKey.tmp');
        if (tmpFile.existsSync()) {
          try {
            await tmpFile.delete();
          } catch (_) {}
        }

        final Uri resolved = Uri.base.resolve(key.url);
        final HttpClientRequest request = await _httpClient.getUrl(resolved);

        headers?.forEach((String name, String value) {
          request.headers.add(name, value);
        });
        final HttpClientResponse response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          // The network may be only temporarily unavailable, or the file will be
          // added on the server later. Avoid having future calls to resolve
          // fail to check the network again.
          await response.drain<List<int>>(<int>[]);
          throw painting.NetworkImageLoadException(
            statusCode: response.statusCode,
            uri: resolved,
          );
        }

        final Uint8List bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (int cumulative, int? total) {
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: cumulative,
                expectedTotalBytes: total,
              ),
            );
          },
        );
        if (bytes.lengthInBytes == 0) {
          throw Exception('NetworkImage is an empty file: $resolved');
        }

        // Decode first, then cache only if decoding succeeds
        final ui.Codec codec = await _decode(
          bytes,
          decode,
          decodeBufferDeprecated,
          decodeDeprecated,
        );

        // Cache the successfully decoded image data asynchronously
        // Use a separate isolate-safe approach for file operations
        unawaited(_writeCacheFile(cacheKey, cacheFile.path, bytes));

        return codec;
      } catch (e) {
        // Depending on where the exception was thrown, the image cache may not
        // have had a chance to track the key in the cache at all.
        // Schedule a microtask to give the cache a chance to add the key.
        scheduleMicrotask(() {
          PaintingBinding.instance.imageCache.evict(key);
        });
        rethrow;
      } finally {
        unawaited(chunkEvents.close());
      }
    });
  }

  /// Write cache file atomically using a temporary file.
  /// Uses a simple lock to prevent concurrent writes to the same file.
  static Future<void> _writeCacheFile(
    String cacheKey,
    String cacheFilePath,
    Uint8List bytes,
  ) async {
    // Skip if another write for this cache key is in progress
    if (_pendingCacheWrites.contains(cacheKey)) {
      return;
    }

    _pendingCacheWrites.add(cacheKey);
    try {
      final tmpPath = '$cacheFilePath.tmp';
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(bytes, flush: true);
      // Atomic rename
      await tmpFile.rename(cacheFilePath);
    } catch (_) {
      // Silently fail - caching is best-effort
      // The image is already decoded and displayed
    } finally {
      _pendingCacheWrites.remove(cacheKey);
    }
  }

  Future<ui.Codec> _decode(
    Uint8List bytes,
    ImageDecoderCallback? decode,
    DecoderBufferCallback? decodeBufferDeprecated,
    DecoderBufferCallback? decodeDeprecated,
  ) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    if (decode != null) {
      return decode(buffer);
    }
    if (decodeBufferDeprecated != null) {
      return decodeBufferDeprecated(buffer);
    }
    assert(decodeDeprecated != null);
    return decodeDeprecated!(buffer);
  }

  static String? _cachedCacheDir;

  Future<File> _getCacheFile(String fileName) async {
    _cachedCacheDir ??= await _computeCacheDir();
    final dir = Directory(_cachedCacheDir!);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return File(join(dir.path, fileName));
  }

  static Future<String> _computeCacheDir() async {
    if (Platform.isWindows) {
      return join(
        (await getTemporaryDirectory()).path,
        (await getApplicationSupportDirectory()).parent.path
            .split(Platform.pathSeparator)
            .last,
        'images',
      );
    } else {
      return join((await getTemporaryDirectory()).path, 'images');
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CacheImage && other.url == url && other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'NetworkImage')}("$url", scale: $scale)';

  @override
  WebHtmlElementStrategy get webHtmlElementStrategy =>
      WebHtmlElementStrategy.never;
}
