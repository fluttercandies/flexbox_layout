import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:example/exceptions.dart';
import 'package:example/models/image_post.dart';
import 'package:example/sources/image_source.dart';

class NekosiaSource extends ImageSource {
  @override
  String get name => 'nekosia';

  @override
  String get baseUrl => 'https://api.nekosia.cat/api/v1';

  static String session = DateTime.now().microsecondsSinceEpoch.toRadixString(
    36,
  );

  // Available categories
  static const List<String> _categories = [
    'random',
    'catgirl',
    'foxgirl',
    'wolfgirl',
    'animal-ears',
    'tail',
    'tail-with-ribbon',
    'tail-from-under-skirt',
    'cute',
    'cuteness-is-justice',
    'blue-archive',
    'girl',
    'young-girl',
    'maid',
    'maid-uniform',
    'vtuber',
    'w-sitting',
    'lying-down',
    'hands-forming-a-heart',
    'wink',
    'valentine',
    'headphones',
    'thigh-high-socks',
    'knee-high-socks',
    'white-tights',
    'black-tights',
    'heterochromia',
    'uniform',
    'sailor-uniform',
    'hoodie',
    'ribbon',
    'white-hair',
    'blue-hair',
    'long-hair',
    'blonde',
    'blue-eyes',
    'purple-eyes',
  ];

  // Convert string ID to int using hash
  int _stringIdToInt(String id) {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = (hash << 5) - hash + id.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.abs();
  }

  String _buildUrl(String path) {
    final fullUrl = '$baseUrl$path';
    // if (kIsWeb) {
    //   return '$_corsProxy$fullUrl';
    // }
    return fullUrl;
  }

  String _buildImageUrl(String imageUrl) {
    // if (kIsWeb) {
    //   return '$_corsProxy$imageUrl';
    // }
    return imageUrl;
  }

  @override
  Future<List<ImagePost>> fetchPosts({
    required int page,
    required int limit,
  }) async {
    // Nekosia API returns random images, not paginated
    // We use session=ip to avoid duplicates on same device
    // Use count parameter to get multiple images at once
    final count = limit.clamp(1, 20);
    final category = _categories[Random().nextInt(_categories.length)];

    final url = Uri.parse(
      _buildUrl('/images/$category?count=$count&rating=safe&session=$session'),
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw ImageSourceException('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);

    // Nekosia returns {success, status, count, images: [...]}
    if (json is! Map<String, dynamic>) {
      throw ImageSourceException('Invalid response format');
    }

    final images = json['images'];
    if (images is! List || images.isEmpty) {
      return [];
    }

    return images.map((item) {
      // Use compressed image for better performance
      final imageData = item['image'];
      final compressed = imageData['compressed'];

      // Use compressed metadata if available, fallback to original
      final metadata = item['metadata'];
      final meta = metadata['compressed'] ?? metadata['original'];

      return ImagePost(
        id: _stringIdToInt(
          item['id'] as String? ??
              DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        ),
        imageUrl: _buildImageUrl(compressed['url'] as String),
        width: (meta['width'] as num).toInt(),
        height: (meta['height'] as num).toInt(),
        source: SourceType.nekosia,
      );
    }).toList();
  }
}
