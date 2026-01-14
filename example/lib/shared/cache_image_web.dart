import 'package:flutter/material.dart';

/// On web platforms, CacheImage is simply an alias for NetworkImage.
/// No caching is needed on web.
typedef CacheImage = NetworkImage;
