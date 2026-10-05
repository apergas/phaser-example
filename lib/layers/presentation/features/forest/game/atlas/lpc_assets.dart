import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

import '../../../../../../core/config/constants/enum/forest/player_sheet.dart';
import '../../../../../../core/config/constants/render_constants.dart';
import 'alpha_mask.dart';
import 'atlas_frame.dart';

class LpcAssets {
  final Image forest;
  final Map<String, AtlasFrame> frames;
  final AlphaMask forestMask;
  final Image ground;
  final Image heroWalk;
  final Image heroIdle;
  final Image heroWalkAxe;
  final Image heroIdleAxe;
  final Image heroChop;
  final Image heroHammer;

  const LpcAssets({
    required this.forest,
    required this.frames,
    required this.forestMask,
    required this.ground,
    required this.heroWalk,
    required this.heroIdle,
    required this.heroWalkAxe,
    required this.heroIdleAxe,
    required this.heroChop,
    required this.heroHammer,
  });

  AtlasFrame frame(String name) {
    final atlasFrame = frames[name];
    if (atlasFrame == null) throw ArgumentError.value(name, 'name', 'Unknown atlas frame');
    return atlasFrame;
  }

  Sprite sprite(String name) {
    final atlasFrame = frame(name);
    return Sprite(
      forest,
      srcPosition: Vector2(atlasFrame.x.toDouble(), atlasFrame.y.toDouble()),
      srcSize: Vector2(atlasFrame.width.toDouble(), atlasFrame.height.toDouble()),
    );
  }

  bool isOpaque(AtlasFrame atlasFrame, int localX, int localY) {
    if (localX < 0 || localY < 0 || localX >= atlasFrame.width || localY >= atlasFrame.height) return false;
    return forestMask.alphaAt(atlasFrame.x + localX, atlasFrame.y + localY) >= RenderConstants.solidAlpha;
  }

  Image sheet(PlayerSheet sheet) {
    return switch (sheet) {
      PlayerSheet.walk => heroWalk,
      PlayerSheet.idle => heroIdle,
      PlayerSheet.walkAxe => heroWalkAxe,
      PlayerSheet.idleAxe => heroIdleAxe,
      PlayerSheet.chop => heroChop,
      PlayerSheet.hammer => heroHammer,
    };
  }
}
