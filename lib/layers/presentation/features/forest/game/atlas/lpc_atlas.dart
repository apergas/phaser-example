import 'dart:convert';

import 'atlas_frame.dart';

abstract final class LpcAtlas {
  static const double _defaultPivot = 0.5;

  static Map<String, AtlasFrame> parse(String source) {
    final json = jsonDecode(source);
    if (json case {'frames': final Map<String, dynamic> frames}) {
      return frames.map((name, value) => MapEntry(name, _frame(name, value)));
    }
    throw const FormatException('Atlas json has no "frames" object');
  }

  static AtlasFrame _frame(String name, Object? value) {
    if (value case {'frame': {'x': final num x, 'y': final num y, 'w': final num w, 'h': final num h}}) {
      final pivot = (value as Map<String, dynamic>)['pivot'];
      final (pivotX, pivotY) = switch (pivot) {
        {'x': final num px, 'y': final num py} => (px.toDouble(), py.toDouble()),
        _ => (_defaultPivot, _defaultPivot),
      };
      return AtlasFrame(
        name: name,
        x: x.toInt(),
        y: y.toInt(),
        width: w.toInt(),
        height: h.toInt(),
        pivotX: pivotX,
        pivotY: pivotY,
      );
    }
    throw FormatException('Atlas frame "$name" is malformed');
  }
}
