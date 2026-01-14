/// Conditional export for CacheImage
///
/// Exports different implementations based on platform:
/// - IO platforms: cache_image_io.dart (with file caching)
/// - Web platforms: cache_image_web.dart (alias to NetworkImage)
library;

export 'cache_image_io.dart' if (dart.library.html) 'cache_image_web.dart';
