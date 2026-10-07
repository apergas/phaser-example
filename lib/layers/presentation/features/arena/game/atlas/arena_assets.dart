import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../../../forest/game/atlas/atlas_frame.dart';

class ArenaAssets {
  final Image atlas;
  final Map<String, AtlasFrame> frames;

  const ArenaAssets({required this.atlas, required this.frames});

  AtlasFrame frame(String name) {
    final atlasFrame = frames[name];
    if (atlasFrame == null) throw ArgumentError.value(name, 'name', 'Unknown arena frame');
    return atlasFrame;
  }

  Sprite sprite(String name) {
    final atlasFrame = frame(name);
    return Sprite(
      atlas,
      srcPosition: Vector2(atlasFrame.x.toDouble(), atlasFrame.y.toDouble()),
      srcSize: Vector2(atlasFrame.width.toDouble(), atlasFrame.height.toDouble()),
    );
  }
}
