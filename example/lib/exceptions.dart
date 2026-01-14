class ImageSourceException implements Exception {
  final String message;
  ImageSourceException(this.message);

  @override
  String toString() => message;
}
