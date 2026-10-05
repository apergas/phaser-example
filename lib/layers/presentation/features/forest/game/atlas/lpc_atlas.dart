import 'dart:convert';

import 'atlas_frame.dart';

abstract final class LpcAtlas {
  static const double _defaultPivot = 0.5;

  static Map<String, AtlasFrame> parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final frames = json['frames'] as Map<String, dynamic>;
    return frames.map((name, value) {
      final entry = value as Map<String, dynamic>;
      final rect = entry['frame'] as Map<String, dynamic>;
      final pivot = entry['pivot'] as Map<String, dynamic>?;
      return MapEntry(
        name,
        AtlasFrame(
          name: name,
          x: (rect['x'] as num).toInt(),
          y: (rect['y'] as num).toInt(),
          width: (rect['w'] as num).toInt(),
          height: (rect['h'] as num).toInt(),
          pivotX: (pivot?['x'] as num?)?.toDouble() ?? _defaultPivot,
          pivotY: (pivot?['y'] as num?)?.toDouble() ?? _defaultPivot,
        ),
      );
    });
  }
}
