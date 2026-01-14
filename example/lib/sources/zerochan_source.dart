import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:example/exceptions.dart';
import 'package:example/models/image_post.dart';
import 'package:example/sources/image_source.dart';

class ZerochanSource extends ImageSource {
  @override
  String get name => 'zerochan';

  @override
  String get baseUrl => 'https://www.zerochan.net';

  static const String _userAgent = 'Flexbox Example App - anonymous';
  static const String _corsProxy = 'https://proxy.corsfix.com/?';

  String _buildUrl(String path) {
    final fullUrl = '$baseUrl$path';
    if (kIsWeb) {
      return '$_corsProxy$fullUrl';
    }
    return fullUrl;
  }

  String _buildImageUrl(String imageUrl) {
    if (kIsWeb) {
      return '$_corsProxy$imageUrl';
    }
    return imageUrl;
  }

  @override
  Future<List<ImagePost>> fetchPosts({
    required int page,
    required int limit,
  }) async {
    final url = Uri.parse(_buildUrl('/?p=$page&l=$limit&s=fav&t=1&json'));
    final response = await http.get(url, headers: {'User-Agent': _userAgent});

    if (response.statusCode != 200) {
      throw ImageSourceException('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    final items = json['items'] as List;

    if (items.isEmpty) {
      return [];
    }

    return items
        .map(
          (item) => ImagePost(
            id: item['id'] as int,
            imageUrl: _buildImageUrl(item['thumbnail'] as String),
            width: item['width'] as int,
            height: item['height'] as int,
            source: SourceType.zerochan,
          ),
        )
        .toList();
  }
}
