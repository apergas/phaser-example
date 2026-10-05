import 'dart:typed_data';
import 'dart:ui';

import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/alpha_mask.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/lpc_assets.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

abstract final class LpcAssetsMock {
  static const int frameSize = 8;

  static final List<String> frameNames = [
    SpriteNames.house,
    SpriteNames.stump,
    SpriteNames.axePickup,
    for (final kind in TreeKind.values) SpriteNames.tree(kind),
    for (final kind in DecorationKind.values) SpriteNames.decoration(kind),
  ];

  static LpcAssets create() {
    final image = _image(frameSize, frameSize);
    return LpcAssets(
      forest: image,
      frames: {
        for (final name in frameNames)
          name: AtlasFrame(
            name: name,
            x: 0,
            y: 0,
            width: frameSize,
            height: frameSize,
            pivotX: 0.5,
            pivotY: name == SpriteNames.axePickup ? 0.5 : 1,
          ),
      },
      forestMask: AlphaMask(width: frameSize, height: frameSize, rgba: _rightHalfOpaque()),
      ground: image,
      heroWalk: image,
      heroIdle: image,
      heroWalkAxe: image,
      heroIdleAxe: image,
      heroChop: image,
      heroHammer: image,
    );
  }

  static Uint8List _rightHalfOpaque() {
    final bytes = Uint8List(frameSize * frameSize * 4);
    for (var y = 0; y < frameSize; y++) {
      for (var x = frameSize ~/ 2; x < frameSize; x++) {
        bytes[(y * frameSize + x) * 4 + 3] = 255;
      }
    }
    return bytes;
  }

  static Image _image(int width, int height) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    return recorder.endRecording().toImageSync(width, height);
  }
}
