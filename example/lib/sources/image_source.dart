import 'package:example/models/image_post.dart';

abstract class ImageSource {
  String get name;
  String get baseUrl;

  Future<List<ImagePost>> fetchPosts({required int page, required int limit});
}
